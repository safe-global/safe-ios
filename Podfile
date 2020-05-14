source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '13.0'

inhibit_all_warnings!

target 'Multisig' do

  # The icon image of the ethereum address
  pod 'BlockiesSwift', :git => 'https://github.com/gnosis/BlockiesSwift.git', :branch => '0.1.2-gnosis'
  
  # The Ethereum lib
  pod 'Web3/Core', '0.4.2'
  pod 'Web3/HTTPExtension', '0.4.2'
  
  # Dependency for the Web3: generate module map file
  pod 'secp256k1.swift', :modular_headers => true
  
  # Dependency for ENS name resolution
  pod 'idn2Swift', :git => 'https://github.com/gnosis/pod-idn2.git', :branch => 'master', :testspecs => ['Tests']
  pod 'BigInt', '4.0.0'
  
  pod 'Kingfisher/SwiftUI'
  
  target 'MultisigTests' do
    inherit! :search_paths
  end
  
  target 'MultisigIntegrationTests' do
    inherit! :search_paths
  end

end
