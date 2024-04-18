DOTA ?= ~/Steam/steamapps/common/dota 2 beta/game
DECOMPILER ?= ./bin/decompiler-linux-amd64

default: d2vpk pull update commit push

d2vpk:
	go get github.com/watbe/vpk
	go build -o d2vpk d2vpk.go

pull:
	git pull

update:
	cp -a "$(DOTA)/dota/steam.inf" ./dota
	$(DECOMPILER) --vpk_decompile --vpk_extensions "txt" --vpk_filepath "resource" -i "$(DOTA)/dota/pak01_dir.vpk" -o ./dota
	$(DECOMPILER) --vpk_decompile --vpk_extensions "txt" --vpk_filepath "scripts" -i "$(DOTA)/dota/pak01_dir.vpk" -o ./dota

commit:
	git add -A dota
	git commit -m "`./d2vpk -v`"

push:
	git push

