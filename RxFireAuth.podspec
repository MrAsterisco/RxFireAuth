#
# Be sure to run `pod lib lint RxFireAuth.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RxFireAuth'
  s.version          = '1.0.0'
  s.summary          = 'A smart Rx wrapper around Firebase Authentication SDK'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/mrasterisco/RxFireAuth'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mrasterisco' => 'alessio@inerziasoft.eu' }
  s.source           = { :git => 'https://github.com/mrasterisco/RxFireAuth.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'RxFireAuth/Classes/**/*'
  
  # s.resource_bundles = {
  #   'RxFireAuth' => ['RxFireAuth/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Firebase/Auth', '~> 6.5'
  s.dependency 'JWTDecode', '~> 2.4'
  s.dependency 'RxCocoa', '~> 5'
  s.static_framework = true
end
