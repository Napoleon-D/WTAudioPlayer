//
//  NSURL+SafeUrl.h
//  WTAudioPlayer
//
//  Created by Tommy on 2018/5/11.
//  Copyright © 2018年 Tommy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (SafeUrl)

+(NSURL *)safeUrlWithString:(NSString *)urlStr;

@end
