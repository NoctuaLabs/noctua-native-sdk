#!/usr/bin/env python3
"""
Coverage gate for the Noctua native SDK (iOS + Android).

Raw whole-module line coverage is structurally capped well below 70% because the
SDK is dominated by native/framework code that cannot run in unit tests:
  - iOS:     StoreKit 2 (StoreKitService, ~800 lines), the @_cdecl Inspector
             bridges, and the real Adjust/Firebase/Facebook SDK init wrappers.
  - Android: NoctuaPresenter (Activity/Context deps), the service classes (real
             Adjust/Firebase/Facebook/Billing SDKs), JNI/ContentProvider/platform,
             and repositories.

This gate measures the *unit-testable* layer by excluding those native-bridge
files from the denominator — the same policy the Unity consumer project applies
to its own coverage report — and fails if that layer drops below the threshold.

Usage:
  iOS:     python3 scripts/coverage_gate.py --platform ios     --report <result.xcresult> [--threshold 70]
  Android: python3 scripts/coverage_gate.py --platform android --report <jacoco report.xml> [--threshold 70]
"""
import argparse
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

# --- Native / framework files excluded from the TESTABLE denominator -------------------

IOS_EXCLUDE = re.compile(
    r"/Sources/(?:"
    r"Service/StoreKitService\.swift|Service/StoreKit1Service\.swift|"
    r"Service/AdjustService\.swift|Service/FirebaseService\.swift|"
    r"Service/FacebookService\.swift|Service/NoctuaInternalService\.swift|"
    r"Repository/AccountRepository\.swift|"
    r"Inspector/(?:NoctuaInspectorBridge|DeviceMetricsProvider|NativeHttpCacheCleaner|"
    r"BuildInfoProvider|FirebaseLogTailer)\.swift"
    r")$"
)

ANDROID_EXCLUDE = re.compile(
    r"(?:"
    r"presenter/NoctuaPresenter|"
    r"services/|platform/|repositories/|"
    r"inspector/(?:LogTailer|BuildInfoProvider|NativeHttpCacheCleaner|NoctuaInspector(?!Bus|TrackerEventPhase)|DeviceMetricsProvider)|"
    r"models/AdjustModelKt|utils/UtilsKt"
    r")"
)


def gate_ios(result_bundle: str):
    raw = subprocess.run(
        ["xcrun", "xccov", "view", "--report", "--json", result_bundle],
        capture_output=True, text=True, check=True,
    ).stdout
    report = json.loads(raw)
    tcov = ttot = rcov = rtot = 0
    for target in report.get("targets", []):
        if target.get("name") != "NoctuaSDK.framework":
            continue
        for f in target.get("files", []):
            cov = f.get("coveredLines", 0)
            tot = f.get("executableLines", 0)
            rcov += cov; rtot += tot
            if IOS_EXCLUDE.search(f.get("path", "")):
                continue
            tcov += cov; ttot += tot
    return rcov, rtot, tcov, ttot


def gate_android(report_xml: str):
    root = ET.parse(report_xml).getroot()

    def line_counter(el):
        for c in el.findall("counter"):
            if c.get("type") == "LINE":
                return int(c.get("missed")), int(c.get("covered"))
        return 0, 0

    tcov = ttot = rcov = rtot = 0
    for pkg in root.findall("package"):
        short = pkg.get("name").split("/")[-1]
        for cl in pkg.findall("class"):
            name = short + "/" + cl.get("name").split("/")[-1]
            m, cov = line_counter(cl)
            rcov += cov; rtot += (m + cov)
            full = cl.get("name")
            if ANDROID_EXCLUDE.search(name) or full.endswith("/Noctua"):
                continue
            tcov += cov; ttot += (m + cov)
    return rcov, rtot, tcov, ttot


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--platform", required=True, choices=["ios", "android"])
    ap.add_argument("--report", required=True, help="xcresult bundle (iOS) or jacoco report.xml (Android)")
    ap.add_argument("--threshold", type=float, default=70.0)
    args = ap.parse_args()

    rcov, rtot, tcov, ttot = (gate_ios if args.platform == "ios" else gate_android)(args.report)
    raw_pct = 100 * rcov / rtot if rtot else 0.0
    test_pct = 100 * tcov / ttot if ttot else 0.0

    print(f"[{args.platform}] raw line coverage:      {rcov}/{rtot} = {raw_pct:.2f}%")
    print(f"[{args.platform}] testable line coverage:  {tcov}/{ttot} = {test_pct:.2f}%  (native bridges excluded)")
    print(f"[{args.platform}] threshold:               {args.threshold:.0f}%")

    if test_pct < args.threshold:
        print(f"FAIL: testable coverage {test_pct:.2f}% < {args.threshold:.0f}%")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
