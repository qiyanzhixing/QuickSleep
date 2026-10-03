.PHONY: setup test verify-assets
setup:
	python3 tools/restore_assets.py
	flutter pub get
	flutter gen-l10n

test: setup
	flutter analyze
	flutter test
	python3 -m unittest discover -s tools/audio/tests -v

verify-assets:
	python3 tools/restore_assets.py --check
	python3 tools/audio/verify_assets.py assets/audio
