default: d2vpk pull update commit push

d2vpk:
	go get github.com/watbe/vpk
	go build -o d2vpk d2vpk.go

pull:
	git pull

update:
	ruby update.rb

commit:
	git add -A dota
	git commit -m "`./d2vpk -v`"

push:
	git push

