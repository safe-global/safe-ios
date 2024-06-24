# Build Process

## Build Configurations

The project is configured to create 3 different variations of the app:
* Development - the app that can be run on the developer's simulator or a development device, it's using the staging environment.
* Staging - the app that is available in TestFlight and that is using the staging backend environment.
* Production - the app that is available in TestFlight and that is using the production backend environment.

## Continuous Integration

The CI pipelines are configured in the `Jenkinsfile`. 

There are 2 kinds of builds: a test build and archive build.

### Test Build

The test build runs all of the Unit Tests using the Staging environment. 
The build is triggerred for every pull request push event.
The script for this build is in the `bin/test.sh`.
During the unit test, the coverage report is collected and uploaded to the codecov.io tool's website.

### Archive Build

The archive build produces the app in Staging and Production configurations and uploads them to the TestFlight (App Store). 
The archive build runs when a pull request is merged to the `main` or `release/*` branch.
The script for this build is in the `bin/archive.sh`.
