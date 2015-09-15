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

	"github.com/Nightgunner5/vpk"
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
	ignoreExt := map[string]bool{}
	ignorePath := []string{}

	if len(os.Args) > 3 {
		for _, arg := range os.Args[3:] {
			if strings.HasPrefix(arg, ".") {
				ignoreExt[arg] = true
			} else {
				ignorePath = append(ignorePath, arg)
			}
		}
	}

	f, err := os.Open(MAIN_FILE)
	eh(err)
	defer f.Close()

	vpkFile, err := vpk.ReadVPKFile(f)
	eh(err)

	for _, filename := range vpkFile.ListFiles() {
		if ignoreExt[path.Ext(filename)] {
			continue
		}
		ignore := false
		for _, path := range ignorePath {
			if strings.HasPrefix(filename, path) {
				ignore = true
				break
			}
		}
		if ignore {
			continue
		}
		dir := path.Dir(TARGET + "/" + filename)
		eh(os.MkdirAll(dir, 0777))
		data, err := vpkFile.GetReader(vpkFile.GetFileInfo(filename), MAIN_FILE)
		fd, err := os.Create(path.Join(dir, path.Base(filename)))
		eh(err)
		io.Copy(fd, data)
		eh(fd.Close())
		eh(data.Close())
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
	inf, err := ioutil.ReadFile(home + "/Steam/steamapps/common/dota 2 beta/dota/steam.inf")
	if err != nil {
		panic(err)
	}

	steamInf := map[string]string{}
	for _, match := range infMatch.FindAllStringSubmatch(string(inf), -1) {
		steamInf[match[1]] = match[2]
	}

	fmt.Printf("Client %s Patch %s\n", steamInf["ClientVersion"], steamInf["PatchVersion"])
}
