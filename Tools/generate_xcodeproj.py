#!/usr/bin/env python3
"""Generate HSMacOSTracker.xcodeproj from App/Core/Data/Features/Tests."""
from pathlib import Path
import uuid

ROOT = Path(__file__).resolve().parent.parent
BUNDLE_ID = "io.github.sunmoo.hs-macos-tracker"

APP_SOURCES = sorted((ROOT / "App").glob("*.swift"))
LIB_SOURCES = sorted((ROOT / "Core").rglob("*.swift"))
LIB_SOURCES += sorted((ROOT / "Data").rglob("*.swift"))
LIB_SOURCES += sorted((ROOT / "Features").rglob("*.swift"))
TEST_SOURCES = sorted((ROOT / "Tests").glob("*.swift"))


def uid() -> str:
    return uuid.uuid4().hex[:24].upper()


ids: dict[str, str] = {}


def ref_id(path: Path) -> str:
    key = str(path.relative_to(ROOT))
    if key not in ids:
        ids[key] = uid()
    return ids[key]


def build_id(path: Path) -> str:
    key = f"build:{path}"
    if key not in ids:
        ids[key] = uid()
    return ids[key]


def main() -> None:
    project_id = uid()
    main_group = uid()
    products_group = uid()
    app_target = uid()
    lib_target = uid()
    test_target = uid()
    app_product = uid()
    lib_product = uid()
    test_product = uid()
    app_sources_phase = uid()
    lib_sources_phase = uid()
    test_sources_phase = uid()
    app_frameworks_phase = uid()
    lib_frameworks_phase = uid()
    test_frameworks_phase = uid()
    app_resources_phase = uid()
    embed_frameworks_phase = uid()
    app_proxy = uid()
    test_proxy = uid()
    app_dep = uid()
    test_dep = uid()
    project_config_list = uid()
    app_config_list = uid()
    lib_config_list = uid()
    test_config_list = uid()
    debug_proj = uid()
    release_proj = uid()
    debug_app = uid()
    release_app = uid()
    debug_lib = uid()
    release_lib = uid()
    debug_test = uid()
    release_test = uid()
    info_plist = ref_id(ROOT / "Resources/Info.plist")
    lib_build_ref = uid()
    embed_build_ref = uid()
    test_lib_build_ref = uid()

    lines: list[str] = []
    add = lines.append

    add("// !$*UTF8*$!")
    add("{")
    add("\tarchiveVersion = 1;")
    add("\tclasses = {};")
    add("\tobjectVersion = 56;")
    add("\tobjects = {")
    add("")
    add("/* Begin PBXBuildFile section */")

    app_source_entries = []
    for src in APP_SOURCES:
        rid = ref_id(src)
        bid = build_id(src)
        add(f"\t\t{bid} /* {src.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {rid} /* {src.name} */; }};")
        app_source_entries.append(f"\t\t\t\t{bid} /* {src.name} in Sources */,")

    lib_source_entries = []
    for src in LIB_SOURCES:
        rid = ref_id(src)
        bid = build_id(src)
        add(f"\t\t{bid} /* {src.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {rid} /* {src.name} */; }};")
        lib_source_entries.append(f"\t\t\t\t{bid} /* {src.name} in Sources */,")

    test_source_entries = []
    for src in TEST_SOURCES:
        rid = ref_id(src)
        bid = build_id(src)
        add(f"\t\t{bid} /* {src.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {rid} /* {src.name} */; }};")
        test_source_entries.append(f"\t\t\t\t{bid} /* {src.name} in Sources */,")

    add(
        f"\t\t{lib_build_ref} /* HSMacOSTrackerLib.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {lib_product} /* HSMacOSTrackerLib.framework */; }};"
    )
    add(
        f"\t\t{embed_build_ref} /* HSMacOSTrackerLib.framework in Embed Frameworks */ = {{isa = PBXBuildFile; fileRef = {lib_product}; settings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }}; }};"
    )
    add(
        f"\t\t{test_lib_build_ref} /* HSMacOSTrackerLib.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {lib_product} /* HSMacOSTrackerLib.framework */; }};"
    )
    add("/* End PBXBuildFile section */")
    add("")
    add("/* Begin PBXContainerItemProxy section */")
    add(f"\t\t{app_proxy} /* PBXContainerItemProxy */ = {{isa = PBXContainerItemProxy; containerPortal = {project_id}; proxyType = 1; remoteGlobalIDString = {lib_target}; remoteInfo = HSMacOSTrackerLib; }};")
    add(f"\t\t{test_proxy} /* PBXContainerItemProxy */ = {{isa = PBXContainerItemProxy; containerPortal = {project_id}; proxyType = 1; remoteGlobalIDString = {lib_target}; remoteInfo = HSMacOSTrackerLib; }};")
    add("/* End PBXContainerItemProxy section */")
    add("")
    add("/* Begin PBXFileReference section */")
    add(f"\t\t{app_product} /* HSMacOSTracker.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = HSMacOSTracker.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    add(f"\t\t{lib_product} /* HSMacOSTrackerLib.framework */ = {{isa = PBXFileReference; explicitFileType = wrapper.framework; includeInIndex = 0; path = HSMacOSTrackerLib.framework; sourceTree = BUILT_PRODUCTS_DIR; }};")
    add(f"\t\t{test_product} /* HSMacOSTrackerTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = HSMacOSTrackerTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};")

    for src in APP_SOURCES + LIB_SOURCES + TEST_SOURCES:
        rid = ref_id(src)
        rel = src.relative_to(ROOT)
        if src.parent.name in {"App", "Tests"}:
            add(f"\t\t{rid} /* {src.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {src.name}; sourceTree = \"<group>\"; }};")
        else:
            add(f"\t\t{rid} /* {src.name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {src.name}; sourceTree = \"<group>\"; }};")

    add(f"\t\t{info_plist} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};")
    add("/* End PBXFileReference section */")
    add("")
    add("/* Begin PBXFrameworksBuildPhase section */")
    add(f"\t\t{app_frameworks_phase} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({lib_build_ref} /* HSMacOSTrackerLib.framework in Frameworks */,); runOnlyForDeploymentPostprocessing = 0; }};")
    add(f"\t\t{lib_frameworks_phase} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};")
    add(f"\t\t{test_frameworks_phase} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({test_lib_build_ref} /* HSMacOSTrackerLib.framework in Frameworks */,); runOnlyForDeploymentPostprocessing = 0; }};")
    add("/* End PBXFrameworksBuildPhase section */")
    add("")
    add("/* Begin PBXCopyFilesBuildPhase section */")
    add(f"\t\t{embed_frameworks_phase} /* Embed Frameworks */ = {{isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = \"\"; dstSubfolderSpec = 10; files = ({embed_build_ref} /* HSMacOSTrackerLib.framework in Embed Frameworks */,); name = \"Embed Frameworks\"; runOnlyForDeploymentPostprocessing = 0; }};")
    add("/* End PBXCopyFilesBuildPhase section */")
    add("")
    add("/* Begin PBXGroup section */")

    app_group = uid()
    test_group = uid()
    resources_group = uid()
    core_group = uid()
    data_group = uid()
    features_group = uid()

    subgroup_ids = []
    subgroup_blocks = []

    for sub in sorted((ROOT / "Core").iterdir()):
        if sub.is_dir():
            gid = uid()
            subgroup_ids.append((gid, sub.name))
            children = ", ".join(f"{ref_id(s)} /* {s.name} */" for s in sorted(sub.glob("*.swift")))
            subgroup_blocks.append(f"\t\t{gid} /* {sub.name} */ = {{isa = PBXGroup; children = ({children},); path = {sub.name}; sourceTree = \"<group>\"; }};")

    card_gid = uid()
    card_children = ", ".join(f"{ref_id(s)} /* {s.name} */" for s in sorted((ROOT / "Data/CardCatalog").glob("*.swift")))
    subgroup_blocks.append(f"\t\t{card_gid} /* CardCatalog */ = {{isa = PBXGroup; children = ({card_children},); path = CardCatalog; sourceTree = \"<group>\"; }};")

    feat_ids = []
    for sub in sorted((ROOT / "Features").iterdir()):
        if sub.is_dir():
            gid = uid()
            feat_ids.append((gid, sub.name))
            children = ", ".join(f"{ref_id(s)} /* {s.name} */" for s in sorted(sub.glob("*.swift")))
            subgroup_blocks.append(f"\t\t{gid} /* {sub.name} */ = {{isa = PBXGroup; children = ({children},); path = {sub.name}; sourceTree = \"<group>\"; }};")

    add(f"\t\t{main_group} = {{isa = PBXGroup; children = ({app_group} /* App */, {core_group} /* Core */, {data_group} /* Data */, {features_group} /* Features */, {resources_group} /* Resources */, {test_group} /* Tests */, {products_group} /* Products */,); sourceTree = \"<group>\"; }};")
    add(f"\t\t{products_group} /* Products */ = {{isa = PBXGroup; children = ({app_product} /* HSMacOSTracker.app */, {lib_product} /* HSMacOSTrackerLib.framework */, {test_product} /* HSMacOSTrackerTests.xctest */,); name = Products; sourceTree = \"<group>\"; }};")

    app_children = ", ".join(f"{ref_id(s)} /* {s.name} */" for s in APP_SOURCES)
    add(f"\t\t{app_group} /* App */ = {{isa = PBXGroup; children = ({app_children},); path = App; sourceTree = \"<group>\"; }};")

    test_children = ", ".join(f"{ref_id(s)} /* {s.name} */" for s in TEST_SOURCES)
    add(f"\t\t{test_group} /* Tests */ = {{isa = PBXGroup; children = ({test_children},); path = Tests; sourceTree = \"<group>\"; }};")
    add(f"\t\t{resources_group} /* Resources */ = {{isa = PBXGroup; children = ({info_plist} /* Info.plist */,); path = Resources; sourceTree = \"<group>\"; }};")

    core_children = ", ".join(f"{gid} /* {name} */" for gid, name in subgroup_ids)
    add(f"\t\t{core_group} /* Core */ = {{isa = PBXGroup; children = ({core_children},); path = Core; sourceTree = \"<group>\"; }};")
    add(f"\t\t{data_group} /* Data */ = {{isa = PBXGroup; children = ({card_gid} /* CardCatalog */,); path = Data; sourceTree = \"<group>\"; }};")
    feat_children = ", ".join(f"{gid} /* {name} */" for gid, name in feat_ids)
    add(f"\t\t{features_group} /* Features */ = {{isa = PBXGroup; children = ({feat_children},); path = Features; sourceTree = \"<group>\"; }};")
    for block in subgroup_blocks:
        add(block)
    add("/* End PBXGroup section */")
    add("")
    add("/* Begin PBXNativeTarget section */")
    add(f"\t\t{app_target} /* HSMacOSTracker */ = {{isa = PBXNativeTarget; buildConfigurationList = {app_config_list}; buildPhases = ({app_sources_phase} /* Sources */, {app_frameworks_phase} /* Frameworks */, {app_resources_phase} /* Resources */, {embed_frameworks_phase} /* Embed Frameworks */,); buildRules = (); dependencies = ({app_dep} /* PBXTargetDependency */,); name = HSMacOSTracker; productName = HSMacOSTracker; productReference = {app_product}; productType = \"com.apple.product-type.application\"; }};")
    add(f"\t\t{lib_target} /* HSMacOSTrackerLib */ = {{isa = PBXNativeTarget; buildConfigurationList = {lib_config_list}; buildPhases = ({lib_sources_phase} /* Sources */, {lib_frameworks_phase} /* Frameworks */,); buildRules = (); dependencies = (); name = HSMacOSTrackerLib; productName = HSMacOSTrackerLib; productReference = {lib_product}; productType = \"com.apple.product-type.framework\"; }};")
    add(f"\t\t{test_target} /* HSMacOSTrackerTests */ = {{isa = PBXNativeTarget; buildConfigurationList = {test_config_list}; buildPhases = ({test_sources_phase} /* Sources */, {test_frameworks_phase} /* Frameworks */,); buildRules = (); dependencies = ({test_dep} /* PBXTargetDependency */,); name = HSMacOSTrackerTests; productName = HSMacOSTrackerTests; productReference = {test_product}; productType = \"com.apple.product-type.bundle.unit-test\"; }};")
    add("/* End PBXNativeTarget section */")
    add("")
    add("/* Begin PBXProject section */")
    add(f"\t\t{project_id} /* Project object */ = {{isa = PBXProject; attributes = {{BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 2600; LastUpgradeCheck = 2600;}}; buildConfigurationList = {project_config_list}; compatibilityVersion = \"Xcode 14.0\"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base,); mainGroup = {main_group}; productRefGroup = {products_group}; projectDirPath = \"\"; projectRoot = \"\"; targets = ({lib_target}, {app_target}, {test_target},); }};")
    add("/* End PBXProject section */")
    add("")
    add("/* Begin PBXResourcesBuildPhase section */")
    add(f"\t\t{app_resources_phase} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};")
    add("/* End PBXResourcesBuildPhase section */")
    add("")
    add("/* Begin PBXSourcesBuildPhase section */")
    add(f"\t\t{app_sources_phase} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({''.join(app_source_entries)}); runOnlyForDeploymentPostprocessing = 0; }};")
    add(f"\t\t{lib_sources_phase} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({''.join(lib_source_entries)}); runOnlyForDeploymentPostprocessing = 0; }};")
    add(f"\t\t{test_sources_phase} /* Sources */ = {{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({''.join(test_source_entries)}); runOnlyForDeploymentPostprocessing = 0; }};")
    add("/* End PBXSourcesBuildPhase section */")
    add("")
    add("/* Begin PBXTargetDependency section */")
    add(f"\t\t{app_dep} /* PBXTargetDependency */ = {{isa = PBXTargetDependency; target = {lib_target}; targetProxy = {app_proxy}; }};")
    add(f"\t\t{test_dep} /* PBXTargetDependency */ = {{isa = PBXTargetDependency; target = {lib_target}; targetProxy = {test_proxy}; }};")
    add("/* End PBXTargetDependency section */")
    add("")
    add("/* Begin XCBuildConfiguration section */")
    add(f"\t\t{debug_proj} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; COPY_PHASE_STRIP = NO; DEBUG_INFORMATION_FORMAT = dwarf; ENABLE_TESTABILITY = YES; MACOSX_DEPLOYMENT_TARGET = 14.0; ONLY_ACTIVE_ARCH = YES; SDKROOT = macosx; SWIFT_VERSION = 6.0;}}; name = Debug; }};")
    add(f"\t\t{release_proj} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_MODULES = YES; COPY_PHASE_STRIP = NO; DEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\"; MACOSX_DEPLOYMENT_TARGET = 14.0; SDKROOT = macosx; SWIFT_VERSION = 6.0;}}; name = Release; }};")
    add(f"\t\t{debug_app} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{CODE_SIGN_IDENTITY = \"-\"; CURRENT_PROJECT_VERSION = 1; GENERATE_INFOPLIST_FILE = NO; INFOPLIST_FILE = Resources/Info.plist; LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/../Frameworks\",); MARKETING_VERSION = 0.1.0; PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID}; PRODUCT_NAME = \"$(TARGET_NAME)\"; SWIFT_EMIT_LOC_STRINGS = YES;}}; name = Debug; }};")
    add(f"\t\t{release_app} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{CODE_SIGN_IDENTITY = \"-\"; CURRENT_PROJECT_VERSION = 1; GENERATE_INFOPLIST_FILE = NO; INFOPLIST_FILE = Resources/Info.plist; LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/../Frameworks\",); MARKETING_VERSION = 0.1.0; PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID}; PRODUCT_NAME = \"$(TARGET_NAME)\"; SWIFT_EMIT_LOC_STRINGS = YES;}}; name = Release; }};")
    add(f"\t\t{debug_lib} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{CODE_SIGN_IDENTITY = \"-\"; COMBINE_HIDPI_IMAGES = YES; CURRENT_PROJECT_VERSION = 1; DEFINES_MODULE = YES; DYLIB_INSTALL_NAME_BASE = \"@rpath\"; GENERATE_INFOPLIST_FILE = YES; INSTALL_PATH = \"$(LOCAL_LIBRARY_DIR)/Frameworks\"; LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/../Frameworks\", \"@loader_path/Frameworks\",); MARKETING_VERSION = 0.1.0; PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID}.lib; PRODUCT_NAME = \"$(TARGET_NAME:c99extidentifier)\"; SKIP_INSTALL = YES; SWIFT_EMIT_LOC_STRINGS = NO;}}; name = Debug; }};")
    add(f"\t\t{release_lib} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{CODE_SIGN_IDENTITY = \"-\"; COMBINE_HIDPI_IMAGES = YES; CURRENT_PROJECT_VERSION = 1; DEFINES_MODULE = YES; DYLIB_INSTALL_NAME_BASE = \"@rpath\"; GENERATE_INFOPLIST_FILE = YES; INSTALL_PATH = \"$(LOCAL_LIBRARY_DIR)/Frameworks\"; LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@executable_path/../Frameworks\", \"@loader_path/Frameworks\",); MARKETING_VERSION = 0.1.0; PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID}.lib; PRODUCT_NAME = \"$(TARGET_NAME:c99extidentifier)\"; SKIP_INSTALL = YES; SWIFT_EMIT_LOC_STRINGS = NO;}}; name = Release; }};")
    add(f"\t\t{debug_test} /* Debug */ = {{isa = XCBuildConfiguration; buildSettings = {{CODE_SIGN_IDENTITY = \"-\"; GENERATE_INFOPLIST_FILE = YES; LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@loader_path/../Frameworks\", \"@executable_path/../Frameworks\",); PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID}.tests; PRODUCT_NAME = \"$(TARGET_NAME)\"; SWIFT_EMIT_LOC_STRINGS = NO;}}; name = Debug; }};")
    add(f"\t\t{release_test} /* Release */ = {{isa = XCBuildConfiguration; buildSettings = {{CODE_SIGN_IDENTITY = \"-\"; GENERATE_INFOPLIST_FILE = YES; LD_RUNPATH_SEARCH_PATHS = (\"$(inherited)\", \"@loader_path/../Frameworks\", \"@executable_path/../Frameworks\",); PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID}.tests; PRODUCT_NAME = \"$(TARGET_NAME)\"; SWIFT_EMIT_LOC_STRINGS = NO;}}; name = Release; }};")
    add("/* End XCBuildConfiguration section */")
    add("")
    add("/* Begin XCConfigurationList section */")
    add(f"\t\t{project_config_list} = {{isa = XCConfigurationList; buildConfigurations = ({debug_proj} /* Debug */, {release_proj} /* Release */,); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")
    add(f"\t\t{app_config_list} = {{isa = XCConfigurationList; buildConfigurations = ({debug_app} /* Debug */, {release_app} /* Release */,); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")
    add(f"\t\t{lib_config_list} = {{isa = XCConfigurationList; buildConfigurations = ({debug_lib} /* Debug */, {release_lib} /* Release */,); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")
    add(f"\t\t{test_config_list} = {{isa = XCConfigurationList; buildConfigurations = ({debug_test} /* Debug */, {release_test} /* Release */,); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};")
    add("/* End XCConfigurationList section */")
    add("\t};")
    add(f"\trootObject = {project_id};")
    add("}")

    out_dir = ROOT / "HSMacOSTracker.xcodeproj"
    out_dir.mkdir(exist_ok=True)
    (out_dir / "project.pbxproj").write_text("\n".join(lines) + "\n")
    print(f"Wrote {out_dir / 'project.pbxproj'}")


if __name__ == "__main__":
    main()
