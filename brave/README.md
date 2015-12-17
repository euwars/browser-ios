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

Do not use 'Xcode managed profiles', there is no advantage to this, and debugging problems with that system is a dead end due to lack of transparency in that system. 

```brave/build-system/profiles``` has some handy scripts to download the adhoc or developer profiles and install them.

## JS Tips

For anyone working with JS in iOS native, I recommend running and debugging your JS in an attached JS console. (Not using an edit/compile/debug cycle in Xcode). When you run from Xcode any iOS web view in the simulator (or attached device), you can then attach from Safari desktop (the Develop menu), and you get a JS console to work in. 

We have various JS interpreters available: UIWebView, JavaScriptCore, and WKWebView.

The first is required if we are running JS on the web page, since we are using UIWebView. JavaScriptCore is a stand-alone JS engine that I believe is more up-to-date than UIWebView's. WKWebView will have the most modern JS engine, but requires instantiating a WKWebView for this purpose, which we would prefer to avoid as that is a heavy approach. UIWebView's JS engine is a few years old, and is quite primitive.

None of these are comparable to Safari iOS's JS engine, which is highly up-to-date in its capabilities but is not available to us.

## Release Builds

```brave/build-system/build-archive.sh``` does everything. When that completes, the Fabric app detects a new archive and asks to distribute to testers.

