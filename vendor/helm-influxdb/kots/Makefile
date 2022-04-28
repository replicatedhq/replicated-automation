SHELL := /bin/bash -o pipefail

# version based on branch/channel
version := $(channel)-$(shell git rev-parse HEAD | head -c7)$(shell git diff --no-ext-diff --quiet --exit-code || echo "-dirty")

.PHONY: deps-vendor-cli
deps-vendor-cli:
	@if [[ ! -x `which replicated` ]]; then echo "please install the replicated cli https://github.com/replicatedhq/replicated"; exit 1; fi

.PHONY: helm-package
helm-package: deps-vendor-cli
	helm dependencies update ../
	helm package ../. -d manifests/

.PHONY: release
release: deps-vendor-cli
	replicated release create --auto -y

.PHONY: release-kurl-installer
release-kurl-installer: deps-vendor-cli
	replicated installer create --auto -y

