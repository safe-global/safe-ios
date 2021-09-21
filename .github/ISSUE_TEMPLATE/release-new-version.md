---
name: Release New Version
about: Release a new version
title: Release x.y.z
labels: infrastructure
assignees: ''
---


- [ ] Create a release task in GitHub using the “New Release” template.
- [ ] Create and push the release branch
```
git checkout main -b release/x.y.z
git push -u origin release/x.y.z
```
- [ ] Marketing version is updated (x.y.z) 
```
agvtool new-marketing-version x.y.z
```
- [ ] Notify QA
- [ ] QA approved release candidate build
- [ ] Product Owner approved submission

**AFTER PRODUCT OWNER APPROVAL**

- [ ] Update screenshots in the App Store
- [ ] Submit to the App Store Review with developer approval for distribution
- [ ] Notify the team that release was submitted using the template below:
```
@here Hi everyone! We have submitted new iOS app vX.Y.Z for review to the App Store.
```
- [ ] Create a new release in GitHub with release notes. This will create a tag. The tag should be in a format vX.Y.Z

#### Download DSYMs manually
- [ ] dSYMs are downloaded from AppStoreConnect and uploaded to Firebase Crashlytics.
``` 
# For the Multisig app (App Store version):
> ./bin/upload-symbols \
  -gsp Multisig/Cross-layer/Analytics/Firebase/GoogleService-Info.Production.plist \
  -p ios /path/to/dSYMs
```
#### Or download DSYMs with the script
- Install fastlane with `gem install fastlane --verbose`
- Set up the `fastlane` directory with configuraiton (ask team member to help). Do not commit the directory to the repository.
- Change the build version and build number in the `fastlane/upload_dsyms.sh` file
- Run the script `sh fastlane/upload_dsyms.sh`

#### Finally
- [ ] Release the app when it is approved by the App Store Review team (do not release on Thu/Fri). Notify the team using the following template:
```
@here Hi everyone! We have released the iOS app vX.Y.Z to the App Store and it will soon be available for download.
```
- [ ]  Merge the release branch to master branch via new pull-request
