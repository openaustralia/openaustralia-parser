// pull-xml copies days of Hansard from https://data.openaustralia.org.au into the local data folder, so a development
// checkout can work with real days without asking APH for them. --source=origxml (the default) copies the XML
// production cached from APH, which parse-speeches.rb then parses locally; --source=scrapedxml copies production's
// parsed output, which xml2db.pl loads into the database as it is.
//
// It only fetches a day that is missing locally or newer on the server, using If-Modified-Since with the local file's
// modification time, and gives each file the server's Last-Modified time. A file that is newer locally, for example
// one refreshed from APH, is left alone. Days are fetched by a pool of workers. A development tool: nothing runs it
// on a schedule.
package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/alitto/pond/v2"
	"github.com/schollz/progressbar/v3"
	"golang.org/x/term"
)

const (
	defaultBaseURL = "https://data.openaustralia.org.au"
	userAgent      = "openaustralia-parser pull-xml (copying public data for development)"
	defaultWorkers = 10
	dateLayout     = "2006-01-02"
)

var (
	sources = []string{"origxml", "scrapedxml"}
	// houses maps the name of a house to its folder on the server.
	houses     = map[string]string{"representatives": "representatives_debates", "senate": "senate_debates"}
	houseOrder = []string{"representatives", "senate"}
	dayLink    = regexp.MustCompile(`href="(\d{4}-\d{2}-\d{2})\.xml"`)
)

type options struct {
	from, to  time.Time
	source    string
	house     string
	outputDir string
	baseURL   string
	all       bool
	force     bool
	dryRun    bool
	delay     time.Duration
	workers   int
}

type puller struct {
	opts     options
	client   *http.Client
	out      io.Writer
	progress bool

	// bar is set only when writing to a terminal. Everything written to out then goes through logf, which clears and
	// redraws the bar around each line, and outMu serialises all of it.
	bar        *progressbar.ProgressBar
	outMu      sync.Mutex
	downloaded atomic.Int64
	upToDate   atomic.Int64
	failed     atomic.Int64
	stopped    atomic.Bool
}

func main() {
	os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
}

// run does the whole job and returns the exit status, so tests can call it.
func run(args []string, stdout, stderr io.Writer) int {
	opts, err := parseOptions(args, stderr)
	if errors.Is(err, flag.ErrHelp) {
		return 0
	}
	if err != nil {
		fmt.Fprintln(stderr, err)
		return 2
	}

	transport := http.DefaultTransport.(*http.Transport).Clone()
	transport.MaxIdleConnsPerHost = opts.workers
	p := &puller{opts: opts, client: &http.Client{Transport: transport, Timeout: 2 * time.Minute}, out: stdout, progress: isTerminal(stdout)}
	return p.run()
}

func parseOptions(args []string, stderr io.Writer) (options, error) {
	opts := options{}
	var from, to string
	var year int
	var delay float64

	fs := flag.NewFlagSet("pull-xml", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintln(stderr, "Usage: pull-xml --from=DATE | --year=YEAR | --all [options]")
		fs.PrintDefaults()
	}
	fs.StringVar(&from, "from", "", "First day to pull, as YYYY-MM-DD (--from, --year or --all is required, so a run never copies the whole archive by accident)")
	fs.IntVar(&year, "year", 0, "Pull the whole of this year, instead of --from and --to")
	fs.BoolVar(&opts.all, "all", false, "Pull every day the server has, instead of --from, --to or --year")
	fs.StringVar(&to, "to", "", "Last day to pull (default today)")
	fs.StringVar(&opts.source, "source", "origxml", "origxml (APH's XML) or scrapedxml (the parsed output)")
	fs.StringVar(&opts.house, "house", "", "representatives or senate (default both)")
	fs.BoolVar(&opts.force, "force", false, "Download even if the local file is as new or newer")
	fs.BoolVar(&opts.dryRun, "dry-run", false, "List the days the server has and whether each is present locally, without downloading")
	fs.Float64Var(&delay, "delay", 0, "Seconds each worker waits after a request")
	fs.IntVar(&opts.workers, "workers", defaultWorkers, "How many days to fetch at once")
	fs.StringVar(&opts.outputDir, "output-dir", "", "Use this folder instead of tmp/pwdata under the parser repository")
	fs.StringVar(&opts.baseURL, "base-url", defaultBaseURL, "Pull from this URL")
	if err := fs.Parse(args); err != nil {
		return opts, err
	}

	var err error
	switch {
	case opts.all:
		if from != "" || to != "" || year != 0 {
			return opts, errors.New("--all can't be used with --from, --to or --year")
		}
		opts.to = time.Now()
	case year != 0:
		if from != "" || to != "" {
			return opts, errors.New("--year can't be used with --from or --to")
		}
		if year < 1900 || year > 9999 {
			return opts, errors.New("--year is not a year like 2025")
		}
		opts.from = time.Date(year, time.January, 1, 0, 0, 0, 0, time.UTC)
		opts.to = time.Date(year, time.December, 31, 0, 0, 0, 0, time.UTC)
	case from == "":
		return opts, errors.New("--from=DATE, --year=YEAR or --all is required")
	default:
		if opts.from, err = time.Parse(dateLayout, from); err != nil {
			return opts, fmt.Errorf("--from is not a date like 2025-11-25: %w", err)
		}
		opts.to = time.Now()
		if to != "" {
			if opts.to, err = time.Parse(dateLayout, to); err != nil {
				return opts, fmt.Errorf("--to is not a date like 2025-11-25: %w", err)
			}
		}
	}
	opts.to = opts.to.Truncate(24 * time.Hour)
	if !contains(sources, opts.source) {
		return opts, fmt.Errorf("--source must be one of %s", strings.Join(sources, ", "))
	}
	if opts.house != "" && houses[opts.house] == "" {
		return opts, errors.New("--house must be representatives or senate")
	}
	if opts.workers < 1 {
		return opts, errors.New("--workers must be at least 1")
	}
	opts.delay = time.Duration(delay * float64(time.Second))
	if opts.outputDir == "" {
		opts.outputDir = defaultOutputDir()
	}
	opts.baseURL = strings.TrimRight(opts.baseURL, "/")
	return opts, nil
}

