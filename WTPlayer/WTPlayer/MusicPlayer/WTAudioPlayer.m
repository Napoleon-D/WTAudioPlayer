//
//  WTAudioPlayer.m
//  WTPlayer
//
//  Created by Tommy on 2018/6/7.
//  Copyright © 2018年 Tommy. All rights reserved.
//

#define PlayerStatus @"status"
#define PlayerLoadedStatus @"loadedTimeRanges"


#import "WTAudioPlayer.h"
#import <KTVHTTPCache/KTVHTTPCache.h>
#import "PauseTimeModel.h"
#import "AudioURLModel.h"
#import "Header.h"

@interface WTAudioPlayer()

///  音频播放器
@property(nonatomic,strong)AVPlayer *audioPlayer;
///  当前播放器的状态
@property(nonatomic,assign)WTAudioPlayerStatus playerStatus;
///  应用被唤醒时候，是否需要继续播放
@property(nonatomic,assign)BOOL needResumePlay;
///  记录暂停时间
@property(nonatomic,strong)NSMutableDictionary <NSString *,PauseTimeModel *>*pauseTimeDict;
///  记录资源item
@property(nonatomic,strong)NSMutableDictionary <NSString *,AVPlayerItem *>*itemDict;
///  记录音频链接
@property(nonatomic,strong)NSMutableArray <NSString *>*urlArray;
///  记录音频模型
@property(nonatomic,strong)NSMutableArray <AudioURLModel *>*urlModelArray;
///  当前音频链接
@property(nonatomic,copy)NSString *currentAudioPlayingURLString;
///  当前视频播放器长度的观察者
@property(nonatomic,assign)id timeObserve;
///  是否已经播放
//@property(nonatomic,assign)BOOL didPlayAudio;
@end

@implementation WTAudioPlayer

+ (instancetype)sharedAudioPlayer{
    static WTAudioPlayer *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WTAudioPlayer alloc] init];
    });
    return instance;
}

+(WTAudioPlayer *)audioPlayer{
    return [[WTAudioPlayer alloc] init];
}

-(instancetype)init{
    if (self = [super init]) {
        _audioPlayer = [[AVPlayer alloc] init];
        _audioPlayer.volume = 1.0f;
        _pauseTimeDict = [NSMutableDictionary dictionary];
        _itemDict = [NSMutableDictionary dictionary];
        _urlArray = [NSMutableArray array];
        _urlModelArray = [NSMutableArray array];
        _timeObserve = nil;
        [self registerSystemObserve];
        [self setupHTTPCache];
    }
    return self;
}

-(void)registerSystemObserve{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

-(void)registerAVPlayerItemObserveWithItem:(AVPlayerItem *)item{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recoveryPlayError:) name:AVPlayerItemNewErrorLogEntryNotification object:item];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptPlayToCache:) name:AVPlayerItemPlaybackStalledNotification object:item];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedPlayToEnd:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:item];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recoveryPlaySuccess:) name:AVPlayerItemNewAccessLogEntryNotification object:item];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(successPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];
    [item addObserver:self forKeyPath:PlayerStatus options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:PlayerLoadedStatus options:NSKeyValueObservingOptionNew context:nil];
}

-(void)removeAVPlayerItemObserveWithItem:(AVPlayerItem *)item{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemNewErrorLogEntryNotification object:item];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:item];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:item];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemNewAccessLogEntryNotification object:item];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:item];
    [item removeObserver:self forKeyPath:PlayerStatus];
    [item removeObserver:self forKeyPath:PlayerLoadedStatus];
}

- (void)setupHTTPCache
{
    ///  是否打印日志
    [KTVHTTPCache logSetConsoleLogEnable:NO];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /// 本地服务只开启一次
        NSError * error;
        [KTVHTTPCache proxyStart:&error];
        if (error) {
            NSLog(@"Proxy Start Failure, %@", error);
        }
    });
    [KTVHTTPCache tokenSetURLFilter:^NSURL * (NSURL * URL) {
        return URL;
    }];
    [KTVHTTPCache downloadSetUnsupportContentTypeFilter:^BOOL(NSURL * URL, NSString * contentType) {
        return NO;
    }];
    
}

