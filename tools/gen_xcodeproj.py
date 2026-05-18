#!/usr/bin/env python3
"""Generate TomatoClock.xcodeproj/project.pbxproj (macOS SwiftUI app + unit/UI tests).

警告：默认使用随机 UUID；重新生成会改变各 Target 的 ID，需同步更新
`TomatoClock.xcodeproj/xcshareddata/xcschemes/TomatoClock.xcscheme` 中的 BlueprintIdentifier。
"""
import os
import secrets


def uid() -> str:
    return secrets.token_hex(12).upper()


# --- identifiers ---
PROJECT = uid()
ROOT_GROUP = uid()
PRODUCTS_GROUP = uid()
APP_GROUP = uid()
TESTS_GROUP = uid()
UITESTS_GROUP = uid()

DOMAIN = uid()
THEME = uid()
SERVICES = uid()
FEATURES = uid()
TIMERF = uid()
SETTINGSF = uid()

APP_TARGET = uid()
TEST_TARGET = uid()
UITEST_TARGET = uid()

APP_PRODUCT = uid()
TEST_PRODUCT = uid()
UITEST_PRODUCT = uid()

APP_SOURCES = uid()
APP_FRAMEWORKS = uid()
APP_RESOURCES = uid()
TEST_SOURCES = uid()
UITEST_SOURCES = uid()

DEP_TEST_APP = uid()
PROXY_TEST_APP = uid()
DEP_UI_APP = uid()
PROXY_UI_APP = uid()

PROJ_CFG_LIST = uid()
APP_CFG_LIST = uid()
TEST_CFG_LIST = uid()
UI_CFG_LIST = uid()

CFG_PROJ_DEBUG = uid()
CFG_PROJ_RELEASE = uid()
CFG_APP_DEBUG = uid()
CFG_APP_RELEASE = uid()
CFG_TEST_DEBUG = uid()
CFG_TEST_RELEASE = uid()
CFG_UI_DEBUG = uid()
CFG_UI_RELEASE = uid()

ENT_REF = uid()
TEST_FILE_REF = uid()
TEST_BUILD = uid()
UI_FILE_REF = uid()
UI_BUILD = uid()

FILES = [
    ("TomatoClock/TomatoClockApp.swift", "TomatoClockApp.swift"),
    ("TomatoClock/Domain/PomodoroPhase.swift", "PomodoroPhase.swift"),
    ("TomatoClock/Domain/PomodoroConfig.swift", "PomodoroConfig.swift"),
    ("TomatoClock/Domain/PomodoroEngine.swift", "PomodoroEngine.swift"),
    ("TomatoClock/Theme/TomatoPalette.swift", "TomatoPalette.swift"),
    ("TomatoClock/Services/PomodoroPersistence.swift", "PomodoroPersistence.swift"),
    ("TomatoClock/Services/PomodoroNotificationService.swift", "PomodoroNotificationService.swift"),
    ("TomatoClock/Features/Timer/TimerViewModel.swift", "TimerViewModel.swift"),
    ("TomatoClock/Features/Timer/TimerRootView.swift", "TimerRootView.swift"),
    ("TomatoClock/Features/Settings/SettingsView.swift", "SettingsView.swift"),
]

app_pairs = []
for _, name in FILES:
    app_pairs.append((uid(), uid(), name))

lines: list[str] = []
lines.append("// !$*UTF8*$!")
lines.append("{")
lines.append("\tarchiveVersion = 1;")
lines.append("\tclasses = {};")
lines.append("\tobjectVersion = 56;")
lines.append("\tobjects = {")

# PBXBuildFile
lines.append("\n/* Begin PBXBuildFile section */")
for fr, bf, name in app_pairs:
    lines.append(f"\t\t{bf} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fr}; }};")
lines.append(
    f"\t\t{TEST_BUILD} /* PomodoroEngineTests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {TEST_FILE_REF}; }};"
)
lines.append(
    f"\t\t{UI_BUILD} /* TomatoClockUITests.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {UI_FILE_REF}; }};"
)
lines.append("/* End PBXBuildFile section */")

# PBXFileReference
lines.append("\n/* Begin PBXFileReference section */")
lines.append(
    f"\t\t{APP_PRODUCT} /* TomatoClock.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = TomatoClock.app; sourceTree = BUILT_PRODUCTS_DIR; }};"
)
lines.append(
    f"\t\t{TEST_PRODUCT} /* TomatoClockTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = TomatoClockTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};"
)
lines.append(
    f"\t\t{UITEST_PRODUCT} /* TomatoClockUITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = TomatoClockUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};"
)
for fr, _, name in app_pairs:
    lines.append(
        f"\t\t{fr} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{name}\"; sourceTree = \"<group>\"; }};"
    )
