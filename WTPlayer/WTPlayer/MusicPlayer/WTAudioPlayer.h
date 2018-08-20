//
//  WTAudioPlayer.h
//  WTPlayer
//
//  Created by Tommy on 2018/6/7.
//  Copyright © 2018年 Tommy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Header.h"
@class AudioURLModel;

@protocol WTAudioPlayerDelegate<NSObject>

@optional
///  当前应用取消第一响应
-(BOOL)shouldPauseWhenApplicationWillResignActive:(AVPlayer *)audioPlayer;

///  当前应用取消第一响应状态下音频会话的分类，默认是AVAudioSessionCategoryPlayback
-(NSString *)audioPlayerPreferAudioSessionCategoryWhenApplicationWillResignActive;

///  当前应用进入后台
-(BOOL)shouldPauseWhenApplicationDidEnterBackground:(AVPlayer *)audioPlayer;

///  当前应用进入后台状态下音频会话的分类，默认是AVAudioSessionCategoryAmbient
-(NSString *)audioPlayerPreferAudioSessionCategoryWhenApplicationDidEnterBackground;

///  当前应用变成第一响应
-(BOOL)shouldResumeWhenApplicationDidBecomeActive:(AVPlayer *)audioPlayer;

///  当前应用进入前台
-(BOOL)shouldResumeWhenApplicationWillEnterForeground:(AVPlayer *)audioPlayer;

///  播放状态下音频会话的分类，默认是AVAudioSessionCategoryPlayback
-(NSString *)audioPlayerPreferAudioSessionCategoryWhenPlaying;

///  播放器状态改变时候的回调
-(void)audioPlayer:(AVPlayer *)player didChangedStatus:(WTAudioPlayerStatus)playerStatus audioURLString:(NSString *)audioURLString;

///  播放器缓冲的进度
-(void)audioPlayer:(AVPlayer *)player didLoadedTime:(NSTimeInterval)didLoadedTime totalTime:(NSTimeInterval)totalTime;

///  是否循环播放,默认不循环
-(BOOL)shouldAutoPlayAudio:(AVPlayer *)palyer forURLString:(NSString *)urlString;

/**
 播放器的播放进度,1秒调用一次

 @param urlStr 当前播放的URL
 @param currentSeconds 单位是秒
 @param totalSeconds 单位是秒
 @param status 播放器当前状态
 */
-(void)audioPlayerURL:(NSString *)urlStr currentTime:(double)currentSeconds forTotalSeconds:(double)totalSeconds status:(WTAudioPlayerStatus)status;

///  播放完成
-(void)audioPlayer:(AVPlayer *)audioPlayer didFinishedPlayForURLString:(NSString *)urlString;

@end

@interface WTAudioPlayer : NSObject

@property(nonatomic,assign)id<WTAudioPlayerDelegate>delegate;

///  播放器的状态
@property(nonatomic,assign,readonly)WTAudioPlayerStatus currentStatus;

/// 播放器的音量
@property(nonatomic,assign,readonly)float playerVolume;

///  单例
+(WTAudioPlayer *)sharedAudioPlayer;

///  实例
+(WTAudioPlayer *)audioPlayer;

///  播放
-(void)playWithUrlString:(NSString *)urlString isLocalFileURL:(BOOL)isLocalFile forClass:(Class)targetClass;

///  暂停
-(void)pauseWithUrlString:(NSString *)urlString;

///  继续播放
-(void)resumeWithUrlString:(NSString *)urlString;

///  停止
-(void)stopWithUrlString:(NSString *)urlString;

///  根据class标示释放内存中对应的item-->一般用于实例
-(void)releaseAudioPlayerForClass:(Class)targetClass;

///  根据class标示释放内存中对应的资源-->一般用于单例
-(void)clearSourceForClass:(Class)targetClass;

///  获取播放资源的状态
-(WTAudioPlayerStatus)statusForURLString:(NSString *)urlString;

/// 根据音频链接返回对应音频模型
-(AudioURLModel *)getAudioURLModelForAudioURLString:(NSString *)audioURLString;

///  设置播放器的音量
-(void)setPlayerVolume:(float)volume;

@end
