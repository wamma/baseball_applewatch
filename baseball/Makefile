# Makefile

.PHONY: default

default: make

make:
	@echo "🧹 Cleaning Flutter project..."
	flutter clean

	@echo "📦 Fetching dependencies..."
	flutter pub get

	@echo "🧽 Cleaning CocoaPods..."
	cd ios && rm -rf Pods Podfile.lock

	@echo "📦 Installing CocoaPods..."
	cd ios && pod cache clean --all && pod install

	@echo "✅ Done!"

	@echo "open ios/Runner.xcworkspace"
	open ios/Runner.xcworkspace


fix-xcode:
	open ios/Runner.xcworkspace
	@echo "⚙️  Now manually add: \`$(PROJECT_DIR)/Flutter\` to Framework Search Paths in Xcode (Debug/Profile/Release)"