#pragma mark 公有方法


-(void)playWithUrlString:(NSString *)urlString isLocalFileURL:(BOOL)isLocalFile forClass:(Class)targetClass{
    
    if (![urlString isNotBlank]) {
        NSLog(@"音频链接不能为空！");
        return;
    }
    
    AVPlayerItem *item;
    if ([_urlArray containsObject:urlString]) {
        
        ///  播放过的音频，直接获取item
        item = (AVPlayerItem *)[_itemDict objectForKey:urlString];
        [_audioPlayer replaceCurrentItemWithPlayerItem:item];
        __weak WTAudioPlayer *weakSelf = self;
        [_audioPlayer seekToTime:CMTimeMake(0, 1) completionHandler:^(BOOL finished) {
            [weakSelf.audioPlayer play];
            weakSelf.playerStatus = WTAudioPlayerStatusPlaying;
            
            ///  改变状态并回调
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([weakSelf.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:audioURLString:)] && weakSelf.delegate) {
                    [weakSelf.delegate audioPlayer:weakSelf.audioPlayer didChangedStatus:weakSelf.playerStatus audioURLString:self.currentAudioPlayingURLString];
                }
            });
            
            [self setAudioURLModelStatusWithString:urlString andStatus:WTAudioPlayerStatusPlaying];
            
        }];
    }else{
        ///  未播放过得音频，添加到记录中去
        [_urlArray addObject:urlString];
        AudioURLModel *model = [[AudioURLModel alloc] init];
        model.audioURL = urlString;
        model.isLocalFile = isLocalFile;
        model.tagClass = NSStringFromClass([targetClass class]);
        [_urlModelArray addObject:model];
        item = [self playerItemWithUrlString:urlString isLocalFileURL:isLocalFile];
        [_itemDict setObject:item forKey:urlString];
        [_audioPlayer replaceCurrentItemWithPlayerItem:item];
        self.playerStatus = WTAudioPlayerStatusCaching;
        ///  改变状态并回调
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:audioURLString:)] && self.delegate) {
                [self.delegate audioPlayer:self.audioPlayer didChangedStatus:self.playerStatus audioURLString:self.currentAudioPlayingURLString];
            }
        });
        [self setAudioURLModelStatusWithString:urlString andStatus:WTAudioPlayerStatusCaching];
        
    }
    self.needResumePlay = YES;
    self.currentAudioPlayingURLString = urlString;
    [self addTimeObsrveToAudioPlayerWithItem:item];
    self.currentAudioPlayingURLString = urlString;
}

-(void)addTimeObsrveToAudioPlayerWithItem:(AVPlayerItem *)item{
    
    __weak WTAudioPlayer *weakSelf = self;
    if (_timeObserve) {
        [_audioPlayer removeTimeObserver:_timeObserve];
        _timeObserve = nil;
    }
    _timeObserve = [_audioPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf resolvePlayerTime:time palyerItem:item];
    }];
}

-(void)pauseWithUrlString:(NSString *)urlString{
    
    if (![urlString isNotBlank]) {
        NSLog(@"暂停的音频链接不能为空!");
        return;
    }
    
    if (![_urlArray containsObject:urlString]) {
        NSLog(@"不存在该音频链接!");
        return;
    }
    
    if (![urlString isEqualToString:_currentAudioPlayingURLString]) {
        NSLog(@"暂停了一个未播放的音频!");
        return;
    }
    
    ///  记录暂停的时间
    PauseTimeModel *model = [[PauseTimeModel alloc] init];
    model.value = _audioPlayer.currentTime.value;
    model.timescale = _audioPlayer.currentTime.timescale;
    model.flags = _audioPlayer.currentTime.flags;
    model.epoch = _audioPlayer.currentTime.epoch;
    [_pauseTimeDict setObject:model forKey:urlString];
    
    ///  暂停
    [_audioPlayer pause];
    
    ///  改变状态并回调
    self.playerStatus = WTAudioPlayerStatusPause;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:audioURLString:)] && self.delegate) {
            [self.delegate audioPlayer:self.audioPlayer didChangedStatus:self.playerStatus audioURLString:self.currentAudioPlayingURLString];
        }
    });
    
    [self setAudioURLModelStatusWithString:urlString andStatus:WTAudioPlayerStatusPause];
    
    self.needResumePlay = NO;
}

