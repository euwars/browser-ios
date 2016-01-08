[[ -e setup.sh  ]] || { echo 'setup.sh must be run from brave directory'; exit 1; }

# Replace the removed xcconfigs with ours
(cd ../Client && rm -rf Configuration &&  ln -sfn ../brave/xcconfig Configuration)

npm update

#output a placeholder id, Archive builds will generate a real build id
echo GENERATED_BUILD_ID=1  > xcconfig/build-id.xcconfig
## cp xcconfig/build-id.xcconfig ../Client/Configuration

#create the xcode project
python brave-proj.py 

echo ""
echo "If files are added/removed from the project, regenerate it with ./brave-proj.py"
echo "Consider adding the post-checkout script for git automation (instructions are in that file)"
