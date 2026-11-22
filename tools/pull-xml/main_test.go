package main

import (
	"bytes"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

var serverTime = time.Date(2025, 11, 26, 9, 0, 0, 0, time.UTC)

func hansard(date string) string {
	return fmt.Sprintf(`<?xml version="1.0"?><hansard><session.header><date>%s</date></session.header></hansard>`, date)
}

func scraped(date string) string {
	return fmt.Sprintf(`<debates proof="1"><major-heading id="uk.org.publicwhip/debate/%s.1.1">x</major-heading></debates>`, date)
}

// server serves a listing and a document for each path in files, honouring If-Modified-Since as the real one does.
func server(t *testing.T, files map[string]string, hook func(r *http.Request)) *httptest.Server {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if hook != nil {
			hook(r)
		}
		if strings.HasSuffix(r.URL.Path, "/") {
			var listing strings.Builder
			for path := range files {
				if dir := path[:strings.LastIndex(path, "/")+1]; dir == r.URL.Path {
					fmt.Fprintf(&listing, `<a href="%s">x</a>`, path[len(dir):])
				}
			}
			if listing.Len() == 0 {
				http.NotFound(w, r)
				return
			}
			fmt.Fprint(w, listing.String())
			return
		}
		body, ok := files[r.URL.Path]
		if !ok {
			http.NotFound(w, r)
			return
		}
		if since, err := http.ParseTime(r.Header.Get("If-Modified-Since")); err == nil && !serverTime.After(since) {
			w.WriteHeader(http.StatusNotModified)
			return
		}
		w.Header().Set("Last-Modified", serverTime.Format(http.TimeFormat))
		fmt.Fprint(w, body)
	}))
	t.Cleanup(srv.Close)
	return srv
}

func pull(t *testing.T, srv *httptest.Server, dir string, extra ...string) (string, int) {
	t.Helper()
	var out, errs bytes.Buffer
	args := append([]string{"--from=2025-11-24", "--to=2025-11-28", "--base-url=" + srv.URL, "--output-dir=" + dir}, extra...)
	status := run(args, &out, &errs)
	return out.String() + errs.String(), status
}

func day(dir, source, house, date string) string {
	return filepath.Join(dir, source, house+"_debates", date+".xml")
}

func TestDownloadsMissingDays(t *testing.T) {
	srv := server(t, map[string]string{"/origxml/representatives_debates/2025-11-25.xml": hansard("2025-11-25"), "/origxml/representatives_debates/2025-11-26.xml": hansard("2025-11-26")}, nil)
	dir := t.TempDir()

	output, status := pull(t, srv, dir, "--house=representatives")

	if status != 0 || !strings.Contains(output, "Downloaded 2, up to date 0, failed 0") {
		t.Fatalf("status %d, output:\n%s", status, output)
	}
	if _, err := os.Stat(day(dir, "origxml", "representatives", "2025-11-26")); err != nil {
		t.Fatal(err)
	}
}

func TestGivesFilesTheServersModifiedTime(t *testing.T) {
	srv := server(t, map[string]string{"/origxml/senate_debates/2025-11-25.xml": hansard("2025-11-25")}, nil)
	dir := t.TempDir()
	pull(t, srv, dir, "--house=senate")

	info, err := os.Stat(day(dir, "origxml", "senate", "2025-11-25"))
	if err != nil || !info.ModTime().Equal(serverTime) {
		t.Fatalf("mod time %v, error %v", info.ModTime(), err)
	}
}

func TestSecondRunIsUpToDate(t *testing.T) {
	srv := server(t, map[string]string{"/origxml/senate_debates/2025-11-25.xml": hansard("2025-11-25")}, nil)
	dir := t.TempDir()
	pull(t, srv, dir, "--house=senate")

	output, _ := pull(t, srv, dir, "--house=senate")

	if !strings.Contains(output, "Downloaded 0, up to date 1, failed 0") {
		t.Fatal(output)
	}
}

func TestLeavesANewerLocalFileAlone(t *testing.T) {
	srv := server(t, map[string]string{"/origxml/senate_debates/2025-11-25.xml": hansard("2025-11-25")}, nil)
	dir := t.TempDir()
	path := day(dir, "origxml", "senate", "2025-11-25")
	os.MkdirAll(filepath.Dir(path), 0o755)
	os.WriteFile(path, []byte("refreshed from APH"), 0o644)

	pull(t, srv, dir, "--house=senate")

	if body, _ := os.ReadFile(path); string(body) != "refreshed from APH" {
		t.Fatalf("overwrote the newer file with %q", body)
	}
}

