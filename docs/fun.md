## Functional View

The app, yet simple, has more than one function. You can interpret diagrams below as a survey of the features.

```mermaid
graph
    Assets
    Transactions
    Safe
    Other
```

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
