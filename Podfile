# Uncomment the next line to define a global platform for your project
platform :ios, '9.1'

inhibit_all_warnings!

source 'https://github.com/CocoaPods/Specs.git'

target 'TYVideoPlayerDemo' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
  # use_frameworks!
  pod 'SDWebImage', '~>3.7'
  pod 'Masonry'
  pod 'Mantle', '1.5.6'
  pod 'AFNetworking'

#    pod 'FLEX'
#pod 'TYSafeKit', :git => 'git@code.aliyun.com:zzuliliyongqiang/SafeKit.git', :branch => 'master',:configurations => ['Release']
pod 'TYVideoPlayer', :path => './'
#    pod 'TYVideoPlayer', :git =>'git@code.aliyun.com:zzuliliyongqiang/TYVideoPlayer.git', :branch => 'master'
  # Pods for TYVideoPlayerDemo
  
  post_install do |installer|
      installer.pods_project.targets.each do |target|
          target.build_configurations.each do |config|
              config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.2'
          end
      end
  end

end
