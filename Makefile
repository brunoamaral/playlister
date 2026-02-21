.PHONY: build install clean run release version help

BUILD_DIR    = $(PWD)/build
APP_NAME     = Playlister
SCHEME       = Playlister
CONFIGURATION = Release
INSTALL_DIR  = /Applications
APP_BUNDLE   = $(BUILD_DIR)/$(CONFIGURATION)/$(APP_NAME).app

build:
	@echo "→ Building $(APP_NAME) ($(CONFIGURATION))…"
	xcodebuild \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-destination "platform=macOS,arch=arm64" \
		SYMROOT="$(BUILD_DIR)" \
		build
	@echo "✓ Build complete: $(APP_BUNDLE)"

install: build
	@echo "→ Installing $(APP_NAME) to $(INSTALL_DIR)…"
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	cp -R $(APP_BUNDLE) $(INSTALL_DIR)/
	@echo "✓ $(APP_NAME) installed to $(INSTALL_DIR)"

run: install
	@echo "→ Launching $(APP_NAME)…"
	open $(INSTALL_DIR)/$(APP_NAME).app

release: clean install
	@echo "✓ Release build installed."

version:
	@/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" \
		$(APP_BUNDLE)/Contents/Info.plist 2>/dev/null \
		|| echo "(app not built yet – run 'make build' first)"

clean:
	@echo "→ Cleaning build artefacts…"
	rm -rf $(BUILD_DIR)
	xcodebuild clean -scheme $(SCHEME) -configuration $(CONFIGURATION) 2>/dev/null || true
	@echo "✓ Clean complete"

help:
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "  build    – compile the app ($(CONFIGURATION))"
	@echo "  install  – build then copy to $(INSTALL_DIR)"
	@echo "  run      – install then launch the app"
	@echo "  release  – clean, build, and install"
	@echo "  version  – print the installed bundle version"
	@echo "  clean    – remove build artefacts"
	@echo ""
