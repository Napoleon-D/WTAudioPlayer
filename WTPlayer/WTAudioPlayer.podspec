

Pod::Spec.new do |s|

s.name        = 'ATAudioPlayer'
s.version     = '0.0.1'
s.authors     = { 'ox-man' => 'wangtao199205@qq.com' }
s.homepage    = 'https://github.com/ox-man'
s.summary     = '~~iOS~~边下边播~~音频播放器~~'
s.source      = { :git => 'https://github.com/ox-man/WTAudioPlayer.git',:tag => s.version.to_s }
s.license     = { :type => "MIT", :file => "LICENSE" }
s.platform = :ios, '8.0'
s.requires_arc = true
s.ios.deployment_target = '7.0'
s.requires_arc = true
s.dependency "KTVHTTPCache"
s.dependency "YYCategories"

end
