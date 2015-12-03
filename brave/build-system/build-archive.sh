[[ `which ios` ]] || gem install cupertino
(cd profiles && sh install-adhoc-profiles-from-portal.sh $1 $2) || exit 1 
(cd -- "$(dirname -- "$0")" && cd ../.. && \
 xcodebuild archive -scheme Brave CODE_SIGN_IDENTITY="iPhone Distribution: Brave Software, Inc. (KL8N8XSYF4)")
