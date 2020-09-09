.PHONY: all bootstrap lint build test coverage install vars debug clean clean-install clobber

.DEFAULT_GOAL := build

################################################################################
# Macros
################################################################################
VERBOSE := -v

# Bootstrap
CONFIG = .env
GIT_IGNORE = .gitignore
GOLINTER_YML = .golangci.yml

# Go Code
VENDOR = vendor
PACKAGES = $(shell find . -name main.go -not -path "./$(VENDOR)/*" -exec dirname {} \; | xargs realpath | xargs basename)
SRC_FILES = $(shell find . -name "*.go" -not -path "./$(VENDOR)/*" | grep -v _test.go)
TEST_FILES = $(shell find . -name "*_test.go" -not -path "./$(VENDOR)/*")

# Build Artifacts
BIN_DIR := bin
REPORT_DIR = report
BUILDS = $(addprefix $(BIN_DIR)/, $(PACKAGES))
LINT_OUT = $(REPORT_DIR)/lint.out
TEST_OUT = $(REPORT_DIR)/test.out
JUNIT_XML = $(REPORT_DIR)/junit.xml
COVERAGE_JSON = $(REPORT_DIR)/coverage.json
COVERAGE_XML = $(REPORT_DIR)/coverage.xml
COVERAGE_HTML = $(REPORT_DIR)/coverage.html
ARTIFACTS = $(BUILDS) $(LINT_OUT) $(TEST_OUT) $(COVERAGE_JSON) $(JUNIT_XML) $(COVERAGE_XML) $(COVERAGE_HTML)

# Install Artifacts
GOBIN ?= $(shell go env GOPATH)/bin
INSTALLS = $(addprefix $(GOBIN)/, $(PACKAGES))

# Go Commands
GOTEST ?= gocov test
GOBUILD ?= go build
GOINSTALL ?= go install

# Go Tools
GOLINTER := $(GOBIN)/golangci-lint
GOCOV := $(GOBIN)/gocov
GOCOV_XML := $(GOBIN)/gocov-xml
GOCOV_HTML := $(GOBIN)/gocov-html
GOJUNIT_REPORT := $(GOBIN)/go-junit-report

# Go Tool Flags
#GOLINTER_FLAGS ?= $(VERBOSE)
GOJUNIT_REPORT_FLAGS ?= -set-exit-code
GOTEST_FLAGS ?= -tags=unit $(VERBOSE)
GOBUILD_FLAGS ?= -o $(BIN_DIR) $(VERBOSE)
GOINSTALL_FLAGS ?= -i

# Versions
GOLINTER_VER := v1.31.0

################################################################################
# Files
################################################################################
# .gitignore
IGNORES = $(BIN_DIR) $(REPORT_DIR) $(GO_MK) $(CONFIG) $(VENDOR)

# .golangci.yml
define GOLINTER_CONFIG
linters:
  disable-all: true
  enable:
    - deadcode
    - dupl
    - errcheck
    - goconst
    - gocyclo
    - gofmt
    - goimports
    - golint
    - govet
    - ineffassign
    - megacheck
    - scopelint
    - structcheck
    - stylecheck
    - unconvert
    - varcheck
endef
export GOLINTER_CONFIG

################################################################################
# Phony
################################################################################
all:: lint test coverage build

bootstrap:: $(GIT_IGNORE) $(GOLINTER_YML) $(CONFIG)

lint:: $(LINT_OUT)

test:: $(JUNIT_XML) $(COVERAGE_XML)

coverage:: $(COVERAGE_HTML)

build:: $(BUILDS)

install:: $(INSTALLS)

clean::
	rm -f $(ARTIFACTS)

clean-install::
	rm -f $(INSTALLS)

clobber:: clean
	rm $(GO_MK)
	rmdir $(REPORT_DIR) $(BIN_DIR)

################################################################################
# Binaries
################################################################################
$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(BUILDS) : $(BIN_DIR) $(SRC_FILES)
	$(GOBUILD) $(GOBUILD_FLAGS) ./...

$(INSTALLS) : $(SRC_FILES)
	$(GOINSTALL) $(GOINSTALL_FLAGS) ./...

################################################################################
# Reports
################################################################################
$(REPORT_DIR):
	mkdir -p $(REPORT_DIR)

