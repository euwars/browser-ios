[[ -e setup.sh  ]] || { echo 'setup.sh must be run from brave directory'; exit 1; }
npm install
(cd node_modules/abp-filter-parser-cpp && build/Release/sample)

mkdir -p github_modules

github_dir_and_remote () {
  [[ -e $1 ]] || git clone https://github.com/$2
  (cd $1 && git pull)
}

(
 cd github_modules
 github_dir_and_remote RNCachingURLProtocol rnapier/RNCachingURLProtocol.git
)

#output a placeholder id, Archive builds will generate a real build id
echo GENERATED_BUILD_ID=1  > ../Client/Configuration/build-id.xcconfig
