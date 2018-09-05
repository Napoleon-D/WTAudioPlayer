

Pod::Spec.new do |s|

s.name        = "WTAudioPlayer"

s.version     = "0.0.2"

s.platform = :ios, "8.0"

s.summary     = "~~iOS~~边下边播~~音频播放器~~"

s.homepage    = "https://github.com/ox-man"

s.author     = { "ox-man" => "wangtao199205@qq.com" }

s.source      = { :git => "https://github.com/ox-man/WTAudioPlayer.git",:tag => s.version}

s.source_files = 'MusicPlayer/*'

s.license     = { :type => "MIT", :file => "FILE_LICENSE" }

s.requires_arc = true

s.dependency "KTVHTTPCache" , "YYCategories"

end