-(void)resumeWithUrlString:(NSString *)urlString{
    
    if (![urlString isNotBlank]) {
        NSLog(@"续播的音频链接不能为空!");
        return;
    }
    
    if (![_urlArray containsObject:urlString]) {
        NSLog(@"续播了一个未播放的音频");
        return;
    }
    
    AVPlayerItem *item = (AVPlayerItem *)[_itemDict objectForKey:urlString];
    if (!item) {
        NSLog(@"续播了一个未播放的音频");
        return;
    }
    
    PauseTimeModel *mode = (PauseTimeModel *)[_pauseTimeDict objectForKey:urlString];
    if (!mode) {
        NSLog(@"该音频未暂停过");
        return;
    }
    
    ///  设置音频会话分类
    NSString *sessionCategory = AVAudioSessionCategoryPlayback;
    if ([self.delegate respondsToSelector:@selector(audioPlayerPreferAudioSessionCategoryWhenPlaying)] && self.delegate) {
        sessionCategory = [self.delegate audioPlayerPreferAudioSessionCategoryWhenPlaying];
    }
    [self audioSessionSetActive:YES setCategory:sessionCategory];
    
    ///  改变播放器状态,不用回调
    self.playerStatus = WTAudioPlayerStatusResume;
    
    ///  跳转到指定时间
    CMTime pauseTime = CMTimeMake(mode.value, mode.timescale);
    [_audioPlayer replaceCurrentItemWithPlayerItem:item];
    [_audioPlayer seekToTime:pauseTime completionHandler:^(BOOL finished) {
        [self.audioPlayer play];
    }];
    
    self.needResumePlay = YES;
    self.currentAudioPlayingURLString = urlString;
}

-(void)stopWithUrlString:(NSString *)urlString{
    
    if (![urlString isNotBlank]) {
        NSLog(@"停止播放的url不能为空");
        return;
    }
    
    if (![_urlArray containsObject:urlString]) {
        NSLog(@"停止了一个未播放过的音频");
        return;
    }
    
    ///  停止播放
    [_audioPlayer pause];
    
    /// 移除对AVPlayerItem的监听
    [self removeAVPlayerItemObserveWithItem:_audioPlayer.currentItem];
    
    ///  移除已经记录过得音频
    [self removeAudioRecorde:urlString];
    
    ///  操作此功能，应用再次被响应的时候，不会继续播放
    self.needResumePlay = NO;
    
    ///  改变状态并回调
    self.playerStatus = WTAudioPlayerStatusStop;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:audioURLString:)] && self.delegate) {
            [self.delegate audioPlayer:self.audioPlayer didChangedStatus:self.playerStatus audioURLString:self.currentAudioPlayingURLString];
        }
    });
    
    [self setAudioURLModelStatusWithString:urlString andStatus:WTAudioPlayerStatusStop];
    
    ///  停止检测
    if (self.timeObserve) {
        [self.audioPlayer removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
    }
    
    
}

///  移除已经记录过得音频
-(void)removeAudioRecorde:(NSString *)urlString{
    ///  移除url
    if ([_urlArray containsObject:urlString]) {
        [_urlArray removeObject:urlString];
    }
    
    ///  移除urlModel
    for(AudioURLModel *model in _urlModelArray){
        if ([model.audioURL isEqualToString:urlString]) {
            [_urlModelArray removeObject:model];
            break;
        }
    }
    
    ///  移除AVPlayerItem
    if ([_itemDict containsObjectForKey:urlString]) {
        [_itemDict removeObjectForKey:urlString];
    }
    
    ///  移除暂停时间
    if ([_pauseTimeDict containsObjectForKey:urlString]) {
        [_pauseTimeDict removeObjectForKey:urlString];
    }
}

