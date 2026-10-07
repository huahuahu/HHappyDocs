#!/usr/bin/env python3
"""Check reproducible generation and references without resolving dependencies."""

import json
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / "HDiary.xcodeproj"
SCHEMES = PROJECT / "xcshareddata/xcschemes"
TARGETS = {"HDiary", "HDiaryWidgetExtension", "HDiaryUITests", "HDiarySnapshotTests", "HDiarySnapshotHost"}


def generate():
    subprocess.run([str(ROOT / "scripts/generate-project.sh")], cwd=ROOT, check=True)
    files = [PROJECT / "project.pbxproj", *sorted(SCHEMES.glob("*.xcscheme"))]
    return {str(path.relative_to(PROJECT)): path.read_bytes() for path in files}


first = generate()
assert first == generate(), "Repeated generation changed project contents"
assert (ROOT / "Package.resolved").read_bytes() == (
    PROJECT / "project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
).read_bytes(), "Generated workspace does not have the canonical dependency lock"

project = json.loads(subprocess.check_output([
    "plutil", "-convert", "json", "-o", "-", str(PROJECT / "project.pbxproj")
]))
objects = project["objects"]
targets = {value["name"]: key for key, value in objects.items() if value["isa"] == "PBXNativeTarget"}
assert set(targets) == TARGETS, f"Unexpected targets: {targets}"
attributes = objects[project["rootObject"]]["attributes"]["TargetAttributes"]
assert attributes[targets["HDiaryUITests"]]["TestTargetID"] == targets["HDiary"], "UI test host is missing"
assert {p.stem for p in SCHEMES.glob("*.xcscheme")} == {
    "HDiary", "HDiaryWidgetExtension", "HDiarySnapshotHost"
}, "Shared schemes are missing or unexpected"

for path in SCHEMES.glob("*.xcscheme"):
    scheme = ET.parse(path)
    for reference in scheme.findall(".//BuildableReference"):
        assert targets[reference.get("BlueprintName")] == reference.get("BlueprintIdentifier"), path
    for plan in scheme.findall(".//TestPlanReference"):
        assert (ROOT / plan.get("reference").removeprefix("container:")).is_file(), path
    for storekit in scheme.findall(".//StoreKitConfigurationFileReference"):
        assert (PROJECT / storekit.get("identifier")).is_file(), path


def check_plan_references(value):
    if isinstance(value, dict):
        if value.get("containerPath") == "container:HDiary.xcodeproj":
            assert targets[value["name"]] == value["identifier"], (
                f"Update the {value['name']} identifier in the test plan after renaming a target"
            )
        for child in value.values():
            check_plan_references(child)
    elif isinstance(value, list):
        for child in value:
            check_plan_references(child)


for plan in [ROOT / "HDiary.xctestplan", ROOT / "HDiary/HDiary.xctestplan",
             ROOT / "HDiarySnapshotTests/HDiarySnapshots.xctestplan"]:
    check_plan_references(json.loads(plan.read_text()))

widget = ET.parse(SCHEMES / "HDiaryWidgetExtension.xcscheme")
assert widget.find("LaunchAction/RemoteRunnable").get("BundleIdentifier") == "com.apple.springboard"
assert widget.find("ProfileAction/BuildableProductRunnable/BuildableReference").get("BlueprintName") == "HDiary"
assert ET.parse(SCHEMES / "HDiary.xcscheme").find("LaunchAction/StoreKitConfigurationFileReference") is not None

tracked = subprocess.check_output(["git", "ls-files", "HDiary.xcodeproj"], cwd=ROOT, text=True)
assert not tracked.strip(), "Generated project files must not be tracked by Git"
print("Verified stable generation, targets, schemes, test plans, StoreKit, and dependency lock.")
