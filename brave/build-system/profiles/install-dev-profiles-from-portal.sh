rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*
rm /tmp/*.mobileprovision*

USER=
PASS=
[[ -n $1 ]] && [[ -n $2 ]] && USER=" -u $1 " && PASS=" -p $2 " && echo "User and Pass specified"

(cd /tmp && /usr/local/bin/ios profiles:download:all --team 9Y996D6DTQ --type development $USER $PASS)
# Since we are on a dev machine just use xcode to install these
open /tmp/*.mobileprovision