///  根据class标示释放内存中对应的item-->一般用于实例
-(void)releaseAudioPlayerForClass:(Class)targetClass{
    
    [self.audioPlayer pause];
    
    ///  移除对应的类播放过的URL
    NSMutableArray <NSString *>*willRemoveArray = [NSMutableArray array];
    NSString *tagClassString = NSStringFromClass([targetClass class]);
    NSMutableArray <AudioURLModel *>*willStayModelArray = [NSMutableArray array];
    for(AudioURLModel *model in _urlModelArray){
        if ([model.tagClass isEqualToString:tagClassString]) {
            [willRemoveArray addObject:model.audioURL];
            [_urlArray removeObject:model.audioURL];
        }else{
            [willStayModelArray addObject:model];
        }
    }
    _urlModelArray = willStayModelArray;
    
    ///  移除对应的类暂停过的时间模型
    for(NSString *key in willRemoveArray){
        if ([_pauseTimeDict containsObjectForKey:key]) {
            [_pauseTimeDict removeObjectForKey:key];
        }
    }
    
    ///  移除对应的类播放过的AVPlayerItem
    for(NSString *key in willRemoveArray){
        if ([_itemDict containsObjectForKey:key]) {
            AVPlayerItem *item = _itemDict[key];
            [self removeAVPlayerItemObserveWithItem:item];
            [_itemDict removeObjectForKey:key];
        }
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.delegate = nil;
    
    if (_timeObserve) {
        [_audioPlayer removeTimeObserver:_timeObserve];
        _timeObserve = nil;
    }
    
}

///  根据class标示释放内存中对应的资源-->一般用于单例
-(void)clearSourceForClass:(Class)targetClass{
    
    ///  移除对应的类播放过的URL
    NSMutableArray <NSString *>*willRemoveArray = [NSMutableArray array];
    NSString *tagClassString = NSStringFromClass([targetClass class]);
    NSMutableArray <AudioURLModel *>*willStayModelArray = [NSMutableArray array];
    for(AudioURLModel *model in _urlModelArray){
        if ([model.tagClass isEqualToString:tagClassString]) {
            [willRemoveArray addObject:model.audioURL];
            [_urlArray removeObject:model.audioURL];
        }else{
            [willStayModelArray addObject:model];
        }
    }
    _urlModelArray = willStayModelArray;
    
    ///  移除对应的类暂停过的时间模型
    for(NSString *key in willRemoveArray){
        if ([_pauseTimeDict containsObjectForKey:key]) {
            [_pauseTimeDict removeObjectForKey:key];
        }
    }
    
    ///  移除对应的类播放过的AVPlayerItem
    for(NSString *key in willRemoveArray){
        if ([_itemDict containsObjectForKey:key]) {
            AVPlayerItem *item = _itemDict[key];
            [self removeAVPlayerItemObserveWithItem:item];
            [_itemDict removeObjectForKey:key];
        }
    }

}

///  获取播放资源的状态
-(WTAudioPlayerStatus)statusForURLString:(NSString *)urlString{
    WTAudioPlayerStatus result = WTAudioPlayerStatusUnknow;
    
    if (![_urlArray containsObject:urlString]) {
        NSLog(@"该资源已被释放，无法获取状态");
        return result;
    }
    
    for(AudioURLModel *model in _urlModelArray){
        if ([model.audioURL isEqualToString:urlString]) {
            result = model.status;
            break;
        }
    }
    return result;
}

/// 根据音频链接返回对应音频模型
-(AudioURLModel *)getAudioURLModelForAudioURLString:(NSString *)audioURLString{
    if (![audioURLString isNotBlank]) return nil;
    AudioURLModel *audioURLModel = nil;
    for(AudioURLModel *model in self.urlModelArray){
        if ([model.audioURL isEqualToString:audioURLString]) {
            audioURLModel = model;
            break;
        }
    }
    return audioURLModel;
}

///  设置播放器的音量
-(void)setPlayerVolume:(float)volume{
    [self.audioPlayer setVolume:volume];
}

-(float)playerVolume{
    return self.audioPlayer.volume;
}

#pragma mark 私有方法

///  设置音频模型的状态
-(void)setAudioURLModelStatusWithString:(NSString *)urlString andStatus:(WTAudioPlayerStatus)status{
    
    for(AudioURLModel *model in _urlModelArray){
        if ([model.audioURL isEqualToString:urlString]) {
            model.status = status;
            break;
        }
    }
}

-(WTAudioPlayerStatus)currentStatus{
    return self.playerStatus;
}

///  处理播放器的播放时间
-(void)resolvePlayerTime:(CMTime)time palyerItem:(AVPlayerItem *)item{
    
    double elapsedSeconds = CMTimeGetSeconds(time);
    double totalSeconds = CMTimeGetSeconds(item.asset.duration);
    
    if(totalSeconds == 0 || isnan(totalSeconds) || elapsedSeconds > totalSeconds){
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(audioPlayerURL:currentTime:forTotalSeconds:status:)] && self.delegate) {
            [self.delegate audioPlayerURL:_currentAudioPlayingURLString currentTime:elapsedSeconds forTotalSeconds:totalSeconds status:self.playerStatus];
        }
    });
    
}

