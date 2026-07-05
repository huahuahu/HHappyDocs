TARGET ?= HDiary

ios-lint-fix:
	./Pods/SwiftLint/swiftlint --fix --quiet; \
	./Pods/SwiftFormat/CommandLineTool/swiftformat . --config .swiftformat; 

ios-lint-check:
	./Pods/SwiftLint/swiftlint --quiet || exit $0; \
	./Pods/SwiftFormat/CommandLineTool/swiftformat --lint . --config .swiftformat || exit $0;

ios-build:
	bash -c 'source scripts/build-ios-project.sh; buildScheme "$$1" --only-ios' _ "$(TARGET)"

ios-test:
	bash -c 'source scripts/test-ios-project.sh; testScheme "$$1"' _ "$(TARGET)"