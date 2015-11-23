# Brave iOS Browser 

## Setup

Do firefox setup by running checkout.sh

Run setup in brave/ (this dir)
```
./setup.sh
```

Open Client.xcodeproj

build Client or ClientNoTests

## Updating Code 

After a git pull (i.e. updating from the remote) run

``` ./brave-proj.py ```

The Xcode project is generated, so local changes won't persist. And if files are added/removed after updating, your project won't be in sync unless the above command is run. 

## Tests

Run Product>Test in Xcode to do so. Not all Firefox tests are passing yet.

## Contribution Notes

The main branch is brave-master, the master is Mozilla's master. If this is too confusing I can remove that master, it isn't absolutely necessary for merging.

Most of the code is in the brave/ directory. The primary design goal has been to preserve easy merging from Firefox iOS upstream, so hopefully code changes outside of that dir are minimal.

To find changes outside of brave/, look for #if BRAVE / #if !BRAVE (#if/#else/#endif is supported by Swift)

Swift coding standard is generally compiler inforced, but indentation is not. I made the mistake of having my editor set to 2-space indent, and later realize Mozilla is using 4-space indent, so code in brave/ uses 2-space. Need to decide what to do here, but 2-space seems in vogue.

Obj-C standard should follow https://google.github.io/styleguide/objcguide.xml. I am not a fan of this cuddling: ```NSObject *object```, preferring ```NSObject* object```, but have now realized the futility of this since we are open-sourcing, and nearly all open-source projects use ```NSObject *object`` cuddling. Start using this; at some point I'll switch the existing code to that standard.


## Provisioning Profiles

For the first time, I am using "Xcode managed profiles" (Apple now recommends this).
However, adding a new tester's device is buggy. After adding a device UDID in ADC, Xcode managed profiles aren't getting the new device.

Remove old embedded.mobileprovision
```
cd ~/Library/Developer
find . -name embedded.mobileprovision | sed 's/.*/"&"/g' | xargs rm
```

Remove ADC account from Xcode>Preferences>Accounts. Quit and restart. Re-add account, and click to download all profiles.

Do an Archive build (I seem to have to do this first) and verify UDID has arrived:
```
find  ~/Library/Developer -name embedded.mobileprovision | sed 's/.*/"&"/g' | xargs grep <a few chars of new UDID>
```
