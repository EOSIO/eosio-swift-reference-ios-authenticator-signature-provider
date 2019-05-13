#
# Be sure to run `pod lib lint EosioSwiftReferenceAuthenticatorSignatureProvider.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'EosioSwiftReferenceAuthenticatorSignatureProvider'
  s.version          = '0.0.1'
  s.summary          = 'Signature Provider for Eosio SDK for Swift that relays transactions to the EOSIO Reference Authenticator Implementation.'
  s.homepage         = 'https://github.com/EOSIO/eosio-swift-reference-ios-authenticator-signature-provider'
  s.license          = { :type => 'MIT', :text => <<-LICENSE
                           Copyright (c) 2017-2019 block.one and its contributors.  All rights reserved.
                         LICENSE
                       }
  s.author           = { 'Todd Bowden' => 'todd.bowden@block.one',
                         'Serguei Vinnitskii' => 'serguei.vinnitskii@block.one',
                         'Farid Rahmani' => 'farid.rahmani@block.one',
                         'Brandon Fancher' => 'brandon.fancher@block.one',
                         'Steve McCoole' => 'steve.mccoole@objectpartners.com',
                         'Ben Martell' => 'ben.martell@objectpartners.com' }
  s.source           = { :git => 'https://github.com/EOSIOeosio-swift-reference-ios-authenticator-signature-provider.git', :tag => "v" + s.version.to_s }

  s.swift_version         = '4.2'
  s.ios.deployment_target = '11.0'

  s.source_files = 'EosioSwiftReferenceAuthenticatorSignatureProvider/**/*.swift'

  s.pod_target_xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
                            'CLANG_ENABLE_MODULES' => 'YES',
                            'SWIFT_COMPILATION_MODE' => 'wholemodule',
                            'ENABLE_BITCODE' => 'YES' }

  s.ios.dependency 'EosioSwift', '~> 0.0.3'
end
