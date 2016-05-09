default: d2vpk pull update commit push

d2vpk:
	go get github.com/Nightgunner5/vpk
	go build -o d2vpk d2vpk.go

pull:
	git pull

update:
	ruby update.rb
	ruby league.rb

commit:
	git add -A dota
	git commit -m "`./d2vpk -v`"

push:
	git push

