function testScheme {
    set -e

    scheme=$1
    destinationIOS="platform=iOS Simulator,name=iPhone 17 Pro"

    project="HDiary.xcodeproj"

    xcodebuild \
        clean \
        test \
        -project $project \
        -scheme $scheme \
        -configuration Debug \
        -destination "$destinationIOS" \
        CODE_SIGN_IDENTITY="-"
}
