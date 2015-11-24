# Replace the removed xcconfigs with ours
(cd ../Client && ln -sfn ../brave/xcconfig Configuration)

[[ -e setup.sh  ]] || { echo 'setup.sh must be run from brave directory'; exit 1; }
npm update
(cd node_modules/abp-filter-parser-cpp && build/Release/sample)

#output a placeholder id, Archive builds will generate a real build id
echo GENERATED_BUILD_ID=1  > xcconfig/build-id.xcconfig
## cp xcconfig/build-id.xcconfig ../Client/Configuration

#create the xcode project
python brave-proj.py > /dev/null 2>&1

echo ""
echo "If files are added/removed from the project, regenerate it with ./brave-proj.py"
echo "Consider adding the post-checkout script for git automation (instructions are in that file)"