func TestForceReplacesANewerLocalFile(t *testing.T) {
	srv := server(t, map[string]string{"/origxml/senate_debates/2025-11-25.xml": hansard("2025-11-25")}, nil)
	dir := t.TempDir()
	path := day(dir, "origxml", "senate", "2025-11-25")
	os.MkdirAll(filepath.Dir(path), 0o755)
	os.WriteFile(path, []byte("refreshed from APH"), 0o644)

	pull(t, srv, dir, "--house=senate", "--force")

	if body, _ := os.ReadFile(path); !strings.Contains(string(body), "<hansard>") {
		t.Fatalf("kept %q", body)
	}
}

func TestDryRunDownloadsNothing(t *testing.T) {
	srv := server(t, map[string]string{"/origxml/senate_debates/2025-11-25.xml": hansard("2025-11-25")}, nil)
	dir := t.TempDir()

	output, _ := pull(t, srv, dir, "--house=senate", "--dry-run")

	if !strings.Contains(output, "2025-11-25 not present locally") {
		t.Fatal(output)
	}
	if _, err := os.Stat(day(dir, "origxml", "senate", "2025-11-25")); err == nil {
		t.Fatal("downloaded a day on a dry run")
	}
}

func TestOnlyPullsDaysInRange(t *testing.T) {
	srv := server(t, map[string]string{"/origxml/senate_debates/2025-11-20.xml": hansard("2025-11-20"), "/origxml/senate_debates/2025-11-25.xml": hansard("2025-11-25")}, nil)

	output, _ := pull(t, srv, t.TempDir(), "--house=senate")

	if !strings.Contains(output, "1 days on the server") {
		t.Fatal(output)
	}
}

func TestRefusesADocumentForAnotherDay(t *testing.T) {
	srv := server(t, map[string]string{"/origxml/senate_debates/2025-11-25.xml": hansard("2025-11-24")}, nil)
	dir := t.TempDir()

	output, status := pull(t, srv, dir, "--house=senate")

	if status != 1 || !strings.Contains(output, "it is for 2025-11-24, not 2025-11-25") {
		t.Fatalf("status %d, output:\n%s", status, output)
	}
	if _, err := os.Stat(day(dir, "origxml", "senate", "2025-11-25")); err == nil {
		t.Fatal("saved a document for the wrong day")
	}
}

func TestRefusesAnErrorPageAsOrigxml(t *testing.T) {
	srv := server(t, map[string]string{"/origxml/senate_debates/2025-11-25.xml": "<html><body>Oops</body></html>"}, nil)

	output, _ := pull(t, srv, t.TempDir(), "--house=senate")

	if !strings.Contains(output, "it is not a hansard document") {
		t.Fatal(output)
	}
}

func TestScrapedxmlIsChecked(t *testing.T) {
	files := map[string]string{"/scrapedxml/senate_debates/2025-11-25.xml": scraped("2025-11-25"), "/scrapedxml/senate_debates/2025-11-26.xml": scraped("2025-11-25")}
	srv := server(t, files, nil)

	output, _ := pull(t, srv, t.TempDir(), "--house=senate", "--source=scrapedxml")

	if !strings.Contains(output, "2025-11-26 senate_debates: not saved, it is for another day than 2025-11-26") || !strings.Contains(output, "Downloaded 1,") {
		t.Fatal(output)
	}
}

func TestScrapedxmlThatIsNotDebates(t *testing.T) {
	srv := server(t, map[string]string{"/scrapedxml/senate_debates/2025-11-25.xml": hansard("2025-11-25")}, nil)

	output, _ := pull(t, srv, t.TempDir(), "--house=senate", "--source=scrapedxml")

	if !strings.Contains(output, "it is not parsed debates") {
		t.Fatal(output)
	}
}

func TestKeepsAnEmptyFileForADayWithNoSitting(t *testing.T) {
	srv := server(t, map[string]string{"/origxml/senate_debates/2025-11-25.xml": ""}, nil)
	dir := t.TempDir()

	output, _ := pull(t, srv, dir, "--house=senate")

	if !strings.Contains(output, "downloaded (no sitting)") {
		t.Fatal(output)
	}
}

