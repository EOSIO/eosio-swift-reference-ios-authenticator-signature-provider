![Swift Logo](https://github.com/EOSIO/eosio-swift-reference-ios-authenticator-signature-provider/raw/master/img/swift-logo.png)
# EOSIO SDK for Swift: Reference iOS Authenticator Signature Provider ![EOSIO Alpha](https://img.shields.io/badge/EOSIO-Alpha-blue.svg)
[![Software License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://github.com/EOSIO/eosio-swift-reference-ios-authenticator-signature-provider/blob/master/LICENSE)
[![Swift 4.2](https://img.shields.io/badge/Language-Swift_4.2-orange.svg)](https://swift.org)
![](https://img.shields.io/badge/Deployment%20Target-iOS%2011-blue.svg)

Reference iOS Authenticator Signature Provider is a pluggable signature provider for [EOSIO SDK for Swift](https://github.com/EOSIO/eosio-swift). Native iOS Apps using this signature provider in conjunction with EOSIO SDK for Swift are able to integrate with the [EOSIO Reference iOS Authenticator App](https://github.com/EOSIO/eosio-reference-ios-authenticator-app), allowing their users to sign in and approve transactions via the authenticator app.

Inter-application communication conforms to and is facilitated by the [EOSIO Authentication Transport Protocol Specification](https://github.com/EOSIO/eosio-authentication-transport-protocol-spec).

_All product and company names are trademarks™ or registered® trademarks of their respective holders. Use of them does not imply any affiliation with or endorsement by them._

## Contents
- [About Signature Providers](#about-signature-providers)
- [Prerequisites](#prerequisites)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Usage with EOSIO SDK for Swift](#usage-with-eosio-sdk-for-swift)
- [Direct Usage](#direct-usage)
- [Architecture](#architecture)
- [Documentation](#documentation)
- [Library Methods and Options](#library-methods-and-options)
- [Want to Help?](#want-to-help)
- [License & Legal](#license)

## About Signature Providers
The Signature Provider abstraction is arguably the most useful of all of the [EOSIO SDK for Swift](https://github.com/EOSIO/eosio-swift) providers. It is responsible for:

* finding out what keys are available for signing (`getAvailableKeys`), and
* requesting and obtaining transaction signatures with a subset of the available keys (`signTransaction`).

By simply switching out the signature provider on a transaction, signature requests can be routed any number of ways. Need a signature directly from keys in the platform's Keychain or Secure Enclave? Configure the `EosioTransaction` with a conforming signature provider that exposes that functionality, such as the [EOSIO SDK for Swift: Vault Signature Provider](https://github.com/EOSIO/eosio-swift-vault-signature-provider). Need signatures from a wallet on the user's device? This signature provider demonstrates that functionality.

All signature providers must conform to the [EosioSignatureProviderProtocol](https://github.com/EOSIO/eosio-swift/blob/master/EosioSwift/EosioSignatureProviderProtocol/EosioSignatureProviderProtocol.swift) Protocol.

## Prerequisites
* Xcode 10 or higher
* CocoaPods 1.5.3 or higher
* For iOS, iOS 11+

## Dependencies
Reference iOS Authenticator Signature Provider depends on the [EOSIO SDK for Swift](https://github.com/EOSIO/eosio-swift) library as a dependency. EOSIO SDK for Swift will be automatically installed when you include the Reference iOS Authenticator Signature Provider in your application with CocoaPods.

Reference iOS Authenticator Signature Provider also requires the presence on the user's device of [EOSIO Reference iOS Authenticator App](https://github.com/EOSIO/eosio-reference-ios-authenticator-app) or another authenticator implementing the required interfaces to pass selective disclosure and signature requests to.

## Installation
Reference iOS Authenticator Signature Provider is intended to be used in conjunction with [EOSIO SDK for Swift](https://github.com/EOSIO/eosio-swift) as a provider plugin.

To use Reference iOS Authenticator Signature Provider with EOSIO SDK for Swift in your app, add the following pods to your [Podfile](https://guides.cocoapods.org/syntax/podfile.html):

```ruby
use_frameworks!

target "Your Target" do
  pod "EosioSwift", "~> 0.1.1" # EOSIO SDK for Swift core library
  pod "EosioSwiftReferenceAuthenticatorSignatureProvider", "~> 0.1.0" # pod for this library
  # add other providers for EOSIO SDK for Swift
  pod "EosioSwiftAbieosSerializationProvider", "~> 0.1.1" # serialization provider
end
```
Now Reference iOS Authenticator Signature Provider is ready for use within EOSIO SDK for Swift according to the [EOSIO SDK for Swift Basic Usage instructions](https://github.com/EOSIO/eosio-swift/tree/master#basic-usage).

## Usage with EOSIO SDK for Swift
Generally, signature providers are called by [`EosioTransaction`](https://github.com/EOSIO/eosio-swift/blob/master/EosioSwift/EosioTransaction/EosioTransaction.swift) during signing. ([See a generic example here.](https://github.com/EOSIO/eosio-swift#basic-usage)). To specifically use Reference iOS Authenticator Signature Provider in `EosioTransaction`, you can follow the example below:

```swift
let from = "testuseraaaa"
let to = "testuserbbbb"
var amount = "10.0000 SYS"
let memo = "Test transfer."

let transaction = EosioTransaction()
transaction.rpcProvider = EosioRpcProvider(endpoint: URL(string: "https://my.blockchain.domain")!)
transaction.serializationProvider = EosioAbieosSerializationProvider()

let eosioAppSignatureProvider = EosioReferenceAuthenticatorSignatureProvider.shared
eosioAppSignatureProvider.returnUrl = "myappurl://"
eosioAppSignatureProvider.declaredDomain = "myapp.domain.com"

// Optional, set security exclusions if testing or debugging
if let theSecurityExclusions = self.securityExclusions {
    eosioAppSignatureProvider.securityExclusions = theSecurityExclusions
}

transaction.signatureProvider = eosioAppSignatureProvider

let action = try! EosioTransaction.Action(
    account: EosioName("eosio.token"),
    name: EosioName("transfer"),
        authorization: [EosioTransaction.Action.Authorization(
        actor: EosioName(from),
        permission: EosioName("active"))
      	 ],
    data: Transfer(
        from: EosioName(from),
        to: EosioName(to),
        quantity: amount,
        memo: memo)
)
transaction.add(action: action)

transaction.signAndBroadcast { (result) in
    print(try! transaction.toJson(prettyPrinted: true))
    switch result {
    case .failure (let error):
        print("Error = \(error)")
        self.showAlert(title: error.errorCode.rawValue, message: "\(error.localizedDescription)", dismiss: "Sorry :(")
    case .success:
        if let transactionId = transaction.transactionId {
            print("SUCCESS!!!!!!")
            self.showAlert(title: "SUCCESS!!!!!!", message: "TransactionId: \(transactionId)", dismiss: "OK :)")
            print(transactionId)
        }
    }
}
```

## Direct Usage
If you find, however, that you need to get available keys or request signing directly, this library can be invoked as follows:

```swift
let eosioAppSignatureProvider = EosioReferenceAuthenticatorSignatureProvider.shared
eosioAppSignatureProvider.returnUrl = "myappurl://"
eosioAppSignatureProvider.declaredDomain = "myapp.domain.com"

// Initialize security exclusions and set if desired. Optional.
if let theSecurityExclusions = self.securityExclusions {
    eosioAppSignatureProvider.securityExclusions = theSecurityExclusions
}

eosioAppSignatureProvider.getAvailableKeys() { (response) in
    if let error = response.error {
	     // Handle error
    }
    if let keys = response.keys {
        // Get Accounts for Keys and potentially let users choose which
        // account key to use.
    }
}
```

To sign an [`EosioTransaction`](https://github.com/EOSIO/eosio-swift/blob/master/EosioSwift/EosioTransaction/EosioTransaction.swift), create an [`EosioTransactionSignatureRequest`](https://github.com/EOSIO/eosio-swift/blob/master/EosioSwift/EosioSignatureProviderProtocol/EosioSignatureProviderProtocol.swift) object and call the `EosioReferenceAuthenticatorSignatureProvider.signTransaction(request:completion:)` method with the request:

```swift
let eosioAppSignatureProvider = EosioReferenceAuthenticatorSignatureProvider.shared
eosioAppSignatureProvider.returnUrl = "myappurl://"
eosioAppSignatureProvider.declaredDomain = "myapp.domain.com"

// Initialize security exclusions and set if desired. Optional.
if let theSecurityExclusions = self.securityExclusions {
    eosioAppSignatureProvider.securityExclusions = theSecurityExclusions
}

var signRequest = EosioTransactionSignatureRequest()
signRequest.serializedTransaction = serializedTransaction
signRequest.publicKeys = publicKeys
signRequest.chainId = chainId

eosioAppSignatureProvider.signTransaction(request: signRequest) { (response) in
    ...
}
```

## Architecture
Reference iOS Authenticator Signature Provider uses the [Deep Link URL Query String Payload transport](https://github.com/EOSIO/eosio-authentication-transport-protocol-spec#url-query-string-payload) to send requests to the EOSIO Reference iOS Authenticator App.

EOSIO Reference iOS Authenticator App sends responses to the requesting app via the `EosioReferenceAuthenticatorSignatureProvider.returnUrl`. Responses take the form of an `EosioAvailableKeysResponse` or an `EosioTransactionSignatureResponse`.

 All of this conforms to and is facilitate by the [EOSIO Authentication Transport Protocol Specification](https://github.com/EOSIO/eosio-authentication-transport-protocol-spec).

![Diagram](https://github.com/EOSIO/eosio-swift-reference-ios-authenticator-signature-provider/raw/master/img/diagram.png)

Your application will need to be registered for the URL scheme that you configured in the Reference iOS Authenticator Signature Provider and implement the [`application(_:open:options:)`](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623112-application) method in your `AppDelegate` to handle the incoming URL and encoded parameters that will be sent back by the EOSIO Reference iOS Authenticator App.

```
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    EosioReferenceAuthenticatorSignatureProvider.handleIncoming(url: url)
    return true
}
```

## Documentation
Please refer to the generated code documentation at https://eosio.github.io/eosio-swift-reference-ios-authenticator-signature-provider or by cloning this repo and opening the `docs/index.html` file in your browser.

## Library Methods and Options
This library is an implementation of [`EosioSignatureProviderProtocol`](https://github.com/EOSIO/eosio-swift/blob/master/EosioSwift/EosioSignatureProviderProtocol/EosioSignatureProviderProtocol.swift). It implements the following protocol methods:

* `EosioSwiftReferenceAuthenticatorSignatureProvider.signTransaction(request:completion:)` signs an [`EosioTransaction`](https://github.com/EOSIO/eosio-swift/blob/master/EosioSwift/EosioTransaction/EosioTransaction.swift).
* `EosioSwiftReferenceAuthenticatorSignatureProvider.getAvailableKeys(completion:)` returns a response containing the public keys associated with the private keys that the object is initialized with.

`EosioSwiftReferenceAuthenticatorSignatureProvider` is implemented as a singleton. To access it simply call:

* `let eosioAppSignatureProvider = EosioSwiftReferenceAuthenticatorSignatureProvider.shared` which will return the current instance, initializing it if necessary.
* Set the return URL, if you have not already done so. `eosioAppSignatureProvider.returnUrl = "myappurl://"`
* Set the declared domain for matching, if you have not already done so. `eosioAppSignatureProvider.declaredDomain = "myapp.domain.com"`
* Optionally, pass any `SecurityExclusions` you wish to set if you are doing development and testing. `eosioAppSignatureProvider.securityExclusions = mySecurityExclusions`. More information about security exclusions can be found [here](https://github.com/EOSIO/eosio-authentication-transport-protocol-spec#securityexclusions-optional).

Other functions included with Reference iOS Authenticator Signature Provider will assist you in handling, decoding and validating incoming URL responses from EOSIO Reference iOS Authenticator App.

## Want to help?
Interested in contributing? That's great! Here are some [Contribution Guidelines](./CONTRIBUTING.md) and the [Code of Conduct](./CONTRIBUTING.md#conduct).

## License
[MIT](./LICENSE)

## Important
See LICENSE for copyright and license terms.  Block.one makes its contribution on a voluntary basis as a member of the EOSIO community and is not responsible for ensuring the overall performance of the software or any related applications.  We make no representation, warranty, guarantee or undertaking in respect of the software or any related documentation, whether expressed or implied, including but not limited to the warranties or merchantability, fitness for a particular purpose and noninfringement. In no event shall we be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or documentation or the use or other dealings in the software or documentation.  Any test results or performance figures are indicative and will not reflect performance under all conditions.  Any reference to any third party or third-party product, service or other resource is not an endorsement or recommendation by Block.one.  We are not responsible, and disclaim any and all responsibility and liability, for your use of or reliance on any of these resources. Third-party resources may be updated, changed or terminated at any time, so the information here may be out of date or inaccurate.

Wallets and related components are complex software that require the highest levels of security.  If incorrectly built or used, they may compromise users’ private keys and digital assets. Wallet applications and related components should undergo thorough security evaluations before being used.  Only experienced developers should work with this software.
