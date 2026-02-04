.PHONY: build install clean

BUILD_DIR = $(PWD)/build
APP_NAME = Playlister
SCHEME = Playlister
CONFIGURATION = Release

build:
	xcodebuild -scheme $(SCHEME) -configuration $(CONFIGURATION) build SYMROOT="$(BUILD_DIR)"

install: build
	rm -rf /Applications/$(APP_NAME).app
	cp -R $(BUILD_DIR)/$(CONFIGURATION)/$(APP_NAME).app /Applications/
	@echo "$(APP_NAME) installed to /Applications"

clean:
	rm -rf $(BUILD_DIR)
	xcodebuild clean -scheme $(SCHEME)
