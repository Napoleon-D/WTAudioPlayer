//
//  Header.h
//  BiBiClick
//
//  Created by Tommy on 2018/6/14.
//  Copyright © 2018年 hbtime. All rights reserved.
//

#ifndef Header_h
#define Header_h

#import <YYCategories/YYCategories.h>
#import "NSURL+SafeUrl.h"

typedef NS_ENUM(NSInteger,WTAudioPlayerStatus) {
    WTAudioPlayerStatusUnknow = -1,
    WTAudioPlayerStatusCaching,
    WTAudioPlayerStatusPlaying,
    WTAudioPlayerStatusPause,
    WTAudioPlayerStatusStop,
    WTAudioPlayerStatusPlayToEnd,
    WTAudioPlayerStatusPlayFailed,
    WTAudioPlayerStatusResume
};



#endif /* Header_h */
