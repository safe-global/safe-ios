## Functional View

The app, yet simple, has more than one function. You can interpret diagrams below as a survey of the features.

<img src="UI.001.png" height="300" alt="User interface"/>

```mermaid
graph
    Assets
    Transactions
    Safe
    Settings
    click Assets "#assets"
```
- `Assets` shows a quick view of a safe's balances and relevant actions
- `Transactions` deals with lists of pending and past transactions
- `Dapps` shows current connections to browser apps
- `Settings` shows apps' and safe's settings and is a home to other app features

### Assets
Arrows in represent "contains" relationship

```mermaid
graph LR
    Assets --> a[View Balances and Collectibles]
    Assets --> b[Send Tokens]
    Assets --> c[Show Safes List]
    Assets --> d[Update Token Claiming Settings]
    Assets --> e[Receive: Show Safe Address]
```
Assets area of the app loads safe's balances and is a place where user starts related interface flows.



### Transactions

```mermaid
graph LR
    T[Transactions] --> a[Queue] --> e[Details]
    e --> Sign
    e --> Reject
    e --> Execute
    e --> v[View in browser]
    T --> b[History]
```

Transactions area of the app is the place where user would view and act on the staged transactions or browse past transactions.
- `Queue` lists pending transactions. New transaction requests appear her.
    - `Details` include such information as the type of transaction and help user understand what this transaction is about, in detail.
    - `Sign` action starts wallet flow to authenticate transaction for sending to the blockchain.

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
