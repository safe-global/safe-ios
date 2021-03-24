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

    # Dependency for ENS name resolution
    pod 'idn2Swift', :git => 'https://github.com/gnosis/pod-idn2.git', :branch => 'master', :testspecs => ['Tests']

    # Dependency for handling images loaded by url
    pod 'Kingfisher/SwiftUI', '5.14.0'

    # Tracking of events of interest
    pod 'Firebase/Analytics'
    # Crash reporting
    pod 'Firebase/Crashlytics'
    # Push notifications
    pod 'Firebase/Messaging'

    # Dependency for SSL pinning
    pod 'TrustKit'

    # Dependency for implementing authentication
    pod 'SwiftAccessPolicy', :git => 'https://github.com/gnosis/SwiftAccessPolicy.git', :branch => 'main'

    target 'MultisigTests' do
      inherit! :search_paths
    end

    target 'MultisigIntegrationTests' do
      inherit! :search_paths
    end

end

post_install do |pi|
   pi.pods_project.targets.each do |t|
       t.build_configurations.each do |bc|
           if bc.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] == '8.0'
             bc.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
           end
       end
   end
end
