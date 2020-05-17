#
# Be sure to run `pod lib lint RxFireAuth.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RxFireAuth'
  s.version          = '1.4.0'
  s.summary          = 'A smart Rx wrapper around Firebase Authentication SDK'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  RxFireAuth is a wrapper around the Firebase Authentication SDK that exposes the most common use cases through RxSwift objects.
  Firebase Authentication is a great way to support user authentication in your app easily. This library builds on top of that to simplify even further the process with pre-built algorithms that support registering, logging-in, linking accounts with other providers and more.
                       DESC

  s.homepage          = 'https://github.com/mrasterisco/RxFireAuth'
  s.license           = { :type => 'MIT', :file => 'LICENSE' }
  s.author            = { 'Alessio Moiso' => 'a.moiso@outlook.com' }
  s.source            = { :git => 'https://github.com/mrasterisco/RxFireAuth.git', :tag => "v"+s.version.to_s }
  s.documentation_url = 'https://mrasterisco.github.io/RxFireAuth/'

  s.swift_version = '5.1'
  s.platform = :ios
  s.ios.deployment_target = '9.0'

  s.weak_framework = 'CryptoKit'

  s.source_files = 'RxFireAuth/Classes/**/*'
  
  s.dependency 'Firebase/Auth', '~> 6.5'
  s.dependency 'GoogleSignIn', '~> 5.0.2'
  s.dependency 'JWTDecode', '~> 2.4'
  s.dependency 'RxCocoa', '~> 5'
  s.static_framework = true
end
