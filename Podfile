using_local_pods = false

unless using_local_pods
  source 'https://github.com/EOSIO/eosio-swift-pod-specs.git'
  source 'https://github.com/CocoaPods/Specs.git'
end

platform :ios, '11.0'

# ignore all warnings from all pods
inhibit_all_warnings!

if using_local_pods
  # Pull pods from sibling directories if using local pods
  target 'EosioReferenceWalletSignatureProvider' do
    use_frameworks!

    pod 'EosioSwift', :path => '../eosio-swift'
    pod 'SwiftLint'

    target 'EosioReferenceWalletSignatureProviderTests' do
      inherit! :search_paths
      pod 'EosioSwift', :path => '../eosio-swift'
    end
  end
else
  # Pull pods from sources above if not using local pods
  target 'EosioReferenceWalletSignatureProvider' do
    use_frameworks!

    pod 'EosioSwift', '~> 0.0.3'
    pod 'SwiftLint'

    target 'EosioReferenceWalletSignatureProviderTests' do
      inherit! :search_paths
      pod 'EosioSwift', '~> 0.0.3'
    end
  end
end
