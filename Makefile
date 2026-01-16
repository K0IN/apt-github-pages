BINARY=hello
VERSION?=0.1.0
PKGNAME=hello-k0in
ARCHITECTURES=amd64 arm64

.PHONY: all build package package-all clean

all: package-all

# Build for a single architecture: make build ARCH=amd64
build:
ifndef ARCH
	$(error ARCH is not set. Use: make build ARCH=amd64)
endif
	@mkdir -p dist
	GOOS=linux GOARCH=$(ARCH) go build -v -ldflags="-X 'main.Version=$(VERSION)' -X 'main.BuildTime=$(shell date)'" -o dist/$(BINARY)-$(ARCH) ./cmd/hello

# Package for a single architecture: make package ARCH=amd64
package:
ifndef ARCH
	$(error ARCH is not set. Use: make package ARCH=amd64)
endif
	@$(MAKE) build ARCH=$(ARCH)
	@rm -rf package-$(ARCH)
	@mkdir -p package-$(ARCH)/DEBIAN package-$(ARCH)/usr/bin
	@sed "s/{{VERSION}}/$(VERSION)/; s/{{ARCH}}/$(ARCH)/; s/{{PKGNAME}}/$(PKGNAME)/" packaging/control.template > package-$(ARCH)/DEBIAN/control
	@install -m 755 dist/$(BINARY)-$(ARCH) package-$(ARCH)/usr/bin/$(BINARY)
	@dpkg-deb --build package-$(ARCH) dist/$(PKGNAME)_$(VERSION)_$(ARCH).deb
	@rm -rf package-$(ARCH)

# Build and package for all architectures
package-all:
	@for arch in $(ARCHITECTURES); do \
		echo "Building for $$arch..."; \
		$(MAKE) package ARCH=$$arch VERSION=$(VERSION); \
	done

clean:
	@rm -rf dist package package-* *.deb
