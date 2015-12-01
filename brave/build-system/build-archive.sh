(cd -- "$(dirname -- "$0")" && cd ../.. && \
 xcodebuild archive -scheme Brave CODE_SIGN_IDENTITY="iPhone Distribution: Brave Software, Inc. (KL8N8XSYF4)")
