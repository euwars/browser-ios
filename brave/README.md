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

These are in brave/provisioning-profiles. Do not use 'Xcode managed profiles', there is no advantage to this, and debugging problems with that system is a dead end due to lack of transparency in that system. 
brave/provisioning-profiles has some handy scripts:
* setup-profile.sh: copies the profiles to the correct directory in ~Library so that Xcode will find them. Also, *deletes* all other profiles to prevent conflicts.
* checkdevices.sh: verifies the UDIDS in devices.txt are in all the profiles. In terms of workflow, do the following in the Apple Dev portal: 1) add test user devices, 2) add the devices to the Ad Hoc provisioning profile and download the 4 Ad Hoc profiles (broswer and 3 extension profiles), 3) copy the device list off the portal and update devices.txt. Finally, run checkdevices.sh.


