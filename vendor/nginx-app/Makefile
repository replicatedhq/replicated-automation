SHELL := /bin/bash -o pipefail

app_slug := "${REPLICATED_APP}"

# Generate channel and release notes. We need to do this differently for github actions vs. command line because of how git works differently in GH actions. 
ifeq ($(origin GITHUB_ACTIONS), undefined)
release_notes := "CLI release of $(shell git symbolic-ref HEAD) triggered by ${shell git config --global user.name}: $(shell basename $$(git remote get-url origin) .git) [SHA: $(shell git rev-parse HEAD)]"
channel := $(shell git rev-parse --abbrev-ref HEAD)
else
release_notes := "GitHub Action release of ${GITHUB_REF} triggered by ${GITHUB_ACTOR}: [$(shell echo $${GITHUB_SHA::7})](https://github.com/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA})"
channel := ${GITHUB_BRANCH_NAME}
endif

# If we're on the master channel, translate that to the "Unstable" channel
ifeq ($(channel), master)
channel := Unstable
endif

# version based on branch/channel
version := $(channel)-$(shell git rev-parse HEAD | head -c7)$(shell git diff --no-ext-diff --quiet --exit-code || echo "-dirty")

.PHONY: deps-vendor-cli

deps-vendor-cli:
	@if [[ ! -x `which replicated` ]]; then echo "please install the replicated cli https://github.com/replicatedhq/replicated"; exit 1; fi


.PHONY: lint
lint: check-api-token check-app deps-vendor-cli
	replicated release lint --app $(app_slug) --yaml-dir manifests

.PHONY: check-api-token
check-api-token:
	@if [ -z "${REPLICATED_API_TOKEN}" ]; then echo "Missing REPLICATED_API_TOKEN"; exit 1; fi

.PHONY: check-app
check-app:
	@if [ -z "$(app_slug)" ]; then echo "Missing REPLICATED_APP"; exit 1; fi

.PHONY: list-releases
list-releases: check-api-token check-app deps-vendor-cli
	replicated release ls --app $(app_slug)

.PHONY: release
release: check-api-token check-app deps-vendor-cli lint
	replicated release create --auto -y

.PHONY: release-kurl-installer
release-kurl-installer: check-api-token check-app deps-vendor-cli
	replicated installer create --auto -y
