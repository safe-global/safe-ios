# Application

This doc explains high-level app design with a structural and functional view. 

## Structural View

```mermaid
---
title: Layer View
---
graph
    UI --> Data
    UI --> Controllers --> Data
    x[Cross-Layer]
```

`UI` implements everything related to interaction with the user: screens, animations, navigation between the screens.

`Controllers` implement processes and business logic functionality of the app, uses `Data` layer's objects.

`Data` implements access to the persistence, secure storage, as well as API models for various remote services. 

### UI

```mermaid
---
title: UI
---
graph
    SceneDelegate --> Window --> ViewController
    Flow --> ViewController --> Data
    ViewController --> View
    Flow --> Data
```

`Flow` implements navigation logic between different screens. It connects `ViewController`s together and passes data around them. 

`ViewController` implements single screen logic using `View`s as components and data provided from outside (usually a `Flow` or another `ViewController`). 

Both `Flow`s and `ViewController`s can use `Data` layer to implement conditional logic in the interface.

### Data
```mermaid
---
title: Data
---
graph
    Data --> Models[Logic Models]
    Data --> CD[Core Data Models]
    Data --> Services
    Services --> CGW[Client Gateway] --> APIModels[API Models]
    Services --> NodeRPC
    Services --> Relay
    Services --> WalletConnect
    Services --> Moonpay    
    Services --> Web3Auth
```

`Data` provides types and APIs to work with them. Much of the application deals with network services.

Persistence implemented with `CoreData` models.

In some areas, the `CoreData` are mirroring or extending the API models to persist that data between app launches. 

### Cross-Layer
```mermaid
---
title: Cross-Layer
---
graph
    Notifs[Notifications / Events]
    Analytics
    Logging
    Configuration
    Errors
```

`Cross-layer` objects implement utilities used throughout other layers. 

`Notification`s are used to post interesting events. `UI` can observe them and reload the data.

`Analytics` includes logging events and non-fatal errors with `Firebase`.

Firebase also provides crash-reporting via `Crashlytics` feature.

`Logging` implements multi-stage logging system.

`Configuration` includes build-time configuration via `.xcconfig` files, `Info.plist` and code-level feature flags. It also includes `Firebase` remote config.

`Errors` implement standard data type for user-facing errors.

## Functional View

```mermaid
---
title: Features
---
graph
    Assets --> Balances
    Assets --> Collectibles
    Transactions --> Queue
    Transactions --> History
    Safe --> Info
    Safe --> List
    Safe --> Settings
```

The app allows to load or create Safe accounts and view their assets and transactions, as well as create and execute new transactions.

```mermaid
---
title: Onchain Actions
---
graph
    SendToken
    
    subgraph SafeAccount
    Safe --> Create
    Safe --> AddOwner
    Safe --> ReplaceOwner
    Safe --> RemoveOwner
    end

    subgraph Multisig
    Transaction --> Confirm
    Transaction --> Rej[Create Rejection]
    Transaction --> Execute
    end

```

The supported transaction functions are in 3 areas: general transaction confirmation functionality, safe-related transactions that change multisig settings, and transactions to send out tokens.

```mermaid
---
title: Features
---
graph
    Settings[App Settings]
    Settings --> Security --> Passcode
    Security --> Biometry
    Settings --> Keys[Owner Keys]
    Settings --> Contacts[Address Book]
    WalletConnect
    Push[Push Notifications]
```

```mermaid
---
title: Features
---
graph
    Token[SAFE Claiming]
    Intercom[Support Chat]
    Help[Help Center]
```

Supporting functionality allows to set up a `Passcode` to restrict access to the app, add `Owner Keys` that would be used to interact with safe accounts and receive `Push Notifications` about Safe transactions.

`Address Book` allows for better readability of transaction data in the interface. 

Useres can use `Chat with us` feature implemented via Intercom to talk with a human.

```mermaid
---
title: WalletConnect Actions
---
graph
    subgraph Dapp
    DappConnection --> ApproveDC[Approve]
    DappConnection --> RejectDC[Reject]
    DappConnection --> Disconnect
    DappTransaction --> Approve[Approve = Create Safe Transaction]
    DappTransaction --> Reject[Reject]
    end
    
    subgraph WalletApp[Wallet / Owner Key]
    Wallet --> Connect
    Wallet --> DisconnectW[Disconnect]
    SafeTransaction --> Send
    Message --> Sign
    end
```

`WalletConnect` is used to receive incoming transaction requests from the external apps (browser or native dapps).
It is also used to connect to the external wallets in order to access functions of private keys there: sign a message or send a transaction.
