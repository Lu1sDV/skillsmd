package main

import (
	"bytes"
	"fmt"
	"os"

	apidesign "example.com/go-api-design"
)

func run() error {
	var builder apidesign.DocumentBuilder
	document, err := builder.Title("Go API").Tag("contracts").Build()
	if err != nil {
		return err
	}
	cloned := document.Clone()
	cloned.Tags[0] = "independent"

	codec := apidesign.NewJSONFamily()
	encoded, err := codec.Encode(document)
	if err != nil {
		return err
	}
	var decoded apidesign.Document
	if err := codec.Decode(encoded, &decoded); err != nil {
		return err
	}
	var output bytes.Buffer
	exporter, err := apidesign.NewExporter(&output, apidesign.WithPrefix("title: "), apidesign.WithLimit(40))
	if err != nil {
		return err
	}
	if err := exporter.Write(decoded.Title); err != nil {
		return err
	}
	_, err = fmt.Printf("tags: %s / %s\n%s\nsum: %d\n",
		document.Tags[0], cloned.Tags[0], output.String(), apidesign.Sum([]int{1, 2, 3}))
	return err
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
