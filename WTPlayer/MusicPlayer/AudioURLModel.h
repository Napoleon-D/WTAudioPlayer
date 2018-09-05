//
//  AudioURLModel.h
//  BiBiClick
//
//  Created by Tommy on 2018/6/14.
//  Copyright © 2018年 hbtime. All rights reserved.
//

#import "Header.h"

@interface AudioURLModel : NSObject

@property(nonatomic,copy)NSString *audioURL;
///  用来标记该URL在当前的哪个class中用到过
@property(nonatomic,copy)NSString *tagClass;
///  是否是本地连接
@property(nonatomic,assign)BOOL isLocalFile;
///  每个链接的状态
@property(nonatomic,assign)WTAudioPlayerStatus status;

@end
