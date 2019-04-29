//
//  EosioReferenceWalletSignatureProvider+SelectiveDisclosure.swift
//  EosioReferenceWalletSignatureProvider
//
//  Created by Todd Bowden on 11/9/18.
//  Copyright (c) 2018-2019 block.one
//

import Foundation
import EosioSwift

extension EosioReferenceWalletSignatureProvider {

    // handle selective disclosures in the payload (cache data and call completion)
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

    public enum SelectiveDisclosureType: String, Codable {
        case none
        case authorizers
    }

    public struct Disclosure: Codable {
        public var type = SelectiveDisclosureType.none
        // other types may require more data, which would go here
    }

    public struct SelectiveDisclosureRequest: Codable {
        public var disclosures = [Disclosure]()
    }

    public struct SelectiveDisclosureResponse: Codable {
        public var error: EosioError?
        public var authorizers: [Authorizer]?
        // other selective disclosures go here

        public init() { }

        public init(error: EosioError) {
            self.error = error
        }
    }

    public struct Authorizer: Codable {
        public var publicKey = ""
        public init() { }
    }

    // request the Selective disclosure from the EOSIO Auth app
    // opens the EOSIO Auth app and asks the user for permission
    public func requestSelectiveDisclosure(_ request: SelectiveDisclosureRequest, completion: @escaping (SelectiveDisclosureResponse) -> Void) {
        var payload = RequestPayload()
        payload.request.selectiveDisclosure = request
        payload.returnUrl = returnUrl
        payload.declaredDomain = declaredDomain
        payload.callbackUrl = callbackUrl
        EosioReferenceWalletSignatureProvider.selectiveDisclosureCompletions[payload.id] = completion
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

    // Signature provider protocol method
    // get keys from getAvailableAuthorizers
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

    // request the authorizers from the EOSIO Auth app
    // opens the EOSIO Auth app and asks the user for permission
    public func requestAuthorizers(completion: @escaping (SelectiveDisclosureResponse) -> Void) {
        var request = SelectiveDisclosureRequest()
        request.disclosures = [Disclosure(type: .authorizers)]
        requestSelectiveDisclosure(request, completion: completion)
    }

    // returns the cache of last requestAuthorizers call if present
    // otherwise, requests authorizers from the EOSIO Auth app
    // in the future, updated authorizers could be retrieved from a server with a token returned from the last requestAuthorizers call
    // updated authorizers can also be included with each transaction response
    public func getAuthorizers(completion: @escaping (SelectiveDisclosureResponse) -> Void) {
        if let authorizers = try? getAuthorizers() {
            var response = SelectiveDisclosureResponse()
            response.authorizers = authorizers
            completion(response)
        } else {
            requestAuthorizers(completion: completion)
        }
    }

    /// Local Cache

    public func clearAuthorizers() throws {
        let url = try EosioReferenceWalletSignatureProvider.authorizersURL()
        try FileManager.default.removeItem(at: url)
    }

    // read authorizers file from cache
    public func getAuthorizers() throws -> [Authorizer] {
        let url = try EosioReferenceWalletSignatureProvider.authorizersURL()
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
