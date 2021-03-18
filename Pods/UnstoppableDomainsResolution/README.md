# UnstoppableDomainsResolution

[![Get help on Discord](https://img.shields.io/badge/Get%20help%20on-Discord-blueviolet)](https://discord.gg/b6ZVxSZ9Hn)
[![Unstoppable Domains Documentation](https://img.shields.io/badge/Documentation-unstoppabledomains.com-blue)](https://docs.unstoppabledomains.com/)

Resolution is a library for interacting with blockchain domain names. It can be used to retrieve [payment addresses](https://unstoppabledomains.com/features#Add-Crypto-Addresses), IPFS hashes for [decentralized websites](https://unstoppabledomains.com/features#Build-Website), and GunDB usernames for [decentralized chat](https://unstoppabledomains.com/chat).

Resolution is primarily built and maintained by [Unstoppable Domains](https://unstoppabledomains.com/).

Resoultion supports decentralized domains across three main zones:

- Crypto Name Service (CNS)
  - `.crypto`
- Zilliqa Name Service (ZNS)
  - `.zil`
- Ethereum Name Service (ENS)
  - `.eth`
  - `.kred`
  - `.xyz`
  - `.luxe`

# Installation into the project

## Cocoa Pods

```ruby
pod 'UnstoppableDomainsResolution', '~> 0.3.0'
```

## Swift Package Manager

```swift
package.dependencies.append(
    .package(url: "https://github.com/unstoppabledomains/resolution-swift", from: "0.3.0")
)
```

# Usage

 - Create an instance of the Resolution class
 - Call any method of the Resolution class asyncronously

> NOTE: make sure an instance of the Resolution class is not deallocated until the asyncronous call brings in the result. Your code is the **only owner** of the instance so keep it as long as you need it.

# Common examples

> NOTE as of 26 November 2020: since the service at https://main-rpc.linkpool.io seems to be unstable it is highly recommended that you instantiate the Resolution instance with an Infura URL, like shown below.

```swift
import UnstoppableDomainsResolution

guard let resolution = try? Resolution() else {
  print ("Init of Resolution instance with default parameters failed...")
  return
}

// Or, if you want to use a specific providerUrl and network:
guard let resolution = try? Resolution(providerUrl: "https://mainnet.infura.io/v3/<YOUR_PROJECT_ID_HERE>", network: "mainnet") else {
  print ("Init of Resolution instance with custom parameters failed...")
  return
}

resolution.addr(domain: "brad.crypto", ticker: "btc") { result in
  switch result {
  case .success(let returnValue):
    // bc1q359khn0phg58xgezyqsuuaha28zkwx047c0c3y
    let btcAddress = returnValue
  case .failure(let error):
    print("Expected btc Address, but got \(error)")
}
}

resolution.addr(domain: "brad.crypto", ticker: "eth") { result in
  switch result {
  case .success(let returnValue):
    // 0x8aaD44321A86b170879d7A244c1e8d360c99DdA8
    let ethAddress = returnValue
  case .failure(let error):
    print("Expected eth Address, but got \(error)")
  }
}

resolution.multiChainAddress(domain: "brad.crypto", ticker: "USDT", chain: "ERC20") { result in
  switch result {
  case .success(let returnValue):
    // 0x8aaD44321A86b170879d7A244c1e8d360c99DdA8
    let usdtErc20Address = returnValue
  case .failure(let error):
    print("Expected eth Address, but got \(error)")
  }
}

resolution.multiChainAddress(domain: "brad.crypto", ticker: "USDT", chain: "OMNI") { result in
  switch result {
  case .success(let returnValue):
    // 1FoWyxwPXuj4C6abqwhjDWdz6D4PZgYRjA
    let usdtOmniAddress = returnValue
  case .failure(let error):
    print("Expected Omni Address, but got \(error)")
  }
}

resolution.owner(domain: "brad.crypto") { result in
  switch result {
  case .success(let returnValue):
    // 0x8aaD44321A86b170879d7A244c1e8d360c99DdA8
    let domainOwner = returnValue
  case .failure(let error):
    XCTFail("Expected owner, but got \(error)")
  }
}
```

## Customizing naming services
Version 0.3.0 introduced the `Configurations` struct that is used for configuring each connected naming service.
Library can offer three naming services at the moment:

* `cns` resolves `.crypto` domains,
* `ens` resolves `.eth` domains,
* `zns` resolves `.zil` domains

By default, each of them is using the mainnet network via infura provider. 
Unstoppable domains are using the infura key with no restriction for CNS.
Unstoppable domains recommends setting up your own provider for ENS, as we don't guarantee ENS Infura key availability. 
You can update each naming service separately

```swift
let resolution = try Resolution(configs: Configurations(
        cns: NamingServiceConfig(
            providerUrl: "https://rinkeby.infura.io/v3/3c25f57353234b1b853e9861050f4817",
            network: "rinkeby"
        )
    )
);

// domain udtestdev-creek.crypto exists only on the rinkeby network.

resolution.addr(domain: "udtestdev-creek.crypto", ticker: "eth") { (result) in
    switch result {
    case .success(let returnValue):
        ethAddress = returnValue
        domainReceived.fulfill()
    case .failure(let error):
        XCTFail("Expected Eth Address, but got \(error)")
    }
}

// naming services that hasn't been touched by Configrations struct are using default settings
// the following will look up monkybrain.eth on the mainnet via infura provider

resolution.addr(domain: "monkybrain.eth", ticker: "eth") { (result) in
    switch result {
    case .success(let returnValue):
        ethENSAddress = returnValue
        domainEthReceived.fulfill()
    case .failure(let error):
        XCTFail("Expected Eth Address, but got \(error)")
    }
}
```

## Batch requesting of owners

Version 0.1.3 introduced the `batchOwners(domains: _, completion: _ )` method which adds additional convenience when making multiple domain owner queries.

> This method is only compatible with CNS-based domains. Using this method with any other domain type will throw the error: `ResolutionError.methodNotSupported`.

As opposed to the single `owner(domain: _, completion: _)` method, this batch request will return an array of owners `[String?]`. If the the domain is not registered or its value is `null`, the corresponding array element of the response will be `nil` without throwing an error.
 
```swift 
resolution.batchOwners(domains: ["brad.crypto", "otherbrad.crypto"]) { result in
  switch result {
  case .success(let returnValue):
    // returnValue: [String?] = <array of owners's addresses>
    let domainOwner = returnValue
  case .failure(let error):
    XCTFail("Expected owner, but got \(error)")
  }
}
```

# Networking

> Make sure your app has AppTransportSecurity settings to allow HTTP access to the `https://main-rpc.linkpool.io` domain.

## Custom Networking Layer

By default, this library uses the native iOS networking API to connect to the internet. If you want the library to use your own networking layer instead, you must conform your networking layer to the `NetworkingLayer` protocol. This protocol requires only one method to be implemented: `makeHttpPostRequest(url:, httpMethod:, httpHeaderContentType:, httpBody:, completion:)`. Using this method will bypass the default behavior and delegate the request to your own networking code.

For example, construct the Resolution instance like so:

```swift
guard let resolution = try? Resolution(networking: MyNetworkingApi) else {
  print ("Init of Resolution instance failed...")
  return
}
```

# Possible Errors:

If the domain you are attempting to resolve is not registered or doesn't contain the information you are requesting, this framework will return a `ResolutionError` with the possible causes below. We advise creating customized errors in your app based on the return value of the error.

```
enum ResolutionError: Error {
  case unregisteredDomain
  case unsupportedDomain
  case recordNotFound
  case recordNotSupported
  case unsupportedNetwork
  case unspecifiedResolver
  case unknownError(Error)
  case proxyReaderNonInitialized
  case inconsistenDomainArray
  case methodNotSupported
}
```

# Contributions

Contributions to this library are more than welcome. The easiest way to contribute is through GitHub issues and pull requests.


# Free advertising for integrated apps

Once your app has a working Unstoppable Domains integration, [register it here](https://unstoppabledomains.com/app-submission). Registered apps appear on the Unstoppable Domains [homepage](https://unstoppabledomains.com/) and [Applications](https://unstoppabledomains.com/apps) page — putting your app in front of tens of thousands of potential customers per day.

Also, every week we select a newly-integrated app to feature in the Unstoppable Update newsletter. This newsletter is delivered to straight into the inbox of ~100,000 crypto fanatics — all of whom could be new customers to grow your business.

# Get help
[Join our discord community](https://discord.com/invite/b6ZVxSZ9Hn) and ask questions.  
