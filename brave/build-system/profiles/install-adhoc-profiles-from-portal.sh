rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*
rm adhoc/*.mobileprovision*

USER=
PASS=
[[ -n $1 ]] && [[ -n $2 ]] && USER=" -u $1 " && PASS=" -p $2 " && echo "User and Pass specified"

[[ -e ~/.brave-apple-login ]] && source ~/.brave-apple-login

(cd adhoc && /usr/local/bin/ios profiles:download:all --team 9Y996D6DTQ --type distribution $USER $PASS)

for f in `ls adhoc/*.mobileprovision`
do
 echo "Processing $f"
 UUID=`/usr/libexec/PlistBuddy -c 'Print :UUID' /dev/stdin <<< $(security cms -D -i ${f})`
 cp ${f} ~/Library/MobileDevice/Provisioning\ Profiles/${UUID}.mobileprovision
done

###(cd adhoc && sh checkdevices.sh)
