# Containers structure

The idea is that each container is a self-sufficient package that is responsible for a 
certain functionality with strong cohesion. Indeed, each container has modules that are
specialized by the app layer (presentation, business logic, or data)

- `App` - overall app structure
- `Safe Management` - The package is responsible for use cases for managing safes in the app. 
    It includes adding, removing, displaying list of safes, switching the selected safe, 
    and displaying a safe information. Also, it includes displaying of the current safe
    settings and editing safe information (such as safe name).
- `ENS Resolution`  - The package is responsible for the ENS name support: 
    entering and resolving names to addresses, and reverse resolving addresses to names.
