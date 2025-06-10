# Makefile

.PHONY: default make update-url init-podfile fix-xcode

default: make

make:
	@echo "🐳 Starting Docker containers (background)..."
	docker-compose up -d

	@echo "🌐 Starting cloudflared tunnel and updating main.dart URL..."
	$(MAKE) update-url

	@echo "🧹 Cleaning Flutter project..."
	flutter clean

	@echo "📦 Fetching dependencies..."
	flutter pub get

	@echo "📄 Checking Podfile..."
	@if [ ! -f ios/Podfile ]; then \
		echo "📄 Podfile not found. Initializing..."; \
		$(MAKE) init-podfile; \
	fi

	@echo "🧽 Cleaning CocoaPods..."
	cd ios && rm -rf Pods Podfile.lock && \
	pod cache clean --all && pod install

	@echo "✅ Done!"
	@echo "📂 open ios/Runner.xcworkspace"
	open ios/Runner.xcworkspace

update-url:
	@echo "🌐 Launching cloudflared tunnel (background) and extracting public URL..."

	@mkdir -p tmp
	@rm -f tmp/cloudflared.log

	@nohup cloudflared tunnel --url http://localhost:8000 > tmp/cloudflared.log 2>&1 &

	@sleep 5

	@TUNNEL_URL=$$(grep -o 'https://[a-zA-Z0-9.-]*\.trycloudflare\.com' tmp/cloudflared.log | head -n 1); \
	echo "📌 New tunnel URL: $$TUNNEL_URL"; \
	if [ -n "$$TUNNEL_URL" ]; then \
		sed -i '' "s|final url = 'https://.*';|final url = '$${TUNNEL_URL}/score?team=\$$$encoded';|" lib/main.dart; \
	else \
		echo "❌ Failed to extract tunnel URL"; \
	fi

	@echo "🧹 Cleaning up..."
	@rm -rf tmp


fix-xcode:
	open ios/Runner.xcworkspace
	@echo "⚙️  Now manually add: \`$(PROJECT_DIR)/Flutter\` to Framework Search Paths in Xcode (Debug/Profile/Release)"

init-podfile:
	@test -f ios/Podfile || ( \
	echo "📄 Creating Podfile..." && \
	echo "# Uncomment this line to define a global platform for your project" > ios/Podfile && \
	echo "platform :ios, '16.0'" >> ios/Podfile && \
	echo "" >> ios/Podfile && \
	echo "ENV['COCOAPODS_DISABLE_STATS'] = 'true'" >> ios/Podfile && \
	echo "" >> ios/Podfile && \
	echo "project 'Runner', {" >> ios/Podfile && \
	echo "  'Debug' => :debug," >> ios/Podfile && \
	echo "  'Profile' => :release," >> ios/Podfile && \
	echo "  'Release' => :release," >> ios/Podfile && \
	echo "}" >> ios/Podfile && \
	echo "" >> ios/Podfile && \
	echo "def flutter_root" >> ios/Podfile && \
	echo "  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)" >> ios/Podfile && \
	echo "  unless File.exist?(generated_xcode_build_settings_path)" >> ios/Podfile && \
	echo "    raise \"\#\{generated_xcode_build_settings_path\} must exist. If you're running pod install manually, make sure flutter pub get is executed first\"" >> ios/Podfile && \
	echo "  end" >> ios/Podfile && \
	echo "  File.foreach(generated_xcode_build_settings_path) do |line|" >> ios/Podfile && \
	echo "    matches = line.match(/FLUTTER_ROOT\=(.*)/)" >> ios/Podfile && \
	echo "    return matches[1].strip if matches" >> ios/Podfile && \
	echo "  end" >> ios/Podfile && \
	echo "  raise \"FLUTTER_ROOT not found in \#\{generated_xcode_build_settings_path\}. Try deleting Generated.xcconfig, then run flutter pub get\"" >> ios/Podfile && \
	echo "end" >> ios/Podfile && \
	echo "" >> ios/Podfile && \
	echo "require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)" >> ios/Podfile && \
	echo "" >> ios/Podfile && \
	echo "flutter_ios_podfile_setup" >> ios/Podfile && \
	echo "" >> ios/Podfile && \
	echo "target 'Runner' do" >> ios/Podfile && \
	echo "  use_frameworks!" >> ios/Podfile && \
	echo "  use_modular_headers!" >> ios/Podfile && \
	echo "" >> ios/Podfile && \
	echo "  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))" >> ios/Podfile && \
	echo "" >> ios/Podfile && \
	echo "  target 'RunnerTests' do" >> ios/Podfile && \
	echo "    inherit! :search_paths" >> ios/Podfile && \
	echo "  end" >> ios/Podfile && \
	echo "end" >> ios/Podfile && \
	echo "" >> ios/Podfile && \
	echo "post_install do |installer|" >> ios/Podfile && \
	echo "  installer.pods_project.targets.each do |target|" >> ios/Podfile && \
	echo "    flutter_additional_ios_build_settings(target)" >> ios/Podfile && \
	echo "  end" >> ios/Podfile && \
	echo "end" >> ios/Podfile \
	)