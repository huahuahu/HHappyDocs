function buildScheme {
    set -e

    scheme=$1
    onlyIOS=$2
    destinationIOS="\"platform=iOS Simulator,name=iPhone 15,OS=17.0\""
    destinationMac="'platform=macOS,arch=x86_64'"

    destination1="-destination $destinationIOS -destination $destinationMac"

    if [ "$onlyIOS" = "--only-ios" ]; then
        destination1="-destination $destinationIOS"
    fi
    
    workspace="MonoProjects.xcworkspace"
    command="xcodebuild -workspace $workspace"
    command="$command -scheme $scheme"
    command="$command -configuration Debug"
    command="$command $destination1"
    command="$command CODE_SIGN_IDENTITY=\"-\""
    command="$command build"
    echo $command

    eval $command
}
