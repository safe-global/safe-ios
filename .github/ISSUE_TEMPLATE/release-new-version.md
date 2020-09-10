
- [ ] Create a release task in GitHub using the “New Release” template.
- [ ] Create and push the release branch
```
git checkout main -b release/X.Y.Z
git push -u origin release/X.Y.Z
```
- [ ] Marketing version is updated (x.y.z) 
```
agvtool new-marketing-version x.y.z
```
- [ ] Notify QA
- [ ] QA approved release candidate build
- [ ] Product Owner approved submission

**AFTER PRODUCT OWNER APPROVAL**

- [ ] Submit to the App Store Review with developer approval for distribution
- [ ] Notify the team that release was submitted using the template below:
```
@here Hi everyone! We have submitted new iOS app vX.Y.Z for review to the App Store.
```
- [ ] Create a new release in GitHub with release notes. This will create a tag. The tag should be in a format vX.Y.Z
- [ ] dSYMs are downloaded from AppStoreConnect and uploaded to Firebase Crashlytics.
```
# For the Multisig Production Rinkeby app:
> Pods/FirebaseCrashlytics/upload-symbols \
  -gsp Multisig/Cross-layer/Analytics/Firebase/GoogleService-Info.Production.Rinkeby.plist \
  -p ios /path/to/dSYMs
 
# For the Multisig app (App Store version):
> Pods/FirebaseCrashlytics/upload-symbols \
  -gsp Multisig/Cross-layer/Analytics/Firebase/GoogleService-Info.Production.Mainnet.plist \
  -p ios /path/to/dSYMs
```
- [ ] Release the app when it is approved by the App Store Review team (do not release on Thu/Fri). Notify the team using the following template:
```
@here Hi everyone! We have released the iOS app vX.Y.Z to the App Store and it will soon be available for download.
```
- [ ]  Merge the release branch to master branch via new pull-request
