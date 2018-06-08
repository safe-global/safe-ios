# CommonImplementations module
The `CommonImplementations` module hosts implementations of some of the protocols defined in the `Common` module: `Logger` and `SecureStore`. 

The `Logger` protocol is implemented with the `LogService`, which has two types of child loggers: crashlytics and console. You can control which loggers are used by the "SafeLogServiceEnabledLoggersKey" app's info dictionary String value that should contain comma-separated list of enabled logger names. See `LogService.init(bundle:)` for details.

You can also control the log level by another key, "SafeLogServiceLogLevelKey". The allowed values for that string are "off", "fatal", "error", "info" and "debug". The values are case-insensitive.

The `SecureStore` protocol is implemented by the `KeychainService` and can be used to stored arbitrary Data in encrypted form.
