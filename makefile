TARGET ?= HDiary
TS_SCRIPT = dist/ci/src/index.js

ios-lint-fix:
	./Pods/SwiftLint/swiftlint --fix --quiet; \
	./Pods/SwiftFormat/CommandLineTool/swiftformat . --config .swiftformat; 

ios-lint-check:
	./Pods/SwiftLint/swiftlint --quiet || exit $0; \
	./Pods/SwiftFormat/CommandLineTool/swiftformat --lint . --config .swiftformat || exit $0;

prepare-ci:
	cd ci; \
	npm install; \
	npx nx build

ios-build:
	make prepare-ci; \
	cd ci; \
	node $(TS_SCRIPT) build -p $(TARGET)

ios-test:
	make prepare-ci; \
	cd ci; \
	node $(TS_SCRIPT) test -p $(TARGET)