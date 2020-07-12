#  Release
*This file assumes that you have access to the CocoaPods Trunk where RxFireAuth is normally published. You may need to tweak a few settings, if you're trying to publish your own version of the library on another destination. Keep in mind that contributions to the project are always welcome: instead of publishing your own version, you may be better off making a PR and discuss your changes.*

To release a new version of RxFireAuth, follow these steps:

## Prerequisites
- RxFireAuth follows [git-flow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow). You should initiate a release only from a `hotfix/*` or `release/*` branch.
- [CocoaPods](https://cocoapods.org) must be installed and available in your `$PATH`.
- If you made any changes to the documentation, you'll need [Jazzy](https://github.com/realm/jazzy).
- Make sure that the `RxFireAuth-Example` target in `Example/RxFireAuth.xcworkspace` builds and runs.

## Steps
- Open `RxFireAuth.podspec` and increase the version. RxFireAuth follows [Semantic Versioning](https://semver.org).
- If you made any change that affects the documentation, run the following command in a Terminal in the RxFireAuth root folder:

```bash
jazzy --podspec RxFireAuth.podspec --clean
```
- To make sure that everything works, run the following command in the same folder:

```bash
pod lib lint
```

- If the previous command ran successfully, you're now ready to push a new release: commit all your changes, push them and finish the `hotfix` or `release` branch using a git-flow compatible client. Some clients let you tag a release/hotfix immediately: make sure to follow the naming convention when creating your tag (i.e. `v1.5.0`).
- Push all branches (you may have commits to push on either `develop` and `master` or both).
- If you haven't tagged the release already, use your favorite git client (GitHub can do this as well) to add a tag *(not a GitHub release - see above for the tags naming convention)*.
- Back in a Terminal in the RxFireAuth root folder, run the following command:

```bash
pod trunk push RxFireAuth.podspec
```

- Once the library has been published successfully, go back to GitHub and [create a new release](https://github.com/MrAsterisco/RxFireAuth/releases/new).
- Insert the tag name and the version name (which is exactly the version number, without the initial "v").
- Detail the changes using three categories: "Added", "Improved" and "Fixed". *When referencing bugs, make sure to include a link to the GitHub issue*.
- Once ready, publish the release.