// defaultOutputDir is tmp/pwdata under the parser repository, found by looking up from the working folder for
// parse-speeches.rb, so the tool works from tools/pull-xml as well as from the repository root.
func defaultOutputDir() string {
	dir, err := os.Getwd()
	if err != nil {
		return filepath.Join("tmp", "pwdata")
	}
	for current := dir; ; current = filepath.Dir(current) {
		if _, err := os.Stat(filepath.Join(current, "parse-speeches.rb")); err == nil {
			return filepath.Join(current, "tmp", "pwdata")
		}
		if filepath.Dir(current) == current {
			return filepath.Join(dir, "tmp", "pwdata")
		}
	}
}

// job is one day of one house to fetch.
type job struct{ directory, date string }

func (p *puller) run() int {
	selected := houseOrder
	if p.opts.house != "" {
		selected = []string{p.opts.house}
	}

	var jobs []job
	for _, house := range selected {
		directory := houses[house]
		dates, err := p.daysOnServer(directory)
		if err != nil {
			p.logf("%v", err)
			return 1
		}
		p.logf("%s/%s: %d days on the server%s", p.opts.source, directory, len(dates), p.rangeText())
		for _, date := range dates {
			jobs = append(jobs, job{directory, date})
		}
	}

	if p.opts.dryRun {
		for _, j := range jobs {
			p.logf("%s %s", j.date, presence(p.localPath(j.directory, j.date)))
		}
		return 0
	}

	if p.progress && len(jobs) > 0 {
		p.bar = progressbar.NewOptions(len(jobs),
			progressbar.OptionSetWriter(p.out),
			progressbar.OptionSetDescription(p.opts.source),
			progressbar.OptionSetWidth(30),
			progressbar.OptionShowCount(),
			progressbar.OptionSetPredictTime(true),
			progressbar.OptionThrottle(100*time.Millisecond),
			progressbar.OptionSetItsString("days"),
			progressbar.OptionShowIts(),
		)
	}

	pool := pond.NewPool(p.opts.workers)
	for _, j := range jobs {
		pool.Submit(func() {
			p.pullDay(j.directory, j.date)
			p.advance()
			time.Sleep(p.opts.delay)
		})
	}
	pool.StopAndWait()

	p.outMu.Lock()
	if p.bar != nil {
		p.bar.Finish()
		fmt.Fprintln(p.out)
		p.bar = nil
	}
	p.outMu.Unlock()

	if p.stopped.Load() {
		p.logf("The server asked us to slow down, so stopping. Run again later to carry on.")
	}
	p.logf("Downloaded %d, up to date %d, failed %d", p.downloaded.Load(), p.upToDate.Load(), p.failed.Load())
	return boolToStatus(p.failed.Load() > 0 || p.stopped.Load())
}

// advance moves the bar on by one day and shows the counts so far.
func (p *puller) advance() {
	p.outMu.Lock()
	defer p.outMu.Unlock()
	if p.bar == nil {
		return
	}
	p.bar.Describe(fmt.Sprintf("%s: %d new, %d current, %d failed", p.opts.source, p.downloaded.Load(), p.upToDate.Load(), p.failed.Load()))
	p.bar.Add(1)
}

// rangeText says which days were asked for, or nothing when it was all of them.
func (p *puller) rangeText() string {
	if p.opts.all {
		return ""
	}
	return fmt.Sprintf(" from %s to %s", p.opts.from.Format(dateLayout), p.opts.to.Format(dateLayout))
}

func presence(path string) string {
	if _, err := os.Stat(path); err == nil {
		return "present locally"
	}
	return "not present locally"
}

func boolToStatus(failed bool) int {
	if failed {
		return 1
	}
	return 0
}

