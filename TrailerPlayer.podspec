Pod::Spec.new do |s|
  s.name             = 'TrailerPlayer'
  s.version          = '1.4.5'
  s.summary          = 'iOS video player for trailer.'
  s.description      = <<-DESC
                       iOS video player for trailer. 
                       You can customize layout for the control panel. Support PiP and DRM.
                       DESC
  s.homepage         = 'https://github.com/AbeWang/TrailerPlayer'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Abe Wang' => 'abe.j81189@gmail.com' }
  s.source           = { :git => 'https://github.com/AbeWang/TrailerPlayer.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.swift_version = '5'
  s.source_files = 'Sources/TrailerPlayer/**/*.swift', 'Sources/TrailerPlayer/*.swift'
  s.requires_arc = true
end
