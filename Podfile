
use_frameworks!

workspace 'MonoProjects'


target 'HAgility' do
    platform :ios, '16.0'
    project 'MonoRepos/HAgility/HAgility.xcodeproj'
    pod 'SwiftLint', '0.58.0'
    pod 'SwiftFormat/CLI', '0.53.0'
  
end

post_install do |installer|
  # Configure the Pods project
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['DEAD_CODE_STRIPPING'] = 'YES'
  end

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'].to_f < 12.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
  end
end