lines.append(
    f"\t\t{ENT_REF} /* TomatoClock.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = TomatoClock.entitlements; sourceTree = \"<group>\"; }};"
)
lines.append(
    f"\t\t{TEST_FILE_REF} /* PomodoroEngineTests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PomodoroEngineTests.swift; sourceTree = \"<group>\"; }};"
)
lines.append(
    f"\t\t{UI_FILE_REF} /* TomatoClockUITests.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TomatoClockUITests.swift; sourceTree = \"<group>\"; }};"
)
lines.append("/* End PBXFileReference section */")

# PBXFrameworksBuildPhase
lines.append("\n/* Begin PBXFrameworksBuildPhase section */")
lines.append(f"\t\t{APP_FRAMEWORKS} /* Frameworks */ = {{")
lines.append("\t\t\tisa = PBXFrameworksBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")
lines.append("/* End PBXFrameworksBuildPhase section */")

# PBXGroup
lines.append("\n/* Begin PBXGroup section */")
lines.append(f"\t\t{ROOT_GROUP} = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{APP_GROUP},")
lines.append(f"\t\t\t\t{TESTS_GROUP},")
lines.append(f"\t\t\t\t{UITESTS_GROUP},")
lines.append(f"\t\t\t\t{PRODUCTS_GROUP},")
lines.append("\t\t\t);")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