///  重新播放
-(void)replayWithUrlString:(NSString *)urlString{
    
    AVPlayerItem *item = (AVPlayerItem *)[_itemDict objectForKey:urlString];
    [_audioPlayer replaceCurrentItemWithPlayerItem:item];
    __weak WTAudioPlayer *weakSelf = self;
    [_audioPlayer seekToTime:CMTimeMake(0, 1) completionHandler:^(BOOL finished) {
        [weakSelf.audioPlayer play];
        ///  改变状态并回调
        weakSelf.playerStatus = WTAudioPlayerStatusPlaying;
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([weakSelf.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:audioURLString:)] && weakSelf.delegate) {
                [weakSelf.delegate audioPlayer:weakSelf.audioPlayer didChangedStatus:weakSelf.playerStatus audioURLString:self.currentAudioPlayingURLString];
            }
        });
        [weakSelf setAudioURLModelStatusWithString:urlString andStatus:WTAudioPlayerStatusPlaying];
    }];
    
    [self addTimeObsrveToAudioPlayerWithItem:item];
    
    self.needResumePlay = YES;
    self.currentAudioPlayingURLString = urlString;
}

///  获取AVPlayerItem
-(AVPlayerItem *)playerItemWithUrlString:(NSString *)urlString isLocalFileURL:(BOOL)isLocalFile{
    NSURL *musicURL;
    if (isLocalFile) {
        musicURL = [NSURL fileURLWithPath:urlString];
    }else{
        ///  源网络链接转成本地服务器请求链接
        NSURL *originURL = [NSURL safeUrlWithString:urlString];
        musicURL = [KTVHTTPCache proxyURLWithOriginalURL:originURL];
    }
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:musicURL];
    [self registerAVPlayerItemObserveWithItem:item];
    return item;
}

-(void)audioSessionSetActive:(BOOL)active setCategory:(NSString *)category{
    [AVAudioSession.sharedInstance setActive:active error:nil];
    [AVAudioSession.sharedInstance setCategory:category withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:nil];
    if (![self isHeadsetPluggedIn]) {
        /// 未插入耳机
        [AVAudioSession.sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    }
}

/// 检测是否插入耳机，包括蓝牙耳机
- (BOOL)isHeadsetPluggedIn {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones] || [[desc portType] isEqualToString:AVAudioSessionPortBluetoothLE] || [[desc portType] isEqualToString:AVAudioSessionPortBluetoothHFP] || [[desc portType] isEqualToString:AVAudioSessionPortBluetoothA2DP])
            return YES;
    }
    return NO;
}

///  当前应用取消第一响应
-(void)applicationWillResignActive:(NSNotification *)notification{
    
    ///  设置音频会话分类
    NSString *audioCategory = AVAudioSessionCategoryPlayback;
    if ([self.delegate respondsToSelector:@selector(audioPlayerPreferAudioSessionCategoryWhenApplicationWillResignActive)] && self.delegate) {
        audioCategory = [self.delegate audioPlayerPreferAudioSessionCategoryWhenApplicationWillResignActive];
    }
    [self audioSessionSetActive:NO setCategory:audioCategory];
    
    ///  是否暂停
    BOOL shouldPause = YES;
    if ([self.delegate respondsToSelector:@selector(shouldPauseWhenApplicationWillResignActive:)] && self.delegate) {
        shouldPause = [self.delegate shouldPauseWhenApplicationWillResignActive:self.audioPlayer];
    }
    if (shouldPause && ((self.playerStatus == WTAudioPlayerStatusPlaying) || (self.playerStatus == WTAudioPlayerStatusResume)) && self.currentAudioPlayingURLString) {
        [self pauseWithUrlString:self.currentAudioPlayingURLString];
        self.needResumePlay = YES;
    }
}

