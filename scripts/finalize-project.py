#!/usr/bin/env python3
"""Preserve scheme options that XcodeGen 2.46.0 cannot express."""

from copy import deepcopy
from pathlib import Path
import xml.etree.ElementTree as ET

schemes = Path(__file__).resolve().parent.parent / "HDiary.xcodeproj/xcshareddata/xcschemes"

widget_path = schemes / "HDiaryWidgetExtension.xcscheme"
widget = ET.parse(widget_path)
widget.find("TestAction").set("shouldAutocreateTestPlan", "YES")
launch = widget.find("LaunchAction")
runnable = launch.find("BuildableProductRunnable")
# WidgetKit runs in SpringBoard; the extension is not a standalone executable.
runnable.tag = "RemoteRunnable"
runnable.attrib = {"runnableDebuggingMode": "2", "BundleIdentifier": "com.apple.springboard"}
profile = widget.find("ProfileAction")
profile.set("launchAutomaticallySubstyle", "2")
profile_runnable = profile.find("BuildableProductRunnable")
profile_runnable.remove(profile_runnable.find("BuildableReference"))
profile_runnable.append(deepcopy(launch.find("MacroExpansion/BuildableReference")))
ET.indent(widget, space="   ")
widget.write(widget_path, encoding="UTF-8", xml_declaration=True)

host_path = schemes / "HDiarySnapshotHost.xcscheme"
host = ET.parse(host_path)
host.find("LaunchAction").set("queueDebuggingEnabled", "No")
ET.indent(host, space="   ")
host.write(host_path, encoding="UTF-8", xml_declaration=True)
