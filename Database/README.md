# Database module
The Database module defines protocols for a simple database access, inspired by standard JDBC interfaces and Enterprise Development Patterns book.

The module also provides SQLite implementation of the given protocols, so this module requires its clinets to link with `sqlite3` library.

Most of the time, you can use `Database.execute(sql:bindings:dict:)` and `Database.execute(sql:bindings:dict:resultMap:)` methods to directly execute SQL requests and avoid dealing with connections, statements and result sets. For more precise control, those objects are available.

All of the protocols are supposed to work in concert. `Database` can be created and destroyed, it can create `Connection`s and close them. Each `Connection` can prepare `Statement`s from SQL command.

`Statement` can bind values of types `String`, `Data`, `Int`, `Double` or `nil` by index (starting at 1), or by key. Of course, a `Statement` can be executed. If `Statement` returns result, then `ResultSet` returned from `Statement.execute()` method.

`ResultSet` represents a cursor of the current row of the result of a `Statement` execution. It can move to the next row, and extract value by 0-based column index.

For unit testing, the module contains `MockDatabase`'s mock implementations.

## SQLite implementation

The module wraps C sqlite3 APIs in one class, `CSQlite3`, which is mocked by `MockCSQlite3`, to allow for unit testing of different cases, such as error codes, different results of execution and so on. 

The main class to work with is `SQLiteDatabase`, which implements `Database` interface using underlying `CSQLite3` methods and `Foundation.FileManager`.

To create a database, initialize it and call `Database.create()` method. After that, you can start executing SQL queries and updates.

NOTE: currently, only one SQL command per execution is supported. Support for multiple, semicolon-separated SQL commands in one `Database.execute(...)` call will be added in future version.

The SQLite database connections are started in multi-threaded mode, that means you can safely use the database from different threads, and it will work. 

The default behavior when multiple threads are accesssing the database is that there can be only one write access to SQLite at a time, all other threads must wait when write operation finishes. 

There could be multiple simultaneous reads. In case a thread must wait for other thread to finish, the database method call will block (wait) until it can be resumed.
