"""Generate a deterministic native Xcode project with no package dependencies."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / 'apps/ios'

def identifier(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()

def generate():
    objects = []
    def obj(name, body):
        key = identifier(name)
        objects.append(f'\t\t{key} = {{ {body} }};')
        return key
    def refs(values):
        return '(' + ', '.join(values) + ',)'
    def q(value):
        return json.dumps(value)
    sources = []
    source_files = []
    for path in sorted((ROOT / 'QuickSleep').rglob('*.swift')):
        relative = path.relative_to(ROOT).as_posix()
        ref = obj(relative, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q(relative)}; sourceTree = SOURCE_ROOT;')
        source_files.append(ref)
        sources.append(obj('build:' + relative, f'isa = PBXBuildFile; fileRef = {ref};'))
    asset = obj('assets', 'isa = PBXFileReference; lastKnownFileType = folder; path = QuickSleep/Resources/assets; sourceTree = SOURCE_ROOT;')
    privacy = obj('privacy', 'isa = PBXFileReference; lastKnownFileType = text.xml; path = QuickSleep/PrivacyInfo.xcprivacy; sourceTree = SOURCE_ROOT;')
    locales = []
    for language in ['en', 'zh']:
        locales.append(obj('locale:' + language, f'isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = {language}; path = QuickSleep/Resources/{language}.lproj/Localizable.strings; sourceTree = SOURCE_ROOT;'))
    strings = obj('strings', f'isa = PBXVariantGroup; children = {refs(locales)}; name = Localizable.strings; sourceTree = "<group>";')
    resources = [obj('build:' + name, f'isa = PBXBuildFile; fileRef = {ref};') for name, ref in [('assets', asset), ('privacy', privacy), ('strings', strings)]]
    source_phase = obj('sourcePhase', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {refs(sources)}; runOnlyForDeploymentPostprocessing = 0;')
    resource_phase = obj('resourcePhase', f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = {refs(resources)}; runOnlyForDeploymentPostprocessing = 0;')
    framework_phase = obj('frameworkPhase', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
    app = obj('app', 'isa = PBXFileReference; explicitFileType = wrapper.application; path = QuickSleep.app; sourceTree = BUILT_PRODUCTS_DIR;')
    product_group = obj('products', f'isa = PBXGroup; children = {refs([app])}; name = Products; sourceTree = "<group>";')
    source_group = obj('sourceGroup', f'isa = PBXGroup; children = {refs(source_files)}; name = Sources; sourceTree = "<group>";')
    resource_group = obj('resourceGroup', f'isa = PBXGroup; children = {refs([asset, strings, privacy])}; name = Resources; sourceTree = "<group>";')
    main = obj('mainGroup', f'isa = PBXGroup; children = {refs([source_group, resource_group, product_group])}; sourceTree = "<group>";')
    project_configs = []
    target_configs = []
    for name in ['Debug', 'Release']:
        debug = name == 'Debug'
        project_configs.append(obj('project:' + name, f'isa = XCBuildConfiguration; name = {name}; buildSettings = {{ CLANG_ENABLE_MODULES = YES; IPHONEOS_DEPLOYMENT_TARGET = 16.0; SDKROOT = iphoneos; SWIFT_VERSION = 5.0; }};'))
        settings = {
            'PRODUCT_BUNDLE_IDENTIFIER': 'com.qiyanzhixing.quicksleep', 'PRODUCT_NAME': '$(TARGET_NAME)',
            'INFOPLIST_FILE': 'QuickSleep/Info.plist', 'GENERATE_INFOPLIST_FILE': 'NO',
            'TARGETED_DEVICE_FAMILY': '1,2', 'SUPPORTED_PLATFORMS': 'iphoneos iphonesimulator',
            'CODE_SIGN_STYLE': 'Automatic', 'SWIFT_VERSION': '5.0', 'IPHONEOS_DEPLOYMENT_TARGET': '16.0',
            'SWIFT_OPTIMIZATION_LEVEL': '-Onone' if debug else '-O', 'ENABLE_USER_SCRIPT_SANDBOXING': 'YES',
            'DEBUG_INFORMATION_FORMAT': 'dwarf' if debug else 'dwarf-with-dsym',
            'SWIFT_ACTIVE_COMPILATION_CONDITIONS': 'DEBUG' if debug else '',
        }
        target_configs.append(obj('target:' + name, f'isa = XCBuildConfiguration; name = {name}; buildSettings = {{ ' + ' '.join(f'{key} = {q(value)};' for key, value in settings.items()) + ' };'))
    project_list = obj('projectList', f'isa = XCConfigurationList; buildConfigurations = {refs(project_configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
    target_list = obj('targetList', f'isa = XCConfigurationList; buildConfigurations = {refs(target_configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
    target = obj('target', f'isa = PBXNativeTarget; name = QuickSleep; productName = QuickSleep; productType = "com.apple.product-type.application"; productReference = {app}; buildConfigurationList = {target_list}; buildPhases = {refs([source_phase, framework_phase, resource_phase])}; dependencies = (); buildRules = ();')
    project = obj('project', f'isa = PBXProject; attributes = {{ LastUpgradeCheck = 1600; }}; buildConfigurationList = {project_list}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; knownRegions = (en, zh, Base); mainGroup = {main}; productRefGroup = {product_group}; projectDirPath = ""; projectRoot = ""; targets = {refs([target])};')
    directory = ROOT / 'QuickSleep.xcodeproj'
    directory.mkdir(exist_ok=True)
    (directory / 'project.pbxproj').write_text('// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n' + '\n'.join(objects) + f'\n\t}};\n\trootObject = {project};\n}}\n', encoding='utf-8')
    scheme = directory / 'xcshareddata/xcschemes'
    scheme.mkdir(parents=True, exist_ok=True)
    (scheme / 'QuickSleep.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="QuickSleep.app" BlueprintName="QuickSleep" ReferencedContainer="container:QuickSleep.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"/>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="QuickSleep.app" BlueprintName="QuickSleep" ReferencedContainer="container:QuickSleep.xcodeproj"/></BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"/>
<AnalyzeAction buildConfiguration="Debug"/>
<ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''', encoding='utf-8')
    print(f'Generated native Xcode project: {directory}')

if __name__ == '__main__':
    generate()
