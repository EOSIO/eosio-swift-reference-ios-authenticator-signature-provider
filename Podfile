using_local_pods = false

platform :ios, '11.0'

# ignore all warnings from all pods
inhibit_all_warnings!

if using_local_pods
  # Pull pods from sibling directories if using local pods
  target 'EosioSwiftReferenceAuthenticatorSignatureProvider' do
    use_frameworks!

    pod 'EosioSwift', :path => '../eosio-swift'
    pod 'SwiftLint'

    target 'EosioSwiftReferenceAuthenticatorSignatureProviderTests' do
      inherit! :search_paths
      pod 'EosioSwift', :path => '../eosio-swift'
    end
  end
else
  # Pull pods from sources above if not using local pods
  target 'EosioSwiftReferenceAuthenticatorSignatureProvider' do
    use_frameworks!

    pod 'EosioSwift', '~> 0.1.1'
    pod 'SwiftLint'

    target 'EosioSwiftReferenceAuthenticatorSignatureProviderTests' do
      inherit! :search_paths
      pod 'EosioSwift', '~> 0.1.1'
    end
  end
end