func TestToleratesUndefinedEntitiesAndLatin1(t *testing.T) {
	body := `<?xml version="1.0" encoding="ISO-8859-1"?><hansard><session.header><date>2025-11-25</date></session.header><p>Fish &nbsp; chips</p></hansard>`
	srv := server(t, map[string]string{"/origxml/senate_debates/2025-11-25.xml": body}, nil)

	output, _ := pull(t, srv, t.TempDir(), "--house=senate")

	if !strings.Contains(output, "Downloaded 1, up to date 0, failed 0") {
		t.Fatal(output)
	}
}

func TestStopsWhenTheServerSaysSlowDown(t *testing.T) {
	files := map[string]string{}
	for d := 24; d <= 28; d++ {
		files[fmt.Sprintf("/origxml/senate_debates/2025-11-%d.xml", d)] = hansard(fmt.Sprintf("2025-11-%d", d))
	}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(r.URL.Path, "/") {
			for path := range files {
				fmt.Fprintf(w, `<a href="%s">x</a>`, path[strings.LastIndex(path, "/")+1:])
			}
			return
		}
		w.WriteHeader(http.StatusTooManyRequests)
	}))
	defer srv.Close()

	output, status := pull(t, srv, t.TempDir(), "--house=senate", "--workers=1")

	if !strings.Contains(output, "The server asked us to slow down, so stopping") || status == 0 {
		t.Fatalf("status %d, output:\n%s", status, output)
	}
}

func TestOtherStatusesAreFailures(t *testing.T) {
	dir := t.TempDir()
	broken := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasSuffix(r.URL.Path, "/") {
			fmt.Fprint(w, `<a href="2025-11-25.xml">x</a>`)
			return
		}
		w.WriteHeader(http.StatusInternalServerError)
	}))
	defer broken.Close()

	output, status := pull(t, broken, dir, "--house=senate")

	if status != 1 || !strings.Contains(output, "the server answered 500") {
		t.Fatalf("status %d, output:\n%s", status, output)
	}
}

func TestFailsWhenTheListingCannotBeRead(t *testing.T) {
	srv := server(t, map[string]string{}, nil)

	output, status := pull(t, srv, t.TempDir(), "--house=senate")

	if status != 1 || !strings.Contains(output, "could not list origxml/senate_debates on the server (404)") {
		t.Fatalf("status %d, output:\n%s", status, output)
	}
}

func TestFetchesWithAPoolOfWorkers(t *testing.T) {
	files := map[string]string{}
	for d := 1; d <= 28; d++ {
		files[fmt.Sprintf("/origxml/senate_debates/2025-11-%02d.xml", d)] = hansard(fmt.Sprintf("2025-11-%02d", d))
	}
	var inFlight, peak atomic.Int64
	var mu sync.Mutex
	srv := server(t, files, func(r *http.Request) {
		if strings.HasSuffix(r.URL.Path, "/") {
			return
		}
		now := inFlight.Add(1)
		mu.Lock()
		if now > peak.Load() {
			peak.Store(now)
		}
		mu.Unlock()
		time.Sleep(40 * time.Millisecond)
		inFlight.Add(-1)
	})

	var out, errs bytes.Buffer
	status := run([]string{"--from=2025-11-01", "--to=2025-11-30", "--base-url=" + srv.URL, "--output-dir=" + t.TempDir(), "--house=senate", "--workers=10"}, &out, &errs)

	if status != 0 || peak.Load() < 5 || peak.Load() > 10 {
		t.Fatalf("status %d, peak concurrency %d (want 5 to 10)\n%s", status, peak.Load(), out.String())
	}
}

func TestWorkersCapTheConcurrency(t *testing.T) {
	files := map[string]string{}
	for d := 1; d <= 10; d++ {
		files[fmt.Sprintf("/origxml/senate_debates/2025-11-%02d.xml", d)] = hansard(fmt.Sprintf("2025-11-%02d", d))
	}
	var inFlight, peak atomic.Int64
	srv := server(t, files, func(r *http.Request) {
		if strings.HasSuffix(r.URL.Path, "/") {
			return
		}
		now := inFlight.Add(1)
		for {
			seen := peak.Load()
			if now <= seen || peak.CompareAndSwap(seen, now) {
				break
			}
		}
		time.Sleep(20 * time.Millisecond)
		inFlight.Add(-1)
	})

	var out, errs bytes.Buffer
	run([]string{"--from=2025-11-01", "--to=2025-11-30", "--base-url=" + srv.URL, "--output-dir=" + t.TempDir(), "--house=senate", "--workers=2"}, &out, &errs)

	if peak.Load() != 2 {
		t.Fatalf("peak concurrency %d, want 2", peak.Load())
	}
}

