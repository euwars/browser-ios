# Brave iOS Browser 

## Setup

Do firefox setup by running checkout.sh

Run setup in brave/ (this dir)
```
./setup.sh
```

Open Client.xcodeproj

build ClientNoTests


## Provisioning Profiles

For the first time, I am using "Xcode managed profiles" (Apple now recommends this).
However, adding a new tester's device is buggy. After adding a device UDID in ADC, Xcode managed profiles aren't getting the new device.

Remove old embedded.mobileprovision
```
cd ~/Library/Developer
find . -name embedded.mobileprovision | sed 's/.*/"&"/g' | xargs rm
```

Remove ADC account from Xcode>Preferences>Accounts. Quit and restart. Re-add account, and click to download all profiles.

Verify UDID has arrived:
```
find  ~/Library/Developer -name embedded.mobileprovision | sed 's/.*/"&"/g' | xargs grep <a few chars of new UDID>
```
