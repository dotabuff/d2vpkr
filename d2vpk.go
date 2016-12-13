package main

import (
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path"
	"regexp"
	"strings"

	"github.com/watbe/vpk"
)

var versionFlag = flag.Bool("v", false, "get version from ~/Steam")

func main() {
	flag.Parse()
	if *versionFlag {
		getVersion()
		return
	}

	if len(os.Args) < 3 {
		fmt.Println("Usage:", os.Args[0], "filename.vpk", "target_directory")
		return
	}

	MAIN_FILE := os.Args[1]
	TARGET := os.Args[2]
	includeExt := map[string]bool{}
	excludeExt := map[string]bool{}
	includePath := []string{}
	excludePath := []string{}
	includeAny := false

	if len(os.Args) > 3 {
		for _, arg := range os.Args[3:] {
			switch {
			case strings.HasPrefix(arg, "+."):
				includeExt[arg[1:]] = true
				includeAny = true
			case strings.HasPrefix(arg, "-."):
				excludeExt[arg[1:]] = true
			case strings.HasPrefix(arg, "+"):
				includePath = append(includePath, arg)
				includeAny = true
			case strings.HasPrefix(arg, "-"):
				excludePath = append(excludePath, arg)
			default:
				fmt.Println("Warning: unknown switch '%s'", arg)
			}
		}
	}

	f, err := os.Open(MAIN_FILE)
	if err != nil {
		panic(err)
	}
	defer f.Close()

	vpkFile, err := vpk.ReadVPKFile(f)
	if err != nil {
		panic(err)
	}	

	for _, filename := range vpkFile.ListFiles() {
		ignore := includeAny
		ext := path.Ext(filename)		

		if excludeExt[ext] {
			ignore = true
		}
		if includeExt[ext] {
			ignore = false
		}

		for _, path := range excludePath {
			if strings.HasPrefix(filename, path) {
				ignore = true
				break
			}
		}

		for _, path := range includePath {
			if strings.HasPrefix(filename, path) {
				ignore = false
				break
			}
		}

		if ignore {
			continue
		}

		fmt.Println("extracting", filename)

		dir := path.Dir(TARGET + "/" + filename)
		if err := os.MkdirAll(dir, 0777); err != nil {
			panic(err)
		}

		data, err := vpkFile.GetReader(vpkFile.GetFileInfo(filename), MAIN_FILE)
		if err != nil {
			panic(err)
		}

		fd, err := os.Create(path.Join(dir, path.Base(filename)))
		if err != nil {
			panic(err)
		}		
		
		io.Copy(fd, data)
		fd.Close()
		data.Close()
	}
}

func eh(err error) {
	if err != nil {
		panic(err)
	}
}

var infMatch = regexp.MustCompile(`(?m)^([^=]+)=(\S+)\s*`)

func getVersion() {
	home := os.Getenv("HOME")
	inf, err := ioutil.ReadFile(home + "/Steam/steamapps/common/dota 2 beta/game/dota/steam.inf")
	if err != nil {
		panic(err)
	}

	steamInf := map[string]string{}
	for _, match := range infMatch.FindAllStringSubmatch(string(inf), -1) {
		steamInf[match[1]] = match[2]
	}

	fmt.Printf("Client %s\n", steamInf["ClientVersion"])
}
