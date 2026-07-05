function testScheme {
    set -e

    scheme=$1
    destinationIOS="platform=iOS Simulator,name=iPhone 14,OS=17.0"

    workspace="MonoProjects.xcworkspace"

    xcodebuild \
        clean \
        test \
        -workspace $workspace \
        -scheme $scheme \
        -configuration Debug \
        -destination "$destinationIOS" \
        CODE_SIGN_IDENTITY="-"
}
