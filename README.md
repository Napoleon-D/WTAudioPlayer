# WTAudioPlayer

iOS开发 边下边播的音乐播放器

具体的使用介绍，请参考这篇博客：https://www.jianshu.com/p/fcea236174dc

安装方式 pod WTAudioPlayer

注意：

    <1>添加MediaPlayer.framework，AudioToolbox.framework，AVFoundation.framework
    
    <2>在工程里的info.plist添加App Transport Security Settings属性，并将Allow Arbitrary Loads设置为YES,来支持http传输
    
    <3>千万别创建临时变量来调用播放的方法
