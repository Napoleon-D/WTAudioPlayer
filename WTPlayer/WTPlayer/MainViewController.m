//
//  ViewController.m
//  WTPlayer
//
//  Created by Tommy on 2018/5/28.
//  Copyright © 2018年 Tommy. All rights reserved.
//
#define PlayerStatus @"status"
#define PlayerLoadedStatus @"loadedTimeRanges"

#import "MainViewController.h"
#import "MainTableViewCell.h"
#import <AVFoundation/AVFoundation.h>
#import <KTVHTTPCache/KTVHTTPCache.h>
#import "NSURL+SafeUrl.h"

@interface MainViewController ()<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,copy)NSArray *musicArray;

@property(nonatomic,strong)UITableView *mainTableView;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"主页";

    _musicArray = @[
                            @"http://hbpic-10057247.file.myqcloud.com/music/f84faa27ad9391abd5f7207cb5c03f0e.mp3",
                            @"http://hbpic-10057247.file.myqcloud.com/music/2afbeef8d03af608e2c6e2dffd807062.mp3",
                            @"http://hbpic-10057247.file.myqcloud.com/music/8888ae5782e4eeeb3141359f8ee2fe88.mp3",
                            @"http://hbpic-10057247.file.myqcloud.com/music/857f1ef5deb1c7439bc87f55a77ee250.mp3",
                            @"http://hbpic-10057247.file.myqcloud.com/music/30b2864a895bdeeada7513a3120ebb7a.mp3",
                            @"http://hbpic-10057247.file.myqcloud.com/music/cfc34f2d9c56745104a311ef697f10e4.mp3",
                            @"http://hbpic-10057247.file.myqcloud.com/music/da5c16951879e94234a28475832cb045.mp3",
                            @"http://hbpic-10057247.file.myqcloud.com/music/7f38f14ecf263d2805971e097828ea49.mp3",
                            @"http://hbpic-10057247.file.myqcloud.com/music/dc2c569025378ad7bb9686d0b719b0ae.mp3",
                            @"http://hbpic-10057247.file.myqcloud.com/music/5a3037e541534a14638cc629de20f013.mp3",
                            @"http://hbpic-10057247.file.myqcloud.com/music/dddb9afe0234bca6849c2d5af7516518.mp3"];
    
    [self.view addSubview:self.mainTableView];
}


- (UITableView *)mainTableView{
    if (!_mainTableView) {
        _mainTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-64) style:UITableViewStylePlain];
        _mainTableView.dataSource = self;
        _mainTableView.delegate = self;
    }
    return _mainTableView;
}

#pragma mark UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _musicArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    MainTableViewCell *cell = [MainTableViewCell mainTableViewCellWithTableView:tableView];
    cell.musicURLStr = _musicArray[indexPath.row];
    return cell;
}

#pragma mark UITableViewDelegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44.0f;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
