//
//  MainTableViewCell.h
//  WTPlayer
//
//  Created by Tommy on 2018/6/7.
//  Copyright © 2018年 Tommy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainTableViewCell : UITableViewCell

@property(nonatomic,copy)NSString *musicURLStr;

+(MainTableViewCell *)mainTableViewCellWithTableView:(UITableView *)tableView;

@end