///  当前应用进入后台
-(void)applicationDidEnterBackground:(NSNotification *)notification{
    
    ///  设置音频会话分类
    NSString *audioCategory = AVAudioSessionCategoryAmbient;
    if ([self.delegate respondsToSelector:@selector(audioPlayerPreferAudioSessionCategoryWhenApplicationWillResignActive)] && self.delegate) {
        audioCategory = [self.delegate audioPlayerPreferAudioSessionCategoryWhenApplicationWillResignActive];
    }
    [self audioSessionSetActive:NO setCategory:audioCategory];
    
    ///  是否暂停
    BOOL shouldPause = YES;
    if ([self.delegate respondsToSelector:@selector(shouldPauseWhenApplicationDidEnterBackground:)] && self.delegate) {
        shouldPause = [self.delegate shouldPauseWhenApplicationDidEnterBackground:self.audioPlayer];
    }
    if (shouldPause && ((self.playerStatus == WTAudioPlayerStatusPlaying) || (self.playerStatus == WTAudioPlayerStatusResume)) && self.currentAudioPlayingURLString) {
        [self pauseWithUrlString:self.currentAudioPlayingURLString];
        self.needResumePlay = YES;
    }
}

///  当前应用变成第一响应
-(void)applicationDidBecomeActive:(NSNotification *)notification{
    ///  系统内部判断
    if (!self.needResumePlay) {
        return;
    }
    
    BOOL shouldResume = YES;
    if ([self.delegate respondsToSelector:@selector(shouldResumeWhenApplicationDidBecomeActive:)] && self.delegate) {
        shouldResume = [self.delegate shouldResumeWhenApplicationDidBecomeActive:self.audioPlayer];
    }
    if (shouldResume && (self.playerStatus == WTAudioPlayerStatusPause) && self.currentAudioPlayingURLString) {
        [self resumeWithUrlString:self.currentAudioPlayingURLString];
    }
}

///  当前应用进入前台
-(void)applicationWillEnterForeground:(NSNotification *)notification{
    ///  系统内部判断
    if (!self.needResumePlay) {
        return;
    }
    
    BOOL shouldResume = YES;
    if ([self.delegate respondsToSelector:@selector(shouldResumeWhenApplicationWillEnterForeground:)] && self.delegate) {
        shouldResume = [self.delegate shouldResumeWhenApplicationWillEnterForeground:self.audioPlayer];
    }
    if (shouldResume && (self.playerStatus == WTAudioPlayerStatusPause) && self.currentAudioPlayingURLString) {
        [self resumeWithUrlString:self.currentAudioPlayingURLString];
    }
    
}

///  成功播放到结束
-(void)successPlayToEnd:(NSNotification *)notification{
    
    /// 设置播放进度
    double totalSeconds = CMTimeGetSeconds(self.audioPlayer.currentItem.asset.duration);
    if((totalSeconds != 0) && !isnan(totalSeconds)){
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(audioPlayerURL:currentTime:forTotalSeconds:status:)] && self.delegate) {
                [self.delegate audioPlayerURL:_currentAudioPlayingURLString currentTime:totalSeconds forTotalSeconds:totalSeconds status:self.playerStatus];
            }
        });
    }
    
    
    ///  是否循环播放
    BOOL autoPlay = NO;
    if ([self.delegate respondsToSelector:@selector(shouldAutoPlayAudio:forURLString:)] && self.delegate) {
        autoPlay = [self.delegate shouldAutoPlayAudio:_audioPlayer forURLString:_currentAudioPlayingURLString];
    }
    if (autoPlay) {
        ///  循环播放
        [self replayWithUrlString:self.currentAudioPlayingURLString];
    }else{
        ///  不循环播放
        
        ///  移除监听
        [self removeAVPlayerItemObserveWithItem:self.audioPlayer.currentItem];
        /// 移除记录
        [self removeAudioRecorde:self.currentAudioPlayingURLString];
        ///  状态改变 && 回调
        self.playerStatus = WTAudioPlayerStatusPlayToEnd;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ([self.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:audioURLString:)] && self.delegate) {
                [self.delegate audioPlayer:self.audioPlayer didChangedStatus:self.playerStatus audioURLString:self.currentAudioPlayingURLString];
            }
        });
        [self setAudioURLModelStatusWithString:self.currentAudioPlayingURLString andStatus:WTAudioPlayerStatusPlayToEnd];
        
        ///  播放完成回调
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if ([self.delegate respondsToSelector:@selector(audioPlayer:didFinishedPlayForURLString:)] && self.delegate) {
                [self.delegate audioPlayer:self.audioPlayer didFinishedPlayForURLString:self.currentAudioPlayingURLString];
            }
        });
        
        ///  操作此功能，应用再次被响应的时候，不会继续播放
        self.needResumePlay = NO;
    }
}