$(LINT_OUT) : $(REPORT_DIR) $(GOLINTER) $(GOLINTER_YML) $(SRC_FILES) $(TEST_FILES)
	$(GOLINTER) run $(GOLINTER_FLAGS) 2>&1 | tee $(LINT_OUT)

$(TEST_OUT) $(COVERAGE_JSON) : $(REPORT_DIR) $(GOCOV)
	$(GOTEST) $(GOTEST_FLAGS) ./... 2>&1 >$(COVERAGE_JSON) | tee $(TEST_OUT)

$(JUNIT_XML) : $(REPORT_DIR) $(GOJUNIT_REPORT) $(TEST_OUT)
	cat $(TEST_OUT) | $(GOJUNIT_REPORT) $(GOJUNIT_REPORT_FLAGS) >$(JUNIT_XML)

$(COVERAGE_XML) : $(REPORT_DIR) $(COVERAGE_JSON) $(GOCOV_XML)
	cat $(COVERAGE_JSON) | $(GOCOV_XML) >$(COVERAGE_XML)

$(COVERAGE_HTML) : $(REPORT_DIR) $(COVERAGE_JSON) $(GOCOV_HTML)
	cat $(COVERAGE_JSON) | $(GOCOV_HTML) >$(COVERAGE_HTML)

################################################################################
# Bootstrap
################################################################################
$(CONFIG):
	touch $(CONFIG)

$(GIT_IGNORE)::
	echo $(IGNORES) | tr ' ', '\n' >$(GIT_IGNORE)

$(GOLINTER_YML):
	echo "$$GOLINTER_CONFIG" >$(GOLINTER_YML)

################################################################################
# Tools
################################################################################
$(GOLINTER):
	curl -sfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(GOBIN) $(GOLINTER_VER)

$(GOCOV):
	@go get -u github.com/axw/gocov/gocov

$(GOJUNIT_REPORT):
	@go get -u github.com/jstemmer/go-junit-report

$(GOCOV_XML):
	@go get -u github.com/AlekSi/gocov-xml

$(GOCOV_HTML):
	@go get -u github.com/matm/gocov-html

################################################################################
# Helpers
################################################################################
vars::
	@echo "################################################################################"
	@echo "## Golang Code ##"
	@echo "################################################################################"
	@echo "PACKAGES = "$(PACKAGES)
	@echo "SRC_FILES = "$(SRC_FILES)
	@echo "TEST_FILES = "$(TEST_FILES)
	@echo
	@echo "################################################################################"
	@echo "## Artifacts ##"
	@echo "################################################################################"
	@echo "LINT_OUT = "$(LINT_OUT)
	@echo "JUNIT_XML = "$(JUNIT_XML)
	@echo "COVERAGE_JSON = "$(COVERAGE_JSON)
	@echo "COVERAGE_XML = "$(COVERAGE_XML)
	@echo "COVERAGE_HTML = "$(COVERAGE_HTML)
	@echo "BUILDS = "$(BUILDS)
	@echo "INSTALLS = "$(INSTALLS)
	@echo

debug:: vars
	@echo "################################################################################"
	@echo "## Artifact Dirs ##"
	@echo "################################################################################"
	@echo "BIN_DIR = "$(BIN_DIR)
	@echo "REPORT_DIR = "$(REPORT_DIR)
	@echo "GOBIN = "$(GOBIN)
	@echo
	@echo "################################################################################"
	@echo "## Tools ##"
	@echo "################################################################################"
	@echo "GOBUILD = "$(GOBUILD)
	@echo "GOTEST = "$(GOTEST)
	@echo "GOINSTALL = "$(GOINSTALL)
	@echo "GOLINTER = "$(GOLINTER)
	@echo "GOCOV = "$(GOCOV)
	@echo "GOCOV_XML = "$(GOCOV_XML)
	@echo "GOCOV_HTML = "$(GOCOV_HTML)
	@echo "GOJUNIT_REPORT = "$(GOJUNIT_REPORT)
	@echo
	@echo "################################################################################"
	@echo "## Flags ##"
	@echo "################################################################################"
	@echo "GOLINTER_FLAGS = "$(GOLINTER_FLAGS)
	@echo "GOTEST_FLAGS = "$(GOTEST_FLAGS)
	@echo "GOBUILD_FLAGS = "$(GOBUILD_FLAGS)
	@echo "GOINSTALL_FLAGS = "$(GOINSTALL_FLAGS)
