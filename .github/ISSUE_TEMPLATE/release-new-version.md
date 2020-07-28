---
name: Release New Version
about: Release a new version
title: Release x.y.z
labels: infrastructure
assignees: ''

---


- [ ] Marketing version is updated (x.y.z) 
```
agvtool new-marketing-version x.y.z
```
- [ ] QA approved release candidate build
- [ ] Product Owner approved submission
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

- [ ] After the submission to the App Store Review, the build is tagged
```
git tag -am x.y.z "x.y.z" && git push --tags
```
