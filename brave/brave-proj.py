#!/usr/bin/env python
# This is the insanity that is required to modify the project to our needs
# Modifies the original project and writes a new one called Brave.xcodeproj
import sys
import os

sys.path.insert(0, os.path.abspath('./build-system'))

proj_file = '../Client.xcodeproj/project.pbxproj'
tmp_proj_file = '/tmp/project.pbxproj'

try:
    os.remove(proj_file)
except:
    pass

# use backslash to unalias cp
os.system('\\cp -f ../Client.xcodeproj.tgz /tmp; cd /tmp; tar xzf Client*tgz; cd -; ' +
          'rsync -ar /tmp/Client.xcodeproj/* ../Client.xcodeproj')

fabric_keys = ''
try:
    key_path = os.path.expanduser('~/.brave-fabric-keys')
    with open(key_path) as f:
      fabric_keys = [x.strip() for x in f.readlines()]
    os.system("sed -e 's/FABRIC_KEY_REMOVED/fabric_keys[0]/' ../Client/Info.plist.template > ../Client/Info.plist")
except:
    print 'no fabric keys'

def modpbxproj():
    from mod_pbxproj import XcodeProject, PBXBuildFile
    project = XcodeProject.Load(proj_file)

    if fabric_keys:
        project.add_run_script(target='Client', script='./Fabric.framework/run ' + fabric_keys[0] + ' ' + fabric_keys[1])

    topgroup = project.get_or_create_group('brave', path='brave')
    group = project.get_or_create_group('src', path='brave/src', parent=topgroup)
    groups = {'brave/src': group}
    project.add_file('brave/Brave.entitlements', parent=topgroup, ignore_unknown_type=True)
    import os
    for root, subfolders, files in os.walk('src'):
        for folder in subfolders:
            g = project.get_or_create_group(folder, path='brave/' + root + '/' + folder, parent=group)
            groups['brave/' + root + '/' + folder] = g
        for file in files:
            if file.endswith('.h') or file.endswith('.js') or file.endswith('.swift') or file.endswith('.m') or file.endswith('.mm'):
                p = groups['brave/' + root]
                if 'test' in root:
                    # add only to the test target
                    project.add_file(file, parent=p, tree="<group>", target='ClientTests', ignore_unknown_type=True)
                    continue

                build_files = project.add_file(file, parent=p, tree="<group>", target='Client', ignore_unknown_type=True)

                # This is the (crappy) method of listing files that aren't added to ClientTests
                filename_substrings_not_for_clienttest = ['Setting.swift']
                if 'frontend' in root or 'page-hooks' in root or file.endswith('.js') or any(substring in file for substring in filename_substrings_not_for_clienttest):
                    continue

                # from here on, add file to test target (this is in addition to the Client target)
                def add_build_file_to_target(file, target_name):
                    target = project.get_target_by_name(target_name)
                    phases = target.get('buildPhases')
                    # phases = project.get_build_phases('PBXSourcesBuildPhase')
                    find = phases[0]
                    result = [p for p in project.objects.values() if p.id == find]
                    list = result[0].data['files']
                    list.data.append(file.id)

                for b in build_files:
                    if b['isa'] == 'PBXBuildFile':
                        add_build_file_to_target(b, 'ClientTests')

    target_config_list = project.get_target_by_name('ClientTests').get('buildConfigurationList')
    configs = project.objects.data[target_config_list].data['buildConfigurations'].data
    for config_id in configs:
        config = project.objects.data[config_id]
        settings = config.data['buildSettings'].data
        settings['OTHER_SWIFT_FLAGS'] = '-D TEST -D BRAVE -D DEBUG'

    group = project.get_or_create_group('abp-filter-parser-cpp', path='brave/node_modules/abp-filter-parser-cpp', parent=topgroup)
    for f in ['ABPFilterParser.h', 'ABPFilterParser.cpp', 'filter.cpp',
              'node_modules/bloom-filter-cpp/BloomFilter.cpp', 'node_modules/bloom-filter-cpp/BloomFilter.h',
              'node_modules/hashset-cpp/hashFn.h', 'node_modules/hashset-cpp/HashItem.h',
              'node_modules/hashset-cpp/HashSet.h', 'node_modules/hashset-cpp/HashSet.cpp',
              'cosmeticFilter.h', 'cosmeticFilter.cpp']:
        project.add_file(f, parent=group, tree="<group>", target='Client', ignore_unknown_type=True)

    group = project.get_or_create_group('tracking-protection', path='brave/node_modules/tracking-protection', parent=topgroup)
    for f in ['FirstPartyHost.h', 'TPParser.h', 'TPParser.cpp']:
        project.add_file(f, parent=group, tree="<group>", target='Client', ignore_unknown_type=True)


    arr = project.root_group.data['children'].data
    arr.insert(0, arr.pop())

    project.add_file('Fabric.framework', target='Client')
    project.add_file('Crashlytics.framework', target='Client')

    configs = [p for p in project.objects.values() if p.get('isa') == 'XCBuildConfiguration']
    for i in configs:
        build_settings = i.data['buildSettings']
        if 'PRODUCT_BUNDLE_IDENTIFIER' in build_settings:
            if 'PRODUCT_NAME' in build_settings and 'Client' in build_settings['PRODUCT_NAME']:
                build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.brave.ios.browser'
            else:
                build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.brave.ios.browser.$(PRODUCT_NAME)'
        elif 'INFOPLIST_FILE' in build_settings:
            build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.brave.ios.browser.$(PRODUCT_NAME)'
    project.save()

