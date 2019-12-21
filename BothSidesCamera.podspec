#
# Be sure to run `pod lib lint BothSidesCamera.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BothSidesCamera'
  s.version          = '1.2.0'
  s.summary          = 'infomation BothSidesCamera.'

  s.description      = 'TODO:　Simultaneous recording of both screens.'


  s.homepage         = 'https://github.com/daisukenagata/BothSidesCamera'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'daisukenagata' => 'dbank0208@gmail.com' }
  s.source           = { :git => 'https://github.com/daisukenagata/BothSidesCamera.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.2'
  s.swift_version = '5.0'
  s.source_files = 'BothSidesCamera/Classes/**/*'
end