///  未能播放到结束
-(void)failedPlayToEnd:(NSNotification *)notification{
    ///  改变状态 && 回调
    self.playerStatus = WTAudioPlayerStatusPlayFailed;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:audioURLString:)] && self.delegate) {
            [self.delegate audioPlayer:self.audioPlayer didChangedStatus:self.playerStatus audioURLString:self.currentAudioPlayingURLString];
        }
    });
    
    [self setAudioURLModelStatusWithString:self.currentAudioPlayingURLString andStatus:WTAudioPlayerStatusPlayFailed];
}

///  播放到一半去缓存
-(void)interruptPlayToCache:(NSNotification *)notification{
    
    ///  改变状态 && 回调
    self.playerStatus = WTAudioPlayerStatusCaching;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:audioURLString:)] && self.delegate) {
            [self.delegate audioPlayer:self.audioPlayer didChangedStatus:self.playerStatus audioURLString:self.currentAudioPlayingURLString];
        }
    });
    [self setAudioURLModelStatusWithString:self.currentAudioPlayingURLString andStatus:WTAudioPlayerStatusCaching];
}

///  缓存失败，未能成功恢复播放
-(void)recoveryPlayError:(NSNotification *)notification{
    
    ///  改变状态 && 回调
    self.playerStatus = WTAudioPlayerStatusPlayFailed;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:audioURLString:)] && self.delegate) {
            [self.delegate audioPlayer:self.audioPlayer didChangedStatus:self.playerStatus audioURLString:self.currentAudioPlayingURLString];
        }
    });
    [self setAudioURLModelStatusWithString:self.currentAudioPlayingURLString andStatus:WTAudioPlayerStatusPlayFailed];
}

///  (AVPlayer有新的日志记录，会调用该方法，比如新的播放，暂停)缓存成功，恢复播放
-(void)recoveryPlaySuccess:(NSNotification *)notification{
    
    
    ///  记录系统缓存后重新恢复播放的日志
//    if ((self.playerStatus == WTAudioPlayerStatusCaching) && (self.didPlayAudio == YES)) {
    if (self.playerStatus == WTAudioPlayerStatusCaching) {
        
        [_audioPlayer play];
        self.playerStatus = WTAudioPlayerStatusPlaying;
        if ([self.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:audioURLString:)] && self.delegate) {
            [self.delegate audioPlayer:self.audioPlayer didChangedStatus:self.playerStatus audioURLString:self.currentAudioPlayingURLString];
        }
        [self setAudioURLModelStatusWithString:self.currentAudioPlayingURLString andStatus:WTAudioPlayerStatusPlaying];
    }
    
    ///  记录暂停之后再次续播后的日志
    if (self.playerStatus == WTAudioPlayerStatusResume) {
        self.playerStatus = WTAudioPlayerStatusPlaying;
        if ([self.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:audioURLString:)] && self.delegate) {
            [self.delegate audioPlayer:self.audioPlayer didChangedStatus:self.playerStatus audioURLString:self.currentAudioPlayingURLString];
        }
        [self setAudioURLModelStatusWithString:self.currentAudioPlayingURLString andStatus:WTAudioPlayerStatusPlaying];
    }
}