// daysOnServer lists the days the server holds for a folder, within the range asked for, oldest first.
func (p *puller) daysOnServer(directory string) ([]string, error) {
	status, _, body, err := p.get(fmt.Sprintf("/%s/%s/", p.opts.source, directory), nil)
	if err != nil {
		return nil, fmt.Errorf("could not list %s/%s on the server: %w", p.opts.source, directory, err)
	}
	if status != http.StatusOK {
		return nil, fmt.Errorf("could not list %s/%s on the server (%d)", p.opts.source, directory, status)
	}

	var dates []string
	for _, match := range dayLink.FindAllStringSubmatch(string(body), -1) {
		date, err := time.Parse(dateLayout, match[1])
		if err != nil || date.Before(p.opts.from) || date.After(p.opts.to) {
			continue
		}
		dates = append(dates, match[1])
	}
	sort.Strings(dates)
	return dates, nil
}

func (p *puller) pullDay(directory, date string) {
	if p.stopped.Load() {
		return
	}
	path := p.localPath(directory, date)
	headers := map[string]string{}
	if info, err := os.Stat(path); err == nil && !p.opts.force {
		headers["If-Modified-Since"] = info.ModTime().UTC().Format(http.TimeFormat)
	}

	status, lastModified, body, err := p.get(fmt.Sprintf("/%s/%s/%s.xml", p.opts.source, directory, date), headers)
	if err != nil {
		p.fail("%s %s: %v", date, directory, err)
		return
	}

	switch status {
	case http.StatusNotModified:
		p.upToDate.Add(1)
		p.info("%s %s: up to date", date, directory)
	case http.StatusOK:
		// The parser keeps an empty file for a day with no sitting, so it doesn't ask APH about it again.
		if len(body) == 0 {
			p.saveAndCount(path, body, lastModified, "%s %s: downloaded (no sitting)", date, directory)
			return
		}
		if problem := problemWith(body, date, p.opts.source); problem != "" {
			p.fail("%s %s: not saved, %s", date, directory, problem)
			return
		}
		p.saveAndCount(path, body, lastModified, "%s %s: downloaded", date, directory)
	case http.StatusTooManyRequests, http.StatusServiceUnavailable:
		p.stopped.Store(true)
	default:
		p.fail("%s %s: the server answered %d", date, directory, status)
	}
}

func (p *puller) saveAndCount(path string, body []byte, lastModified, format string, args ...any) {
	if err := save(path, body, lastModified); err != nil {
		p.fail("%v", err)
		return
	}
	p.downloaded.Add(1)
	p.info(format, args...)
}

func (p *puller) fail(format string, args ...any) {
	p.failed.Add(1)
	p.logf(format, args...)
}

// logf prints a line, above the bar when there is one.
func (p *puller) logf(format string, args ...any) {
	p.outMu.Lock()
	defer p.outMu.Unlock()
	if p.bar != nil {
		p.bar.Clear()
		defer p.bar.Add(0)
	}
	fmt.Fprintf(p.out, format+"\n", args...)
}

// info prints a line about a day that went as expected. The bar already shows those, so it prints nothing then.
func (p *puller) info(format string, args ...any) {
	p.outMu.Lock()
	hidden := p.bar != nil
	p.outMu.Unlock()
	if !hidden {
		p.logf(format, args...)
	}
}

func (p *puller) localPath(directory, date string) string {
	return filepath.Join(p.opts.outputDir, p.opts.source, directory, date+".xml")
}

// get returns the status, the Last-Modified header and the body.
func (p *puller) get(path string, headers map[string]string) (int, string, []byte, error) {
	req, err := http.NewRequest(http.MethodGet, p.opts.baseURL+path, nil)
	if err != nil {
		return 0, "", nil, err
	}
	req.Header.Set("User-Agent", userAgent)
	for name, value := range headers {
		req.Header.Set(name, value)
	}
	resp, err := p.client.Do(req)
	if err != nil {
		return 0, "", nil, err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return 0, "", nil, err
	}
	return resp.StatusCode, resp.Header.Get("Last-Modified"), body, nil
}

// save writes to a temporary file first, so an interrupted run never leaves half a day where the parser would read it.
func save(path string, body []byte, lastModified string) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	temporary := path + ".new"
	defer os.Remove(temporary)
	if err := os.WriteFile(temporary, body, 0o644); err != nil {
		return err
	}
	modified := time.Now()
	if parsed, err := http.ParseTime(lastModified); err == nil {
		modified = parsed
	}
	if err := os.Chtimes(temporary, modified, modified); err != nil {
		return err
	}
	return os.Rename(temporary, path)
}

func contains(list []string, item string) bool {
	for _, candidate := range list {
		if candidate == item {
			return true
		}
	}
	return false
}

// isTerminal is true when w is a terminal, where a progress bar can redraw itself. A pipe or a file gets plain lines.
func isTerminal(w io.Writer) bool {
	file, ok := w.(*os.File)
	if !ok {
		return false
	}
	return term.IsTerminal(int(file.Fd()))
}
