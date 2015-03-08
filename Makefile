NAME=herokuish
HARDWARE=$(shell uname -m)
VERSION=0.3.0
CEDARISH=v3

build:
	echo "$(CEDARISH)" > include/cedarish.txt
	go-bindata include
	mkdir -p build/linux  && GOOS=linux  go build -ldflags "-X main.Version $(VERSION)" -o build/linux/$(NAME)
	mkdir -p build/darwin && GOOS=darwin go build -ldflags "-X main.Version $(VERSION)" -o build/darwin/$(NAME)
	cp Dockerfile.cedar14 Dockerfile # CircleCI doesn't support `docker build -f`
	docker build -t herokuish:cedar14 .
	rm Dockerfile

deps: .cache/cedarish_$(CEDARISH).tgz
	time cat .cache/cedarish_$(CEDARISH).tgz | docker import - progrium/cedarish:cedar14
	go get -u github.com/jteeuwen/go-bindata/...
	go get -u github.com/progrium/gh-release/...
	go get || true

.cache/cedarish_$(CEDARISH).tgz:
	mkdir -p .cache
	rm -rf .cache/cedarish_* # drop old versions from cache
	curl -L https://github.com/progrium/cedarish/releases/download/$(CEDARISH)/cedarish-cedar14_$(CEDARISH).tar.gz \
		> .cache/cedarish_$(CEDARISH).tgz

test: test-functional test-apps

test-functional: build
	tests/shunit2 tests/*/tests.sh

test-apps: build
	tests/shunit2 tests/apps/*/tests.sh

release:
	rm -rf release && mkdir release
	cp build/cedar14.tgz release/$(NAME)_$(VERSION)_cedar14.tgz
	tar -zcf release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz -C build/linux $(NAME)
	tar -zcf release/$(NAME)_$(VERSION)_darwin_$(HARDWARE).tgz -C build/darwin $(NAME)
	gh-release create gliderlabs/$(NAME) $(VERSION) $(shell git rev-parse --abbrev-ref HEAD)

.PHONY: build
