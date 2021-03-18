source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '13.0'

inhibit_all_warnings!

project 'Multisig',

  'Debug.Production.Mainnet'    => :debug,
  'Release.Production.Mainnet'  => :release,

  'Debug.Production.Rinkeby'    => :debug,
  'Release.Production.Rinkeby'  => :release,

  'Debug.Staging.Rinkeby'       => :debug,
  'Release.Staging.Rinkeby'     => :release,

  'Debug.Staging.Mainnet'       => :debug,
  'Release.Staging.Mainnet'     => :release,

  'Debug.Development.Rinkeby'       => :debug,
  'Release.Development.Rinkeby'     => :release,

  'Debug.Development.Mainnet'       => :debug,
  'Release.Development.Mainnet'     => :release

target 'Multisig' do

  # The icon image of the ethereum address
  pod 'BlockiesSwift', :git => 'https://github.com/gnosis/BlockiesSwift.git', :branch => '0.1.2-gnosis'
  
  # The Ethereum lib
  pod 'Web3/Core', :git => 'https://github.com/gnosis/Web3.swift.git', :branch => 'enhance-signing'
  pod 'Web3/HTTPExtension', :git => 'https://github.com/gnosis/Web3.swift.git', :branch => 'enhance-signing'
  
  # Dependency for the Web3: generate module map file
  pod 'secp256k1.swift', :modular_headers => true
  
  # Dependency for ENS name resolution
  pod 'idn2Swift', :git => 'https://github.com/gnosis/pod-idn2.git', :branch => 'master', :testspecs => ['Tests']
  
  # Dependency for handling images loaded by url
  pod 'Kingfisher/SwiftUI', '5.14.0'

  # Dependency for formatting tokens in UI
  # Uses BigInt as a dependency
  pod 'SwiftCryptoTokenFormatter', '1.0.0'

  # Tracking of events of interest
  pod 'Firebase/Analytics'
  # Crash reporting
  pod 'Firebase/Crashlytics'
  # Push notifications
  pod 'Firebase/Messaging'

  # Dependency for SSL pinning
  pod 'TrustKit'

  pod 'UnstoppableDomainsResolution', '~> 0.3.5'
  
  target 'MultisigTests' do
    inherit! :search_paths
  end
  
  target 'MultisigIntegrationTests' do
    inherit! :search_paths
  end

end

target 'NotificationServiceExtension' do
  pod 'SwiftCryptoTokenFormatter', '1.0.0'
end
