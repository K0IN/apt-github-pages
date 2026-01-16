package main

import (
	"fmt"
)

// https://www.digitalocean.com/community/tutorials/using-ldflags-to-set-version-information-for-go-applications
// go build -v -ldflags="-X 'main.Version=v1.0.0' -X 'main.BuildTime=$(date)'"

var Version = "dev"
var BuildTime = "unknown"

func main() {
	fmt.Printf("Hello, world from apt-github-pages!\nI was built at %s with version %s\n", BuildTime, Version)
}