///  KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    AVPlayerItem *item = (AVPlayerItem *)object;
    
    ///  资源加载状态
    if ([keyPath isEqualToString:PlayerStatus]) {
        AVPlayerItemStatus status = item.status;
        switch (status) {
            case AVPlayerItemStatusUnknown:{
                self.playerStatus = WTAudioPlayerStatusUnknow;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:audioURLString:)] && self.delegate) {
                        [self.delegate audioPlayer:self.audioPlayer didChangedStatus:self.playerStatus audioURLString:self.currentAudioPlayingURLString];
                    }
                });
                [self setAudioURLModelStatusWithString:self.currentAudioPlayingURLString andStatus:WTAudioPlayerStatusUnknow];
                
                break;
            }
                
            case AVPlayerItemStatusReadyToPlay:{
                if (self.playerStatus == WTAudioPlayerStatusCaching) {
                    
                    NSString *sessionCategory = AVAudioSessionCategoryPlayback;
                    if ([self.delegate respondsToSelector:@selector(audioPlayerPreferAudioSessionCategoryWhenPlaying)] && self.delegate) {
                        sessionCategory = [self.delegate audioPlayerPreferAudioSessionCategoryWhenPlaying];
                    }
                    [self audioSessionSetActive:YES setCategory:sessionCategory];
                    
                    [_audioPlayer play];
//                    self.didPlayAudio = YES;
                    
//                    self.playerStatus = WTAudioPlayerStatusPlaying;
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        if ([self.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:)] && self.delegate) {
//                            [self.delegate audioPlayer:self.audioPlayer didChangedStatus:self.playerStatus];
//                        }
//                    });
                    
                    [self setAudioURLModelStatusWithString:self.currentAudioPlayingURLString andStatus:WTAudioPlayerStatusPlaying];
                }
                break;
            }
                
            case AVPlayerItemStatusFailed:{
                self.playerStatus = WTAudioPlayerStatusPlayFailed;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(audioPlayer:didChangedStatus:audioURLString:)] && self.delegate) {
                        [self.delegate audioPlayer:self.audioPlayer didChangedStatus:self.playerStatus audioURLString:self.currentAudioPlayingURLString];
                    }
                });
                [self setAudioURLModelStatusWithString:self.currentAudioPlayingURLString andStatus:WTAudioPlayerStatusPlayFailed];
                break;
            }
                
            default:
                break;
        }
    }
    
    ///  资源加载进度
    if ([keyPath isEqualToString:PlayerLoadedStatus]) {
        
        NSTimeInterval loadedTime = [self availableDurationWithplayerItem:item];
        NSTimeInterval totalTime = CMTimeGetSeconds(item.duration);
        if ([self.delegate respondsToSelector:@selector(audioPlayer:didLoadedTime:totalTime:)] && self.delegate) {
            [self.delegate audioPlayer:self.audioPlayer didLoadedTime:loadedTime totalTime:totalTime];
        }
        
    }
    
}

/// 获取缓冲进度
- (NSTimeInterval)availableDurationWithplayerItem:(AVPlayerItem *)playerItem {
    
    NSArray * loadedTimeRanges = [playerItem loadedTimeRanges];
    /// 获取缓冲区域
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
    NSTimeInterval startSeconds = CMTimeGetSeconds(timeRange.start);
    NSTimeInterval durationSeconds = CMTimeGetSeconds(timeRange.duration);
    /// 计算缓冲总进度
    NSTimeInterval result = startSeconds + durationSeconds;
    
    return result;
}

-(void)dealloc{
    
    [self.audioPlayer pause];
    [_urlArray removeAllObjects];
    [_urlModelArray removeAllObjects];
    for(NSString *key in _pauseTimeDict.allKeys){
        [_pauseTimeDict removeObjectForKey:key];
    }
    for(NSString *key in _itemDict.allKeys){
        AVPlayerItem *item = _itemDict[key];
        [self removeAVPlayerItemObserveWithItem:item];
        [_itemDict removeObjectForKey:key];
    }
    if (_timeObserve) {
        [_audioPlayer removeTimeObserver:_timeObserve];
        _timeObserve = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.delegate = nil;
    
    NSLog(@"");
}
@end
