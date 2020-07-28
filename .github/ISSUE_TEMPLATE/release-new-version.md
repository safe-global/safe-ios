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
/path/to/pods/directory/FirebaseCrashlytics/upload-symbols -gsp /path/to/GoogleService-Info.plist -p ios /path/to/dSYMs
```
- [ ] After release, the build is tagged
```
git tag -am x.y.z "x.y.z" && git push --tags
```
