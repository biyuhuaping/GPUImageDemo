//
//  LZVideoTailoringVC.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/23.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZVideoTailoringVC.h"
#import "SAVideoRangeSlider.h"
#import "LZPlayerView.h"
#import "LZVideoTools.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface LZVideoTailoringVC ()<SAVideoRangeSliderDelegate>
@property (strong, nonatomic) LZSessionSegment *segment;

@property (strong, nonatomic) IBOutlet LZPlayerView *playerView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet SAVideoRangeSlider *trimmerView;     //微调视图
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;//计时显示

@property (strong, nonatomic) id timeObser;
@property (strong, nonatomic) NSMutableArray *recordSegments;

@end

@implementation LZVideoTailoringVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.recordSegments = [NSMutableArray arrayWithArray:self.recordSession.segments];
    self.segment = self.recordSession.segments[self.currentSelected];
    
    [self.trimmerView getMovieFrameWithAsset:self.segment.asset];
    self.trimmerView.delegate = self;
    
    self.segment.endTime = CMTimeGetSeconds(self.segment.duration);
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playOrPause)];
    [self.playerView addGestureRecognizer:tap];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.segment.asset];
    self.playerView.player = [AVPlayer playerWithPlayerItem:item];
    
    WS(weakSelf);
    self.timeObser = [self.playerView.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        double current = CMTimeGetSeconds(time);
        if (current >= weakSelf.segment.endTime) {
            [weakSelf.playerView.player pause];
            weakSelf.imageView.hidden = NO;
        }
    }];
    

    [self configNavigationBar];
    [self configTimeLabel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - configViews
//配置navi
- (void)configNavigationBar{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    button.selected = NO;
    [button setTitle:@"提交" forState:UIControlStateNormal];
    [button setTitleColor:UIColorFromRGB(0xffffff, 1) forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectMake(0, 0, CGRectGetWidth(button.bounds), 40);
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
    [button addTarget:self action:@selector(navbarRightButtonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:button];
}

- (void)configTimeLabel{
    self.timeLabel.layer.masksToBounds = YES;
    self.timeLabel.layer.cornerRadius = 10;
    
    CGFloat durationSeconds = CMTimeGetSeconds(self.segment.asset.duration);
    int seconds = lround(durationSeconds) % 60;
    int minutes = (lround(durationSeconds) / 60) % 60;
    self.timeLabel.text = [NSString stringWithFormat:@" %02d:%02d ", minutes, seconds];
}

#pragma mark - Event
- (void)navbarRightButtonClickAction:(UIButton*)sender {
    [self cutVideo];
}

- (void)cutVideo {
    NSURL *tempPath = self.segment.url;
    [LZVideoTools removeFileAtPath:[tempPath absoluteString]];
    
    [self.recordSession removeAllSegments:NO];

    CMTime start = CMTimeMakeWithSeconds(self.segment.startTime, self.segment.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(self.segment.endTime - self.segment.startTime, self.segment.duration.timescale);
    CMTimeRange range = CMTimeRangeMake(start, duration);
    
    [LZVideoTools exportVideo:self.segment.asset videoComposition:nil filePath:tempPath timeRange:range completion:^(NSURL *savedPath) {
        if(savedPath) {
            DLog(@"导出视频路径：%@", savedPath);
            LZSessionSegment * newSegment = [LZSessionSegment segmentWithURL:tempPath filter:self.segment.filter];
            [self.recordSegments removeObject:self.segment];
            [self.recordSegments insertObject:newSegment atIndex:self.currentSelected];
            
            for (int i = 0; i < self.recordSegments.count; i++) {
                LZSessionSegment * segment = self.recordSegments[i];
                NSAssert(segment.url != nil, @"segment url must be non-nil");
                if (segment.url != nil) {
                    [self.recordSession insertSegment:segment atIndex:i];
                }
            }
            
            [self.navigationController popViewControllerAnimated:YES];
        }
        else {
            DLog(@"导出视频路径出错：%@", savedPath);
        }
    }];
}

//播放或暂停
- (void)playOrPause{
    if (!(self.playerView.player.rate > 0)) {
        CMTime time = CMTimeMakeWithSeconds(self.segment.startTime, self.segment.asset.duration.timescale);
        [self.playerView.player seekToTime:time];
        [self.playerView.player play];
        _imageView.hidden = YES;
    }else{
        [self.playerView.player pause];
        _imageView.hidden = NO;
    }
}

#pragma mark - SAVideoRangeSliderDelegate
- (void)videoRange:(SAVideoRangeSlider *)videoRange isLeft:(BOOL)isLeft didChangeLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition
{
    [self.playerView.player pause];
    self.imageView.hidden = NO;
    self.segment.startTime = leftPosition;
    self.segment.endTime = rightPosition;
    
    CGFloat durationSeconds = rightPosition - leftPosition;
    self.timeLabel.text = [NSString stringWithFormat:@" 00:%02ld ", lround(durationSeconds)];
    
    //控制快进，后退
    double f = isLeft?leftPosition:rightPosition;
    CMTime time = CMTimeMakeWithSeconds(f, self.segment.asset.duration.timescale);
    [self.playerView.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)dealloc{
    [self.playerView.player removeTimeObserver:self.timeObser];
}

@end
