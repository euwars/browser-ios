[[ -e setup.sh  ]] || { echo 'setup.sh must be run from brave directory'; exit 1; }
npm install
(cd node_modules/abp-filter-parser-cpp && build/Release/sample)

#output a placeholder id, Archive builds will generate a real build id
echo GENERATED_BUILD_ID=1  > ../Client/Configuration/build-id.xcconfig

#create the xcode project
python brave-proj.py

echo "If files are added/removed from the project, regenerate it with ./brave-proj.py"

