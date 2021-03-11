.PHONY: clean submodules release debug all

submodules:
	@if git submodule status | egrep -q '^[-]|^[+]' ; then \
  	echo "INFO: Need to reinitialize git submodules"; \
		git submodule update --init; \
	fi

origjsdeps := bitwarden-menubar/browser/package.json bitwarden-menubar/browser/package-lock.json
origjssources := $(filter-out $(origjsdeps),$(wildcard bitwarden-menubar/browser/**/*))
jssources := $(subst bitwarden-menubar/browser,bitwarden-menubar/browser-build,$(origjssources))
jsdeps := $(subst bitwarden-menubar/browser,bitwarden-menubar/browser-build,$(origjsdeps))
builtsources := $(wildcard bitwarden-menubar/browser-build/build/**/*)
appsources := $(wildcard bitwarden-menubar/app/*)

bitwarden-menubar/browser/package.json bitwarden-menubar/browser/package-lock.json: submodules

bitwarden-menubar/browser-build:
	mkdir -p bitwarden-menubar/browser-build

bitwarden-menubar/browser-build/package.json: bitwarden-menubar/browser/package.json | bitwarden-menubar/browser-build
	cp -f $? $@

bitwarden-menubar/browser-build/package-lock.json: bitwarden-menubar/browser/package-lock.json | bitwarden-menubar/browser-build
	cp -f $? $@

bitwarden-menubar/browser-build/node_modules: $(jsdeps)
	pushd bitwarden-menubar/browser-build && npm ci && popd

$(jssources): $(origjssources) | bitwarden-menubar/browser-build
	cp -Rf bitwarden-menubar/browser/* bitwarden-menubar/browser-build
	patch -d bitwarden-menubar/browser-build --forward --strip=1 < bitwarden-menubar/bitwarden-menubar.patch

bitwarden-menubar/browser-build/build: bitwarden-menubar/browser-build/node_modules $(jssources)
	pushd bitwarden-menubar/browser-build && npm run build && popd

bitwarden-menubar/app: bitwarden-menubar/browser-build/build
	mkdir -p bitwarden-menubar/app
	cp -R bitwarden-menubar/browser-build/build/* bitwarden-menubar/app
	cp bitwarden-menubar/browser-build/src/safari/safari/app/popup/index.html bitwarden-menubar/app/popup/index.html

debug: bitwarden-menubar/app
	xcodebuild -target bitwarden-menubar -configuration Debug

release: bitwarden-menubar/app
	xcodebuild -target bitwarden-menubar -configuration Release -arch x86_64

all: debug

clean:
	rm -rf build
	rm -rf bitwarden-menubar/browser-build
	rm -rf bitwarden-menubar/app
