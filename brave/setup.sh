[[ -e setup.sh  ]] || { echo 'setup.sh must be run from brave directory'; exit 1; }
npm install
(cd node_modules/abp-filter-parser-cpp && build/Release/sample)
