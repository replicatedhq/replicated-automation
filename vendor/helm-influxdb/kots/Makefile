SHELL := /bin/bash -o pipefail

# version based on branch/channel
version := $(channel)-$(shell git rev-parse HEAD | head -c7)$(shell git diff --no-ext-diff --quiet --exit-code || echo "-dirty")

.PHONY: deps-vendor-cli
deps-vendor-cli: upstream_version = $(shell  curl --silent --location --fail --output /dev/null --write-out %{url_effective} https://github.com/replicatedhq/replicated/releases/latest | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+$$')
deps-vendor-cli: dist = $(shell echo `uname` | tr '[:upper:]' '[:lower:]')
deps-vendor-cli: cli_version = ""
deps-vendor-cli: cli_version = $(shell [[ -x deps/replicated ]] && deps/replicated version | grep version | head -n1 | cut -d: -f2 | tr -d , | tr -d '"' | tr -d " " )

deps-vendor-cli:
	: CLI Local Version $(cli_version)
	: CLI Upstream Version $(upstream_version)
	@if [[ "$(cli_version)" == "$(upstream_version)" ]]; then \
	   echo "Latest CLI version $(upstream_version) already present"; \
	 else \
	   echo '-> Downloading Replicated CLI to ./deps '; \
	   mkdir -p deps/; \
	   curl -s https://api.github.com/repos/replicatedhq/replicated/releases/latest \
	   | grep "browser_download_url.*$(dist)_amd64.tar.gz" \
	   | cut -d : -f 2,3 \
	   | tr -d \" \
	   | wget -O- -qi - \
	   | tar xvz -C deps; \
	 fi

.PHONY: helm-package
helm-package: deps-vendor-cli
	helm dependencies update ../
	helm package ../. -d manifests/

.PHONY: release
release: deps-vendor-cli
	deps/replicated release create --auto -y

.PHONY: release-kurl-installer
release-kurl-installer: deps-vendor-cli
	deps/replicated installer create --auto -y

