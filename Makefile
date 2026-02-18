# hyfervisor - macOS VM installer tool Makefile
# Builds the hyfervisor macOS virtual machine installer tool.

# Xcode project settings
PROJECT = hyfervisor.xcodeproj
SCHEME = hyfervisor-InstallationTool-Objective-C
CONFIGURATION = Release
DESTINATION = generic/platform=macOS
DERIVED_DATA_PATH = build
RESULT_BUNDLE_PATH = build/Result_$(shell date +%Y%m%d-%H%M%S).xcresult

# Installer target
INSTALLATION_TOOL_TARGET = hyfervisor-InstallationTool-Objective-C

# Sample app target
APP_TARGET = hyfervisor-Objective-C

# Default target
all: $(INSTALLATION_TOOL_TARGET) $(APP_TARGET)

# Build installer (uses xcodebuild)
$(INSTALLATION_TOOL_TARGET):
	@echo "Building hyfervisor installer..."
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		-resultBundlePath "$(RESULT_BUNDLE_PATH)" \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO
	@echo "Build complete: $(INSTALLATION_TOOL_TARGET)"
	@echo "Binary at: $(DERIVED_DATA_PATH)/Build/Products/$(CONFIGURATION)/$(INSTALLATION_TOOL_TARGET)"

# Build hyfervisor app (uses xcodebuild)
$(APP_TARGET):
	@echo "Building hyfervisor app..."
	xcodebuild \
		-project $(PROJECT) \
		-scheme $(APP_TARGET) \
		-configuration $(CONFIGURATION) \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		-resultBundlePath "$(RESULT_BUNDLE_PATH)" \
		CODE_SIGN_IDENTITY="-" \
		CODE_SIGNING_REQUIRED=NO
	@echo "Build complete: $(APP_TARGET)"
	@echo "App at: $(DERIVED_DATA_PATH)/Build/Products/$(CONFIGURATION)/$(APP_TARGET).app"

# Clean
clean:
	@echo "Cleaning hyfervisor build artifacts..."
	rm -rf $(DERIVED_DATA_PATH)
	rm -f $(INSTALLATION_TOOL_TARGET)
	rm -rf $(APP_TARGET).app
	@echo "Clean complete"

# Install (optional)
install: $(INSTALLATION_TOOL_TARGET)
	@echo "Installing hyfervisor installer to /usr/local/bin..."
	cp $(DERIVED_DATA_PATH)/Build/Products/$(CONFIGURATION)/$(INSTALLATION_TOOL_TARGET) /usr/local/bin/
	@echo "Install complete"

# Uninstall (optional)
uninstall:
	@echo "Removing hyfervisor installer..."
	rm -f /usr/local/bin/$(INSTALLATION_TOOL_TARGET)
	@echo "Removal complete"

# Help
help:
	@echo "hyfervisor - macOS virtual machine tool"
	@echo ""
	@echo "Available targets:"
	@echo "  all                               - Build every target (default)"
	@echo "  $(INSTALLATION_TOOL_TARGET)       - Build only the installer"
	@echo "  $(APP_TARGET)                     - Build only the hyfervisor app"
	@echo "  clean                             - Remove build artifacts"
	@echo "  install                           - Install the installer to /usr/local/bin"
	@echo "  uninstall                         - Remove the installer"
	@echo "  help                              - Show this help"
	@echo "  check-deps                        - Verify required dependencies"
	@echo "  info                              - Show project information"
	@echo "  test-build                        - Run a build test"

# Dependency check
check-deps:
	@echo "Checking dependencies required to build hyfervisor..."
	@which xcodebuild > /dev/null || (echo "xcodebuild is not installed. Please install Xcode." && exit 1)
	@echo "xcodebuild: OK"
	@if [ ! -d $(PROJECT) ]; then \
		echo "Project file not found: $(PROJECT)"; \
		exit 1; \
	fi
	@echo "Project file: OK"
	@echo "All dependencies satisfied."

# Project info
info:
	@echo "hyfervisor project info:"
	@echo "  Name: hyfervisor - macOS virtual machine tool"
	@echo "  Description: Tool for running macOS virtual machines on Apple Silicon Macs"
	@echo "  Language: Objective-C"
	@echo "  Platform: Apple Silicon Mac (ARM64)"
	@echo "  Frameworks: Foundation, Virtualization"
	@echo "  Project: $(PROJECT)"
	@echo "  Installer scheme: $(SCHEME)"
	@echo "  App scheme: $(APP_TARGET)"
	@echo "  Targets: $(INSTALLATION_TOOL_TARGET), $(APP_TARGET)"

# Build test
test-build: clean $(INSTALLATION_TOOL_TARGET) $(APP_TARGET)
	@echo "Running hyfervisor build test..."
	@if [ -f $(DERIVED_DATA_PATH)/Build/Products/$(CONFIGURATION)/$(INSTALLATION_TOOL_TARGET) ]; then \
		echo "Build succeeded: $(INSTALLATION_TOOL_TARGET)"; \
		ls -la $(DERIVED_DATA_PATH)/Build/Products/$(CONFIGURATION)/$(INSTALLATION_TOOL_TARGET); \
	else \
		echo "Build failed: $(INSTALLATION_TOOL_TARGET)"; \
		exit 1; \
	fi
	@if [ -d $(DERIVED_DATA_PATH)/Build/Products/$(CONFIGURATION)/$(APP_TARGET).app ]; then \
		echo "Build succeeded: $(APP_TARGET)"; \
		ls -la $(DERIVED_DATA_PATH)/Build/Products/$(CONFIGURATION)/$(APP_TARGET).app; \
	else \
		echo "Build failed: $(APP_TARGET)"; \
		exit 1; \
	fi

# Phony targets
.PHONY: all clean install uninstall help check-deps info test-build $(INSTALLATION_TOOL_TARGET) $(APP_TARGET)
