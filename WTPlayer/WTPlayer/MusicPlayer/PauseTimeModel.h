//
//  PauseTimeModel.h
//  WTPlayer
//
//  Created by Tommy on 2018/6/8.
//  Copyright © 2018年 Tommy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface PauseTimeModel : NSObject

@property(nonatomic,assign)CMTimeValue value;
@property(nonatomic,assign)CMTimeScale timescale;
@property(nonatomic,assign)CMTimeFlags flags;
@property(nonatomic,assign)CMTimeEpoch epoch;

@end
