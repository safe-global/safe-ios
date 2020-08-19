# SwiftCryptoTokenFormatter
Formatter for crypto token amounts.

## Rules
- Cut off after the 5th decimal, no matter how many decimals there are: 0.12345
- Remove trailing zeroes, i.e. display 0.10000 as 0.1
- Use the 5 decimals up until 999.99999
- Display '< 0.00001' for values less than 0.00001
- Use 1 decimal less from 1,000.0001 until 9,999.9999
- Use 1 decimal less from 10,000.001 until 99,999.999
- Use 1 decimal less from 100,000.01 until 999,999.99
- Use 1 decimal less from 1,000,000.1 until 9,999,999.9
- From 10,000,000 No Decimals until 99,999,999
- Then Use 10.001M until 999.999M
- Then 1.001B until 999.999B
- Then 1.001T until 999.999T
- Then just > 999T
- Thousands and decimal separators are used according to user's locale.
- M, B, T is localized

```Swift
import SwiftCryptoTokenFormatter
import BigInt

let f = TokenFormatter()
f.string(from: BigDecimal(100_000_000_000000000, 9)) // 100M
f.string(from: BigDecimal(BigInt("999999999000000000000"), 9)) // 999.999B
```

## Features

### Custom rounding behaviour
```Swift
f.roundingBehavior = .cutoff
f.string(from: BigDecimal(0_0000101, 7)) // 0.00001
f.roundingBehavior = .roundUp
f.string(from: BigDecimal(0_0000101, 7)) // 0.00002
```

### Support of negative numbers
```Swift
f.string(from: BigDecimal(-10_000_001000000, 9) // -10,000.001
```

### Number from string
```Swift
f.number(from: "0,001", precision: 3) == BigDecimal(1, 3)
```

### Localizatoin

`string(from:)` allows to override default `decimalSeparator`, `thousandSeparator` and `literals`.

`localizedString(from:)` uses:
-  `Locale.autoupdatingCurrent` for `decimalSeparator` and  `thousandSeparator`
-  `"amount_millions"`, `"amount_billions"` and `"amount_trillions"` localized strings from literals. **You need to provide localizable strings for different locales.**

```Swift
// Assuming russian locale and "amount_billions" = "Б"
formatter.localizedString(from: BigDecimal(BigInt("999999999000000000000"), 9)) // 999,999Б
```

## Installation

### Prerequisites

- iOS 11.0 or macOS 10.14
- Xcode 10.3
- Swift 5



### Manual

Add this repository as a submodule:

```
git submodule add https://github.com/gnosis/SwiftCryptoTokenFormatter.git
```

Fetch the dependencies

```
cd SwiftCryptoTokenFormatter
git submodule update --init
```

Dependencies of the SwiftCryptoTokenFormatter library:
- BigInt

Drag and drop the `SwiftCryptoTokenFormatter.xcodeproj` into your project and link the `SwiftCryptoTokenFormatter` static library.

### CocoaPods

```
pod 'SwiftCryptoTokenFormatter'
```

### Carthage

In your `Cartfile`:
github "gnosis/SwiftCryptoTokenFormatter"

Run `carthage update` to build the framework and drag the SwiftCryptoTokenFormatter.framework into your Xcode project.

### Swift Package Manager

You can use Swift Package Manager and add dependency in your `Package.swift`:
```
    dependencies: [
        .package(url: "https://github.com/gnosis/SwiftCryptoTokenFormatter.git", .upToNextMinor(from: "1.0.0"))
    ]
```

## Contributors

* Dmitry Bespalov ([DmitryBespalov](https://github.com/DmitryBespalov))
* Andrey Scherbovich ([sche](https://github.com/sche))

## License

MIT License (see the LICENSE file).
