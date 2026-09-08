PROJECT := KeyboardLock.xcodeproj
SCHEME := KeyboardLock
DERIVED_DATA ?= build
DESTINATION := platform=macOS
APP_PATH := $(DERIVED_DATA)/Build/Products/Release/KeyboardLock.app

.PHONY: generate build signed-build run signed-run test analyze check clean

generate:
	xcodegen generate

build: generate
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination 'generic/platform=macOS' \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGNING_ALLOWED=NO \
		build

signed-build: generate
	@test -n "$(DEVELOPMENT_TEAM)" || (echo "Set DEVELOPMENT_TEAM to your Apple team ID." && exit 1)
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination 'generic/platform=macOS' \
		-derivedDataPath $(DERIVED_DATA) \
		DEVELOPMENT_TEAM="$(DEVELOPMENT_TEAM)" \
		CODE_SIGN_STYLE=Automatic \
		build

run: build
	open -n $(APP_PATH)

signed-run: signed-build
	open -n $(APP_PATH)

test: generate
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGNING_ALLOWED=NO \
		test

analyze: generate
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGNING_ALLOWED=NO \
		analyze

check: test build analyze

clean:
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-derivedDataPath $(DERIVED_DATA) \
		clean
