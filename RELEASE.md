# Release

To release a new version of RxFireAuth, follow these steps:

## Prerequisites

- RxFireAuth follows [git-flow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow). You should initiate a release only from a `hotfix/*` or `release/*` branch.
- Make sure that all targets in the `RxFireAuth` project under `Example-SwiftPM` build and run correctly.

## Steps

- If you made any change that affects the documentation, run the following command in a Terminal in the RxFireAuth root folder:

```bash
swift package --allow-writing-to-directory docs generate-documentation --target RxFireAuth --disable-indexing --transform-for-static-hosting --hosting-base-path RxFireAuth --output-path docs
```

- Commit all your changes, push them and finish the `hotfix` or `release` branch using a git-flow compatible client. Some clients let you tag a release/hotfix immediately: make sure to follow the naming convention when creating your tag (i.e. `v1.5.0`).
- Push all branches (you may have commits to push on either `develop` and `master` or both).
- If you haven't tagged the release already, use your favorite git client (GitHub can do this as well) to add a tag _(not a GitHub release - see above for the tags naming convention)_.
- Go back to GitHub and [create a new release](https://github.com/MrAsterisco/RxFireAuth/releases/new).
- Insert the tag name and the version name (which is exactly the version number, without the initial "v").
- Detail the changes using three categories: "Added", "Improved" and "Fixed". _When referencing bugs, make sure to include a link to the GitHub issue_.
- Once ready, publish the release.
