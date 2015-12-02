rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

(cd adhoc && ios profiles:download:all --team 9Y996D6DTQ --type distribution)

for f in `ls adhoc/*.mobileprovision`
do
 echo "Processing $f"
 UUID=`/usr/libexec/PlistBuddy -c 'Print :UUID' /dev/stdin <<< $(security cms -D -i ${f})`
 cp ${f} ~/Library/MobileDevice/Provisioning\ Profiles/${UUID}.mobileprovision
done

(cd adhoc && sh checkdevices.sh)