lines.append(f"\t\t{PRODUCTS_GROUP} /* Products */ = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{APP_PRODUCT},")
lines.append(f"\t\t\t\t{TEST_PRODUCT},")
lines.append(f"\t\t\t\t{UITEST_PRODUCT},")
lines.append("\t\t\t);")
lines.append("\t\t\tname = Products;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

lines.append(f"\t\t{APP_GROUP} /* TomatoClock */ = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{app_pairs[0][0]},")
lines.append(f"\t\t\t\t{ENT_REF},")
lines.append(f"\t\t\t\t{DOMAIN},")
lines.append(f"\t\t\t\t{THEME},")
lines.append(f"\t\t\t\t{SERVICES},")
lines.append(f"\t\t\t\t{FEATURES},")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = TomatoClock;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

lines.append(f"\t\t{DOMAIN} /* Domain */ = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{app_pairs[1][0]},")
lines.append(f"\t\t\t\t{app_pairs[2][0]},")
lines.append(f"\t\t\t\t{app_pairs[3][0]},")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = Domain;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

lines.append(f"\t\t{THEME} /* Theme */ = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{app_pairs[4][0]},")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = Theme;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

lines.append(f"\t\t{SERVICES} /* Services */ = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{app_pairs[5][0]},")
lines.append(f"\t\t\t\t{app_pairs[6][0]},")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = Services;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

lines.append(f"\t\t{FEATURES} /* Features */ = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{TIMERF},")
lines.append(f"\t\t\t\t{SETTINGSF},")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = Features;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

lines.append(f"\t\t{TIMERF} /* Timer */ = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{app_pairs[7][0]},")
lines.append(f"\t\t\t\t{app_pairs[8][0]},")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = Timer;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

lines.append(f"\t\t{SETTINGSF} /* Settings */ = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{app_pairs[9][0]},")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = Settings;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

lines.append(f"\t\t{TESTS_GROUP} /* TomatoClockTests */ = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{TEST_FILE_REF},")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = TomatoClockTests;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

lines.append(f"\t\t{UITESTS_GROUP} /* TomatoClockUITests */ = {{")
lines.append("\t\t\tisa = PBXGroup;")
lines.append("\t\t\tchildren = (")
lines.append(f"\t\t\t\t{UI_FILE_REF},")
lines.append("\t\t\t);")
lines.append("\t\t\tpath = TomatoClockUITests;")
lines.append("\t\t\tsourceTree = \"<group>\";")
lines.append("\t\t};")

lines.append("/* End PBXGroup section */")

# PBXNativeTarget
lines.append("\n/* Begin PBXNativeTarget section */")
lines.append(f"\t\t{APP_TARGET} /* TomatoClock */ = {{")
lines.append("\t\t\tisa = PBXNativeTarget;")
lines.append(f"\t\t\tbuildConfigurationList = {APP_CFG_LIST} /* Build configuration list for PBXNativeTarget \"TomatoClock\" */;")
lines.append("\t\t\tbuildPhases = (")
lines.append(f"\t\t\t\t{APP_SOURCES},")
lines.append(f"\t\t\t\t{APP_FRAMEWORKS},")
lines.append(f"\t\t\t\t{APP_RESOURCES},")
lines.append("\t\t\t);")
lines.append("\t\t\tbuildRules = (")
lines.append("\t\t\t);")
lines.append("\t\t\tdependencies = (")
lines.append("\t\t\t);")
lines.append("\t\t\tname = TomatoClock;")
lines.append("\t\t\tproductName = TomatoClock;")
lines.append(f"\t\t\tproductReference = {APP_PRODUCT} /* TomatoClock.app */;")
lines.append("\t\t\tproductType = \"com.apple.product-type.application\";")
lines.append("\t\t};")

lines.append(f"\t\t{TEST_TARGET} /* TomatoClockTests */ = {{")
lines.append("\t\t\tisa = PBXNativeTarget;")
lines.append(f"\t\t\tbuildConfigurationList = {TEST_CFG_LIST} /* Build configuration list for PBXNativeTarget \"TomatoClockTests\" */;")
lines.append("\t\t\tbuildPhases = (")
lines.append(f"\t\t\t\t{TEST_SOURCES},")
lines.append("\t\t\t);")
lines.append("\t\t\tbuildRules = (")
lines.append("\t\t\t);")
lines.append("\t\t\tdependencies = (")
lines.append(f"\t\t\t\t{DEP_TEST_APP},")
lines.append("\t\t\t);")
lines.append("\t\t\tname = TomatoClockTests;")
lines.append("\t\t\tproductName = TomatoClockTests;")
lines.append(f"\t\t\tproductReference = {TEST_PRODUCT} /* TomatoClockTests.xctest */;")
lines.append("\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";")
lines.append("\t\t};")

lines.append(f"\t\t{UITEST_TARGET} /* TomatoClockUITests */ = {{")
lines.append("\t\t\tisa = PBXNativeTarget;")
lines.append(f"\t\t\tbuildConfigurationList = {UI_CFG_LIST} /* Build configuration list for PBXNativeTarget \"TomatoClockUITests\" */;")
lines.append("\t\t\tbuildPhases = (")
lines.append(f"\t\t\t\t{UITEST_SOURCES},")
lines.append("\t\t\t);")
lines.append("\t\t\tbuildRules = (")
lines.append("\t\t\t);")
lines.append("\t\t\tdependencies = (")
lines.append(f"\t\t\t\t{DEP_UI_APP},")
lines.append("\t\t\t);")
lines.append("\t\t\tname = TomatoClockUITests;")
lines.append("\t\t\tproductName = TomatoClockUITests;")
lines.append(f"\t\t\tproductReference = {UITEST_PRODUCT} /* TomatoClockUITests.xctest */;")
lines.append("\t\t\tproductType = \"com.apple.product-type.bundle.ui-testing\";")
lines.append("\t\t};")
lines.append("/* End PBXNativeTarget section */")

# PBXProject
lines.append("\n/* Begin PBXProject section */")
lines.append(f"\t\t{PROJECT} /* Project object */ = {{")
lines.append("\t\t\tisa = PBXProject;")
lines.append("\t\t\tattributes = {")
lines.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
lines.append("\t\t\t\tLastSwiftUpdateCheck = 1500;")
lines.append("\t\t\t\tLastUpgradeCheck = 1500;")
lines.append("\t\t\t\tTargetAttributes = {")
lines.append(f"\t\t\t\t\t{APP_TARGET} = {{")
lines.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
lines.append("\t\t\t\t\t};")
lines.append(f"\t\t\t\t\t{TEST_TARGET} = {{")
lines.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
lines.append(f"\t\t\t\t\t\tTestTargetID = {APP_TARGET};")
lines.append("\t\t\t\t\t};")
lines.append(f"\t\t\t\t\t{UITEST_TARGET} = {{")
lines.append("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
lines.append(f"\t\t\t\t\t\tTestTargetID = {APP_TARGET};")
lines.append("\t\t\t\t\t};")
lines.append("\t\t\t\t};")
lines.append("\t\t\t};")
lines.append(f"\t\t\tbuildConfigurationList = {PROJ_CFG_LIST} /* Build configuration list for PBXProject \"TomatoClock\" */;")
lines.append("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
lines.append("\t\t\tdevelopmentRegion = en;")
lines.append("\t\t\thasScannedForEncodings = 0;")
lines.append("\t\t\tknownRegions = (")
lines.append("\t\t\t\ten,")
lines.append("\t\t\t\tBase,")
lines.append("\t\t\t);")
lines.append(f"\t\t\tmainGroup = {ROOT_GROUP};")
lines.append(f"\t\t\tproductRefGroup = {PRODUCTS_GROUP} /* Products */;")
lines.append("\t\t\tprojectDirPath = \"\";")
lines.append("\t\t\tprojectRoot = \"\";")
lines.append("\t\t\ttargets = (")
lines.append(f"\t\t\t\t{APP_TARGET},")
lines.append(f"\t\t\t\t{TEST_TARGET},")
lines.append(f"\t\t\t\t{UITEST_TARGET},")
lines.append("\t\t\t);")
lines.append("\t\t};")
lines.append("/* End PBXProject section */")

# PBXResourcesBuildPhase
lines.append("\n/* Begin PBXResourcesBuildPhase section */")
lines.append(f"\t\t{APP_RESOURCES} /* Resources */ = {{")
lines.append("\t\t\tisa = PBXResourcesBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")
lines.append("/* End PBXResourcesBuildPhase section */")

# PBXSourcesBuildPhase
lines.append("\n/* Begin PBXSourcesBuildPhase section */")
lines.append(f"\t\t{APP_SOURCES} /* Sources */ = {{")
lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
for _, bf, name in app_pairs:
    lines.append(f"\t\t\t\t{bf} /* {name} in Sources */,")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")

lines.append(f"\t\t{TEST_SOURCES} /* Sources */ = {{")
lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
lines.append(f"\t\t\t\t{TEST_BUILD} /* PomodoroEngineTests.swift in Sources */,")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")

lines.append(f"\t\t{UITEST_SOURCES} /* Sources */ = {{")
lines.append("\t\t\tisa = PBXSourcesBuildPhase;")
lines.append("\t\t\tbuildActionMask = 2147483647;")
lines.append("\t\t\tfiles = (")
lines.append(f"\t\t\t\t{UI_BUILD} /* TomatoClockUITests.swift in Sources */,")
lines.append("\t\t\t);")
lines.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
lines.append("\t\t};")
lines.append("/* End PBXSourcesBuildPhase section */")

# PBXContainerItemProxy / PBXTargetDependency
lines.append("\n/* Begin PBXContainerItemProxy section */")
lines.append(f"\t\t{PROXY_TEST_APP} /* PBXContainerItemProxy */ = {{")
lines.append("\t\t\tisa = PBXContainerItemProxy;")
lines.append(f"\t\t\tcontainerPortal = {PROJECT} /* Project object */;")
lines.append("\t\t\tproxyType = 1;")
lines.append(f"\t\t\tremoteGlobalIDString = {APP_TARGET};")
lines.append("\t\t\tremoteInfo = TomatoClock;")
lines.append("\t\t};")
lines.append(f"\t\t{PROXY_UI_APP} /* PBXContainerItemProxy */ = {{")
lines.append("\t\t\tisa = PBXContainerItemProxy;")
lines.append(f"\t\t\tcontainerPortal = {PROJECT} /* Project object */;")
lines.append("\t\t\tproxyType = 1;")
lines.append(f"\t\t\tremoteGlobalIDString = {APP_TARGET};")
lines.append("\t\t\tremoteInfo = TomatoClock;")
lines.append("\t\t};")
lines.append("/* End PBXContainerItemProxy section */")

lines.append("\n/* Begin PBXTargetDependency section */")
lines.append(f"\t\t{DEP_TEST_APP} /* PBXTargetDependency */ = {{")
lines.append("\t\t\tisa = PBXTargetDependency;")
lines.append(f"\t\t\ttarget = {APP_TARGET} /* TomatoClock */;")
lines.append(f"\t\t\ttargetProxy = {PROXY_TEST_APP} /* PBXContainerItemProxy */;")
lines.append("\t\t};")
lines.append(f"\t\t{DEP_UI_APP} /* PBXTargetDependency */ = {{")
lines.append("\t\t\tisa = PBXTargetDependency;")
lines.append(f"\t\t\ttarget = {APP_TARGET} /* TomatoClock */;")
lines.append(f"\t\t\ttargetProxy = {PROXY_UI_APP} /* PBXContainerItemProxy */;")
lines.append("\t\t};")
lines.append("/* End PBXTargetDependency section */")

# XCBuildConfiguration helpers
common_swift = [
    "\t\t\t\tCLANG_ENABLE_MODULES = YES;",
    "\t\t\t\tCURRENT_PROJECT_VERSION = 1;",
    "\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 12.0;",
    "\t\t\t\tMARKETING_VERSION = 0.1.0;",
    "\t\t\t\tSWIFT_VERSION = 5.0;",
]


def cfg_app(cid: str, debug: bool) -> None:
    lines.append(f"\t\t{cid} /* {'Debug' if debug else 'Release'} */ = {{")
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append("\t\t\tbuildSettings = {")
    lines.extend(common_swift)
    if debug:
        lines.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
        lines.append("\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;")
        lines.append("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
        lines.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
        lines.append("\t\t\t\tENABLE_TESTABILITY = YES;")
    else:
        lines.append("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
        lines.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";")
    lines.append("\t\t\t\tASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;")
    lines.append("\t\t\t\tCODE_SIGN_ENTITLEMENTS = TomatoClock/TomatoClock.entitlements;")
    lines.append('\t\t\t\t"CODE_SIGN_IDENTITY[sdk=macosx*]" = "-";')
    lines.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    lines.append("\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;")
    lines.append("\t\t\t\tDEVELOPMENT_TEAM = \"\";")
    lines.append("\t\t\t\tENABLE_HARDENED_RUNTIME = YES;")
    lines.append("\t\t\t\tENABLE_PREVIEWS = YES;")
    lines.append("\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
    lines.append(
        '\t\t\t\tINFOPLIST_KEY_NSUserNotificationUsageDescription = "番茄钟在阶段结束时发送本地通知。";'
    )
    lines.append("\t\t\t\tINFOPLIST_KEY_NSHumanReadableCopyright = \"\";")
    lines.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
    lines.append("\t\t\t\t\t\"$(inherited)\",")
    lines.append("\t\t\t\t\t\"@executable_path/../Frameworks\",")
    lines.append("\t\t\t\t);")
    lines.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.tsdy.TomatoClock;")
    lines.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    lines.append("\t\t\t};")
    lines.append(f"\t\t\tname = {'Debug' if debug else 'Release'};")
    lines.append("\t\t};")


def cfg_test(cid: str, debug: bool) -> None:
    lines.append(f"\t\t{cid} /* {'Debug' if debug else 'Release'} */ = {{")
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append("\t\t\tbuildSettings = {")
    lines.extend(common_swift)
    if debug:
        lines.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
        lines.append("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
        lines.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
    else:
        lines.append("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
        lines.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";")
    lines.append('\t\t\t\t"CODE_SIGN_IDENTITY[sdk=macosx*]" = "-";')
    lines.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    lines.append("\t\t\t\tDEVELOPMENT_TEAM = \"\";")
    lines.append("\t\t\t\tBUNDLE_LOADER = \"$(TEST_HOST)\";")
    lines.append("\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
    lines.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
    lines.append("\t\t\t\t\t\"$(inherited)\",")
    lines.append("\t\t\t\t\t\"@executable_path/../Frameworks\",")
    lines.append("\t\t\t\t\t\"@loader_path/../Frameworks\",")
    lines.append("\t\t\t\t);")
    lines.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.tsdy.TomatoClockTests;")
    lines.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    lines.append("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;")
    lines.append(
        '\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/TomatoClock.app/Contents/MacOS/TomatoClock";'
    )
    lines.append("\t\t\t};")
    lines.append(f"\t\t\tname = {'Debug' if debug else 'Release'};")
    lines.append("\t\t};")


def cfg_ui(cid: str, debug: bool) -> None:
    lines.append(f"\t\t{cid} /* {'Debug' if debug else 'Release'} */ = {{")
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append("\t\t\tbuildSettings = {")
    lines.extend(common_swift)
    if debug:
        lines.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
        lines.append("\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;")
        lines.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
    else:
        lines.append("\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;")
        lines.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";")
    lines.append('\t\t\t\t"CODE_SIGN_IDENTITY[sdk=macosx*]" = "-";')
    lines.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    lines.append("\t\t\t\tDEVELOPMENT_TEAM = \"\";")
    lines.append("\t\t\t\tGENERATE_INFOPLIST_FILE = YES;")
    lines.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (")
    lines.append("\t\t\t\t\t\"$(inherited)\",")
    lines.append("\t\t\t\t\t\"@executable_path/../Frameworks\",")
    lines.append("\t\t\t\t\t\"@loader_path/../Frameworks\",")
    lines.append("\t\t\t\t);")
    lines.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.tsdy.TomatoClockUITests;")
    lines.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    lines.append("\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;")
    lines.append("\t\t\t\tTEST_TARGET_NAME = TomatoClock;")
    lines.append("\t\t\t};")
    lines.append(f"\t\t\tname = {'Debug' if debug else 'Release'};")
    lines.append("\t\t};")


def cfg_proj(cid: str, debug: bool) -> None:
    lines.append(f"\t\t{cid} /* {'Debug' if debug else 'Release'} */ = {{")
    lines.append("\t\t\tisa = XCBuildConfiguration;")
    lines.append("\t\t\tbuildSettings = {")
    lines.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    lines.append("\t\t\t\tCLANG_ANALYZER_NONNULL = YES;")
    lines.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    lines.append("\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;")
    lines.append("\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 12.0;")
    lines.append("\t\t\t\tSDKROOT = macosx;")
    lines.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    lines.append("\t\t\t};")
    lines.append(f"\t\t\tname = {'Debug' if debug else 'Release'};")
    lines.append("\t\t};")


lines.append("\n/* Begin XCBuildConfiguration section */")
cfg_app(CFG_APP_DEBUG, True)
cfg_app(CFG_APP_RELEASE, False)
cfg_test(CFG_TEST_DEBUG, True)
cfg_test(CFG_TEST_RELEASE, False)
cfg_ui(CFG_UI_DEBUG, True)
cfg_ui(CFG_UI_RELEASE, False)
cfg_proj(CFG_PROJ_DEBUG, True)
cfg_proj(CFG_PROJ_RELEASE, False)
lines.append("/* End XCBuildConfiguration section */")

# XCConfigurationList
lines.append("\n/* Begin XCConfigurationList section */")
lines.append(f"\t\t{PROJ_CFG_LIST} /* Build configuration list for PBXProject */ = {{")
lines.append("\t\t\tisa = XCConfigurationList;")
lines.append("\t\t\tbuildConfigurations = (")
lines.append(f"\t\t\t\t{CFG_PROJ_DEBUG},")
lines.append(f"\t\t\t\t{CFG_PROJ_RELEASE},")
lines.append("\t\t\t);")
lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
lines.append("\t\t\tdefaultConfigurationName = Release;")
lines.append("\t\t};")

lines.append(f"\t\t{APP_CFG_LIST} /* Build configuration list for PBXNativeTarget \"TomatoClock\" */ = {{")
lines.append("\t\t\tisa = XCConfigurationList;")
lines.append("\t\t\tbuildConfigurations = (")
lines.append(f"\t\t\t\t{CFG_APP_DEBUG},")
lines.append(f"\t\t\t\t{CFG_APP_RELEASE},")
lines.append("\t\t\t);")
lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
lines.append("\t\t\tdefaultConfigurationName = Release;")
lines.append("\t\t};")

lines.append(f"\t\t{TEST_CFG_LIST} /* Build configuration list for PBXNativeTarget \"TomatoClockTests\" */ = {{")
lines.append("\t\t\tisa = XCConfigurationList;")
lines.append("\t\t\tbuildConfigurations = (")
lines.append(f"\t\t\t\t{CFG_TEST_DEBUG},")
lines.append(f"\t\t\t\t{CFG_TEST_RELEASE},")
lines.append("\t\t\t);")
lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
lines.append("\t\t\tdefaultConfigurationName = Release;")
lines.append("\t\t};")

lines.append(f"\t\t{UI_CFG_LIST} /* Build configuration list for PBXNativeTarget \"TomatoClockUITests\" */ = {{")
lines.append("\t\t\tisa = XCConfigurationList;")
lines.append("\t\t\tbuildConfigurations = (")
lines.append(f"\t\t\t\t{CFG_UI_DEBUG},")
lines.append(f"\t\t\t\t{CFG_UI_RELEASE},")
lines.append("\t\t\t);")
lines.append("\t\t\tdefaultConfigurationIsVisible = 0;")
lines.append("\t\t\tdefaultConfigurationName = Release;")
lines.append("\t\t};")
lines.append("/* End XCConfigurationList section */")

lines.append("\t};")
lines.append(f"\trootObject = {PROJECT} /* Project object */;")
lines.append("}")

text = "\n".join(lines) + "\n"

out_dir = os.path.join(os.path.dirname(__file__), "..", "TomatoClock.xcodeproj")
out_dir = os.path.abspath(out_dir)
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, "project.pbxproj")
with open(out_path, "w", encoding="utf-8") as f:
    f.write(text)
print("Wrote", out_path)
