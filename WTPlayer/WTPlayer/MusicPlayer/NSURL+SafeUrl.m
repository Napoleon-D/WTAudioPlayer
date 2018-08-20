//
//  NSURL+SafeUrl.m
//  WTAudioPlayer
//
//  Created by Tommy on 2018/5/11.
//  Copyright © 2018年 Tommy. All rights reserved.
//

#import "NSURL+SafeUrl.h"

@implementation NSURL (SafeUrl)

+(NSURL *)safeUrlWithString:(NSString *)urlStr{
    return [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}


@end
