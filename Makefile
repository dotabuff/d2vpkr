default: d2vpk update

d2vpk:
	go get github.com/Nightgunner5/vpk
	go build -o d2vpk d2vpk.go

update:
	ruby update.rb
