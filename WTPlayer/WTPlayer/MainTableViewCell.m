//
//  MainTableViewCell.m
//  WTPlayer
//
//  Created by Tommy on 2018/6/7.
//  Copyright © 2018年 Tommy. All rights reserved.
//

#define KSCREENWIDTH [UIScreen mainScreen].bounds.size.width

#import "MainTableViewCell.h"
#import "WTAudioPlayer.h"

@interface MainTableViewCell()<WTAudioPlayerDelegate>

@property(nonatomic,strong)UILabel *nameLabel;
@property(nonatomic,strong)UIButton *playBtn;
@property(nonatomic,strong)UIButton *pauseBtn;
@property(nonatomic,strong)UIButton *stopBtn;

@end

@implementation MainTableViewCell

+(MainTableViewCell *)mainTableViewCellWithTableView:(UITableView *)tableView{
    static NSString *identifer = @"MainTableViewCell";
    MainTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifer];
    if (!cell) {
        cell = [[MainTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifer];
    }
    return cell;
}

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:self.playBtn];
        [self.contentView addSubview:self.pauseBtn];
        [self.contentView addSubview:self.stopBtn];
        [self.contentView addSubview:self.nameLabel];
        [WTAudioPlayer sharedAudioPlayer].delegate = self;
    }
    return self;
}

- (UIButton *)playBtn{
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playBtn.frame = CGRectMake(KSCREENWIDTH-44-15, 0, 44, 44);
        [_playBtn setTitle:@"播放" forState:UIControlStateNormal];
        [_playBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_playBtn setBackgroundColor:[UIColor whiteColor]];
        [_playBtn addTarget:self action:@selector(playBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (UIButton *)pauseBtn{
    if (!_pauseBtn) {
        _pauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _pauseBtn.frame = CGRectMake(KSCREENWIDTH-44*2-15, 0, 44, 44);
        [_pauseBtn setTitle:@"暂停" forState:UIControlStateNormal];
        [_pauseBtn setTitle:@"继续" forState:UIControlStateSelected];
        [_pauseBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_pauseBtn setBackgroundColor:[UIColor whiteColor]];
        [_pauseBtn addTarget:self action:@selector(pauseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pauseBtn;
}

- (UIButton *)stopBtn{
    if (!_stopBtn) {
        _stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _stopBtn.frame = CGRectMake(KSCREENWIDTH-44*3-15, 0, 44, 44);
        [_stopBtn setTitle:@"停止" forState:UIControlStateNormal];
        [_stopBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_stopBtn setBackgroundColor:[UIColor whiteColor]];
        [_stopBtn addTarget:self action:@selector(stopBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _stopBtn;
}

- (UILabel *)nameLabel{
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetMinX(self.stopBtn.frame), 44)];
        _nameLabel.textColor = [UIColor blackColor];
        _nameLabel.backgroundColor = [UIColor whiteColor];
        _nameLabel.textAlignment = NSTextAlignmentRight;
        _nameLabel.font = [UIFont systemFontOfSize:13];
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingHead;
    }
    return _nameLabel;
}

-(void)setMusicURLStr:(NSString *)musicURLStr{
    _musicURLStr = musicURLStr;
    _nameLabel.text = musicURLStr;
}

-(void)playBtnClicked:(UIButton *)sender{
    if (_musicURLStr) {
        [[WTAudioPlayer sharedAudioPlayer] playWithUrlString:_musicURLStr isLocalFileURL:NO forClass:[self class]];
    }
}

-(void)pauseBtnClicked:(UIButton *)sender{
    if (sender.selected) {
        ///  继续播放
        [[WTAudioPlayer sharedAudioPlayer] resumeWithUrlString:_musicURLStr];
    }else{
        ///  暂停播放
        [[WTAudioPlayer sharedAudioPlayer] pauseWithUrlString:_musicURLStr];
    }
    sender.selected = !sender.selected;
}

-(void)stopBtnClicked:(UIButton *)sender{
    if (_musicURLStr) {
        [[WTAudioPlayer sharedAudioPlayer] stopWithUrlString:_musicURLStr];
    }
}


- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

#pragma mark WTAudioPlayerDelegate

-(void)audioPlayer:(AVPlayer *)player didChangedStatus:(WTAudioPlayerStatus)playerStatus{
    switch (playerStatus) {
        case -1:{
            NSLog(@"WTAudioPlayerStatusUnknow");
            break;
        }
        case 0:{
            NSLog(@"WTAudioPlayerStatusCaching");
            break;
        }
        case 1:{
            NSLog(@"WTAudioPlayerStatusPlaying");
            break;
        }
        case 2:{
            NSLog(@"WTAudioPlayerStatusPause");
            break;
        }
        case 3:{
            NSLog(@"WTAudioPlayerStatusStop");
            break;
        }
        case 4:{
            NSLog(@"WTAudioPlayerStatusPlayToEnd");
            break;
        }
        case 5:{
            NSLog(@"WTAudioPlayerStatusPlayFailed");
            break;
        }
            
        default:
            break;
    }
}

-(void)audioPlayerURL:(NSString *)urlStr currentTime:(double)currentSeconds forTotalSeconds:(double)totalSeconds{
    NSLog(@"当前播放音频链接:%@",urlStr);
    NSLog(@"当前时间:%d",(int)currentSeconds);
    NSLog(@"总时间:%d",(int)totalSeconds);
}


@end
