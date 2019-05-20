//
//  EosioReferenceAuthenticatorSignatureProvider+SelectiveDisclosure.swift
//  EosioReferenceAuthenticatorSignatureProvider
//
//  Created by Todd Bowden on 11/9/18.
//  Copyright (c) 2017-2019 block.one and its contributors. All rights reserved.
//

import Foundation
import EosioSwift

/// Extensions to `EosioReferenceWalletSignatureProvider` to add selective disclosure functionality.
extension EosioReferenceAuthenticatorSignatureProvider {

    /// Handle selective disclosures in the payload, caching data and call completion.
    ///
    /// - Parameter payload: The selective disclosure `ResponsePayload`
    public static func handleIncomingSelectiveDisclosure(payload: ResponsePayload) {
        guard let selectiveDisclosureResponse = payload.response.selectiveDisclosure else { return }
        if let authorizers = selectiveDisclosureResponse.authorizers {
            try? saveAuthorizers(authorizers)
        }

        guard let completion = selectiveDisclosureCompletions[payload.id] else { return }
        selectiveDisclosureCompletions[payload.id] = nil
        DispatchQueue.main.async {
            return completion(selectiveDisclosureResponse)
        }
    }

    /// The type of selective disclosure.
    public enum SelectiveDisclosureType: String, Codable {
        /// Default, unset value.
        case none
        /// Selective disclosure of authorizers requested.
        case authorizers
    }

    /// Single disclosure request.
    public struct Disclosure: Codable {
        public var type = SelectiveDisclosureType.none
        // other types may require more data, which would go here
    }

    /// Selective disclosure request.  Can contain multiple disclosures in a single request.
    public struct SelectiveDisclosureRequest: Codable {
        /// Requested disclosures.
        public var disclosures = [Disclosure]()
    }

    /// Selective disclosure response.
    public struct SelectiveDisclosureResponse: Codable {
        /// Error, set if the request fails.
        public var error: EosioError?
        /// List of authorizors, returned if the request is successful.
        public var authorizers: [Authorizer]?

        // other selective disclosures go here

        public init() { }

        public init(error: EosioError) {
            self.error = error
        }
    }

    /// Authorizer information returned in selective disclosure.
    public struct Authorizer: Codable {
        /// The authorizer public key.
        public var publicKey = ""

        public init() { }
    }

    /// Request selective disclosure from the EOSIO Reference Wallet Implementation.
    /// Opens the EOSIO Reference Wallet Implementation and asks the user for permission.
    ///
    /// - Parameter request: The `SelectiveDisclosureRequest` being sent to the EOSIO Reference Wallet Implementation.
    /// - Parameter completion: The completion closure to be called with the `SelectiveDisclosureResponse`.
    public func requestSelectiveDisclosure(_ request: SelectiveDisclosureRequest, completion: @escaping (SelectiveDisclosureResponse) -> Void) {
        var payload = RequestPayload()
        payload.request.selectiveDisclosure = request
        payload.returnUrl = returnUrl
        payload.declaredDomain = declaredDomain
        payload.callbackUrl = callbackUrl
        payload.securityExclusions = securityExclusions
        EosioReferenceAuthenticatorSignatureProvider.selectiveDisclosureCompletions[payload.id] = completion
        guard let requestHex = payload.toHex else {
            return completion(SelectiveDisclosureResponse(error: EosioError(.signatureProviderError, reason: "Unable to encode hex request")))
        }

        guard let url = URL(string: "eosio://request?payload=\(requestHex)") else {
            return completion(SelectiveDisclosureResponse(error: EosioError(.signatureProviderError, reason: "Unable to create url")))
        }

        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:]) { (success) in
                print(success)
            }
        }
    }

    /// Get the list of keys from the available authorizers.  Required to conform to `EosioSignatureProviderProtocol`.
    ///
    /// - Parameter completion: Closure to call with the `EosioAvailableKeysResponse`.
    public func getAvailableKeys(completion: @escaping (EosioAvailableKeysResponse) -> Void) {
        getAuthorizers { (availableAuthorizersResponse) in
            var availableKeysResponse = EosioAvailableKeysResponse()
            availableKeysResponse.error = availableAuthorizersResponse.error
            if let authorizers = availableAuthorizersResponse.authorizers {
                var keys = [String]()
                for authorizer in authorizers {
                    if !keys.contains(authorizer.publicKey) {
                        keys.append(authorizer.publicKey)
                    }
                }
                availableKeysResponse.keys = keys
            }
            completion(availableKeysResponse)
        }
    }

    /// Request authorizers from the EOSIO Reference Wallet Implementation.
    /// Opens the EOSIO Reference Wallet Implementation and asks the user for permission.
    ///
    /// - Parameter completion: The completion closure to be called with the `SelectiveDisclosureResponse`.
    public func requestAuthorizers(completion: @escaping (SelectiveDisclosureResponse) -> Void) {
        var request = SelectiveDisclosureRequest()
        request.disclosures = [Disclosure(type: .authorizers)]
        requestSelectiveDisclosure(request, completion: completion)
    }

    /// Returns the cache of the last `requestAuthorizers` call if present.  Otherwise, requests authorizers from the
    /// EOSIO Reference Wallet Implementation.
    /// - Remark: In the future, updated authorizers could be retrieved from a server with a token returned from
    /// the last `requestAuthorizers` call.  Updated authorizers can also be included with each transaction response.
    ///
    /// - Parameters completion: The completion closure to be called with the `SelectiveDisclosureResponse`.
    public func getAuthorizers(completion: @escaping (SelectiveDisclosureResponse) -> Void) {
        if let authorizers = try? getAuthorizers() {
            var response = SelectiveDisclosureResponse()
            response.authorizers = authorizers
            completion(response)
        } else {
            requestAuthorizers(completion: completion)
        }
    }

    // MARK: - Local Cache Functions

    /// Clear the authorizers in the local cache.
    public func clearAuthorizers() throws {
        let url = try EosioReferenceAuthenticatorSignatureProvider.authorizersURL()
        try FileManager.default.removeItem(at: url)
    }

    /// Read authorizers file from cache.
    ///
    /// - Returns: `Array` of `Authorizer`.
    /// - Throws: If there is an error building the authorizers URL or decoding the cached authorizers JSON.
    public func getAuthorizers() throws -> [Authorizer] {
        let url = try EosioReferenceAuthenticatorSignatureProvider.authorizersURL()
        let authorizersJson = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let authorizers = try decoder.decode([Authorizer].self, from: authorizersJson)
        return authorizers
    }

    // save authorizers file to cache
    static func saveAuthorizers(_ authorizers: [Authorizer]) throws {
        let encoder = JSONEncoder()
        let authorizersJson = try encoder.encode(authorizers)
        let url = try authorizersURL()
        try authorizersJson.write(to: url)
    }

    static func selectiveDisclosureURL() throws -> URL {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw EosioError(.signatureProviderError, reason: "Cannot get document directory")
        }
        let url = documentsDirectory.appendingPathComponent("SelectiveDisclosure")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url
    }

    static func authorizersURL() throws -> URL {
        return try selectiveDisclosureURL().appendingPathComponent("authorizers.json")
    }

}
