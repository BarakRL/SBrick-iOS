
# Be sure to run `pod lib lint SBrick-iOS.podspec' to ensure this is a


Pod::Spec.new do |s|

s.name         = "SBrick-iOS"
s.version      = "0.2.2"
s.summary      = "SBrick support for Swift"
s.description  = "Connect and control SBrick using Swift"

s.homepage     = "https://github.com/BarakRL/SBrick-iOS"
s.license      = { :type => "MIT", :file => "LICENSE" }

s.author    = "Barak Harel"
s.platform     = :ios, "10.0"

s.source       = { :git => "https://github.com/BarakRL/SBrick-iOS.git", :tag => "#{s.version}" }
s.source_files  = "Classes", "SBrick-iOS/Classes/**/*.{swift}"
s.module_name	 = 'SBrick'

s.frameworks = 'CoreBluetooth'

end

