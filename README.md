# ForgeRock Authenticator for iOS

The ForgeRock Authenticator provides a secure method for users to access their
accounts managed by ForgeRock's OpenAM.
This works in combination with OpenAM's "ForgeRock Authenticator (OATH)" and
"ForgeRock Authenticator (Push)" authentication modules.

## Getting Started

* Download the project's code (`git clone ...`)
* Download dependencies defined in the [CocoaPods](https://cocoapods.org/) [Podfile](Podfile) - You'll need to [install CocoaPods](https://guides.cocoapods.org/using/getting-started.html) and run the command `pod install`
* Open the project in Xcode (`open ForgeRock.xcworkspace/`)

Check Confluence for [further information relating to this project](https://wikis.forgerock.org/confluence/display/openam/ForgeRock+Authenticator+Apps).

## CocoaPods

As implied in the Getting Started instructions above, this project uses CocoaPods
for managing 3rd party dependencies. Further details regarding CocoaPods can be
found [online](https://guides.cocoapods.org).

After adding new dependencies to the [Podfile](Podfile), run `pod install` to
download the dependency and capture its version in the [Podfile.lock](Podfile.lock)
file. The [Podfile.lock](Podfile.lock) file ensures that running `pod install`
again will download the same versions.

Updating to a newer version of a dependency can be achieved by using a combination
of `pod outdated` to identify dependencies that are outdated and `pod update` to
update them. See [CocoaPods install vs update documentation](https://guides.cocoapods.org/using/pod-install-vs-update.html)
for further details.

When adding, removing or updating 3rd party dependencies, be sure to update the
[LIBRARIES](LIBRARIES) file.

## Typhoon

We use [Typhoon](http://typhoonframework.org/) for dependency injection.

Dependencies are defined in [FRAApplicationAssembly.h](ForgeRock-Authenticator/FRAApplicationAssembly.h).
