package main

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io"
	"strings"
)

// problemWith says what is wrong with a downloaded day, or returns "" when it is the right kind of document for
// that day. It only reads as far as it needs to, and is forgiving about the entities and encodings real files have.
func problemWith(body []byte, date, source string) string {
	decoder := xml.NewDecoder(bytes.NewReader(body))
	decoder.Strict = false
	decoder.CharsetReader = func(_ string, input io.Reader) (io.Reader, error) { return input, nil }

	wantRoot, notRoot := "hansard", "it is not a hansard document"
	if source == "scrapedxml" {
		wantRoot, notRoot = "debates", "it is not parsed debates"
	}

	var names []string
	for {
		token, err := decoder.Token()
		if err != nil {
			if len(names) == 0 {
				return notRoot
			}
			return ""
		}

		switch element := token.(type) {
		case xml.StartElement:
			names = append(names, element.Name.Local)
			depth := len(names)
			if depth == 1 && element.Name.Local != wantRoot {
				return notRoot
			}
			if source == "scrapedxml" {
				if depth == 2 {
					if id := attribute(element, "id"); id != "" && !strings.Contains(id, date) {
						return "it is for another day than " + date
					} else if id != "" {
						return ""
					}
				}
				continue
			}
			if depth == 3 && names[1] == "session.header" && element.Name.Local == "date" {
				var found string
				if err := decoder.DecodeElement(&found, &element); err != nil {
					return ""
				}
				if found = strings.TrimSpace(found); found != "" && found != date {
					return fmt.Sprintf("it is for %s, not %s", found, date)
				}
				return ""
			}
		case xml.EndElement:
			names = names[:len(names)-1]
		}
	}
}

func attribute(element xml.StartElement, name string) string {
	for _, a := range element.Attr {
		if a.Name.Local == name {
			return a.Value
		}
	}
	return ""
}
