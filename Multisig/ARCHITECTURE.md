# Guide to the app architecture

The app, logically, has a layered architecture:
- Presentation Layer - user interface implementation.
- Busines Logic Layer - domain model and logic of the application.
- Data Layer - access to the local data store and to the server services.
- Cross-cutting Layer - modules that are relevant for all the layers above.

The folder structure replicates the layers, however, the meat of the application is inside
the [Containers](Containers/ABOUT.md) folder, while layer folders hold modules 
common to all containers.
