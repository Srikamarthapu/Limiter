.PHONY: build test package install clean

build:
	swift build

test:
	swift test

package:
	./scripts/package-app.sh

install:
	./scripts/install-local.sh

clean:
	swift package clean
