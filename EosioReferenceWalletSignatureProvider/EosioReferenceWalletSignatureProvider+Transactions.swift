//
//  EosioReferenceWalletSignatureProvider+Transactions.swift
//  EosioReferenceWalletSignatureProvider
//
//  Created by Todd Bowden on 11/12/18.
//  Copyright (c) 2018-2019 block.one
//

import Foundation
import EosioSwift

/// Extensions to `EosioReferenceWalletSignatureProvider` to add transaction signature functionality.
extension EosioReferenceWalletSignatureProvider {

    /// Handle transaction signature requests in the payload.
    ///
    /// - Parameter payload: The transaction signature `ResponsePayload`.
    public static func handleIncomingTransactionSignature(payload: ResponsePayload) {
        guard let completion = transactionSignatureCompletions[payload.id] else { return }
        transactionSignatureCompletions[payload.id] = nil
        guard let transactionSignatureResponse = payload.response.transactionSignature else { return }
        DispatchQueue.main.async {
            return completion(transactionSignatureResponse)
        }
    }

    /// Sign transaction implementation method.  Required to conform to `EosioSignatureProviderProtocol`.
    ///
    /// - Parameter: request: The `EosioTransactionSignatureRequest` being sent to the EOSIO Reference Wallet Implementation.
    /// - Parameter completion: The completion closure to be called with the `EosioTransactionSignatureResponse`.
    public func signTransaction(request: EosioTransactionSignatureRequest, completion: @escaping (EosioTransactionSignatureResponse) -> Void) {

        var payload = RequestPayload()
        payload.request.transactionSignature = request
        payload.requireBiometric = requireBiometric

        EosioReferenceWalletSignatureProvider.transactionSignatureCompletions[payload.id] = completion

        // check that return url is valid
        guard isValid(url: returnUrl) else {
            return completion(EosioTransactionSignatureResponse(error: EosioError(.signatureProviderError, reason: "Return url is not valid")))
        }
        payload.returnUrl = returnUrl
        payload.declaredDomain = declaredDomain
        payload.securityExclusions = securityExclusions

        // if callback url provided, check that callback url is valid
        if let callbackUrl = callbackUrl {
            guard isValid(url: callbackUrl) else {
                return completion(EosioTransactionSignatureResponse(error: EosioError(.signatureProviderError, reason: "Callback url is not valid")))
            }
            payload.callbackUrl = callbackUrl
        }

        print("PAYLOAD")
        print(payload)

        // encode the payload
        let encoder = JSONEncoder()
        guard let encodedPayload = try? encoder.encode(payload) else {
            return completion(EosioTransactionSignatureResponse(error: EosioError(.signatureProviderError, reason: "Unable to encode payload")))
        }

        // create url
        guard let url = URL(string: "eosio://request?payload=\(encodedPayload.hex)") else {
            return completion(EosioTransactionSignatureResponse(error: EosioError(.signatureProviderError, reason: "Unable to create url")))
        }
        print(url)

        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { (success) in
                print(success)
            }
        }

    }

    private func isValid(url: String) -> Bool {
        if URL(string: url) != nil {
            return true
        } else {
            return false
        }
    }

}