# Do manual removal/replacement in cases where it is easy to do without mod_pbxproj
removals = ['MOZ_PRODUCT_NAME',
            'MOZ_BUNDLE_DISPLAY_NAME',
            'PROVISIONING_PROFILE',
            'OTHER_SWIFT_FLAGS',
            'entitlements',
            'FRAMEWORK_SEARCH_PATHS = ""']

pbxHeaderSection =[] # save this and restore it later
pbxHeaderSection_parsing = False
infile = open(proj_file, 'r')
outfile = open(tmp_proj_file, 'w')
line = infile.readline()
while line:
    if 'PBXHeadersBuildPhase section' in line:
        pbxHeaderSection_parsing = not pbxHeaderSection_parsing

    if pbxHeaderSection_parsing:
        pbxHeaderSection.append(line)

    if '/* Embed App Extensions */' in line:
        # TODO use mod_pbxproj for this
        # There are 2 entries for embed app extensions. The first is one-line, so skip writing it out.
        # The 2nd is a multi-line block bounded by '= {' and '};'
        if '= {' in line:
            while line:
                line = infile.readline()
                if '};' in line:
                    break
    elif 'SystemCapabilities = {' in line:
        outfile.write(' DevelopmentTeam = KL8N8XSYF4;\n')
        outfile.write(line)
    elif 'CODE_SIGN_ENTITLEMENTS' in line:
        outfile.write(' CODE_SIGN_ENTITLEMENTS = brave/Brave.entitlements;\n')
    elif 'Breakpad.framework' in line and not line.rstrip().endswith('= {'):
        pass
    elif not any(substring in line for substring in removals):
        outfile.write(line)

    line = infile.readline()

infile.close()
outfile.close()
from shutil import move
move(tmp_proj_file, proj_file)

modpbxproj()

## put back missing section due to bug
def put_back_missing_section(missingSection):
    infile = open(proj_file, 'r')
    outfile = open(tmp_proj_file, 'w')
    line = infile.readline()
    while line:
        # pick an arbitrary safe spot in the file
        if 'Begin PBXBuildFile section' in line and missingSection != None:
            for i in missingSection:
                outfile.write(i)
            missingSection = None
        outfile.write(line)
        line = infile.readline()

    infile.close()
    outfile.close()
    move(tmp_proj_file, proj_file)

put_back_missing_section(pbxHeaderSection)

###
def create_build_num_increment_step():
    build_num_increment = """
          <PreActions>
         <ExecutionAction
            ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
            <ActionContent
               title = "Run Script"
               scriptText = "conf=${CONFIGURATION}&#10;if [ $conf == &quot;Firefox&quot; ]&#10;then&#10;say &apos;Build pre-action: incrementing build number&apos; &amp;&#10;echo GENERATED_BUILD_ID=`date +&quot;%y.%m.%d.%H&quot;` &gt; ${PROJECT_DIR}/Client/Configuration/build-id.xcconfig&#10;fi">
            </ActionContent>
         </ExecutionAction>
      </PreActions>
    """

    scheme_file = '../Client.xcodeproj/xcshareddata/xcschemes/Firefox.xcscheme'
    tmp_file = '/tmp/tmp.xcscheme'
    infile = open(scheme_file, 'r')
    outfile = open(tmp_file, 'w')
    line = infile.readline()
    while line:
        if 'BuildActionEntries' in line and build_num_increment:
            outfile.write(build_num_increment)
            build_num_increment = None
        outfile.write(line)
        line = infile.readline()
    move(tmp_file, scheme_file)

create_build_num_increment_step()

os.system('\\cp -f build-system/Brave.xcscheme ../Client.xcodeproj/xcshareddata/xcschemes')