func TestPrintsNoBarWhenNotATerminal(t *testing.T) {
	srv := server(t, map[string]string{"/origxml/senate_debates/2025-11-25.xml": hansard("2025-11-25")}, nil)

	output, _ := pull(t, srv, t.TempDir(), "--house=senate")

	if !strings.Contains(output, "2025-11-25 senate_debates: downloaded") || strings.Contains(output, "\r") {
		t.Fatalf("expected plain lines, got %q", output)
	}
}

func TestOptionErrors(t *testing.T) {
	cases := map[string][]string{
		"--from=DATE, --year=YEAR or --all": {},
		"--all can't be used with":          {"--all", "--year=2025"},
		"--year can't be used with":         {"--year=2025", "--from=2025-01-01"},
		"--year is not a year":              {"--year=25"},
		"--from is not a date":              {"--from=yesterday"},
		"--source must be one of":           {"--from=2025-11-25", "--source=rewritexml"},
		"--house must be":                   {"--from=2025-11-25", "--house=lords"},
		"--workers must be at":              {"--from=2025-11-25", "--workers=0"},
		"--to is not a date like ":          {"--from=2025-11-25", "--to=soon"},
	}
	for want, args := range cases {
		var errs bytes.Buffer
		status := run(args, &bytes.Buffer{}, &errs)
		if status != 2 || !strings.Contains(errs.String(), want) {
			t.Errorf("%v: status %d, want %q in %q", args, status, want, errs.String())
		}
	}
}

func TestHelpExitsCleanly(t *testing.T) {
	if status := run([]string{"-h"}, &bytes.Buffer{}, &bytes.Buffer{}); status != 0 {
		t.Fatalf("status %d", status)
	}
}

func TestDefaultOutputDirFindsTheRepository(t *testing.T) {
	root := t.TempDir()
	os.WriteFile(filepath.Join(root, "parse-speeches.rb"), nil, 0o644)
	nested := filepath.Join(root, "tools", "pull-xml")
	os.MkdirAll(nested, 0o755)
	t.Chdir(nested)

	got, _ := filepath.EvalSymlinks(defaultOutputDir())
	want, _ := filepath.EvalSymlinks(filepath.Join(root, "tmp", "pwdata"))
	if got != want {
		t.Fatalf("got %s, want %s", got, want)
	}
}

func TestYearPullsTheWholeYear(t *testing.T) {
	srv := server(t, map[string]string{
		"/origxml/senate_debates/2024-12-31.xml": hansard("2024-12-31"),
		"/origxml/senate_debates/2025-01-01.xml": hansard("2025-01-01"),
		"/origxml/senate_debates/2025-12-31.xml": hansard("2025-12-31"),
		"/origxml/senate_debates/2026-01-01.xml": hansard("2026-01-01"),
	}, nil)
	var out, errs bytes.Buffer

	status := run([]string{"--year=2025", "--base-url=" + srv.URL, "--output-dir=" + t.TempDir(), "--house=senate", "--dry-run"}, &out, &errs)

	got := out.String()
	if status != 0 || !strings.Contains(got, "2 days on the server from 2025-01-01 to 2025-12-31") {
		t.Fatalf("status %d, output:\n%s", status, got)
	}
}

func TestAllPullsEveryDay(t *testing.T) {
	srv := server(t, map[string]string{
		"/origxml/senate_debates/2006-02-07.xml": hansard("2006-02-07"),
		"/origxml/senate_debates/2025-11-25.xml": hansard("2025-11-25"),
	}, nil)
	var out, errs bytes.Buffer

	status := run([]string{"--all", "--base-url=" + srv.URL, "--output-dir=" + t.TempDir(), "--house=senate"}, &out, &errs)

	if status != 0 || !strings.Contains(out.String(), "origxml/senate_debates: 2 days on the server\n") || !strings.Contains(out.String(), "Downloaded 2,") {
		t.Fatalf("status %d, output:\n%s", status, out.String())
	}
}
