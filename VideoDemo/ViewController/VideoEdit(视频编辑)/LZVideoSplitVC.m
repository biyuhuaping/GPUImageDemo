//
//  LZVideoSplitVC.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/26.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//  视频分割

#import "LZVideoSplitVC.h"
#import "LZVideoTailoringVC.h"
#import "LZVideoCropperSlider.h"
#import "LZPlayerView.h"
#import "LZVideoTools.h"

@interface LZVideoSplitVC ()<LZVideoCropperSliderDelegate>
@property (strong, nonatomic) LZSessionSegment *segment;

@property (strong, nonatomic) IBOutlet LZPlayerView *playerView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet LZVideoCropperSlider *trimmerView;     //微调视图

@property (strong, nonatomic) id timeObser;
@property (strong, nonatomic) NSMutableArray *recordSegments;

@end

@implementation LZVideoSplitVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.recordSegments = [NSMutableArray arrayWithArray:self.recordSession.segments];
    self.segment = self.recordSession.segments[self.currentSelected];
    
    [self.trimmerView getMovieFrameWithAsset:self.segment.asset];
    self.trimmerView.delegate = self;
    
    self.segment.startTime = 0.00;
    self.segment.endTime = CMTimeGetSeconds(self.segment.duration)/2;

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

#pragma mark - Event
//保存
- (void)navbarRightButtonClickAction:(UIButton*)sender {
    [self cutVideo];
}

- (void)cutVideo {
    NSURL *tempPath = self.segment.url;
    NSString *filename = [LZVideoTools getFileName:[tempPath absoluteString]];
    [self.recordSession removeAllSegments:NO];
    
    dispatch_group_t serviceGroup = dispatch_group_create();
    for (int i = 0; i < 2; i++) {
        tempPath = [LZVideoTools filePathWithFileName:[NSString stringWithFormat:@"%@-%d.m4v", filename,i] isFilter:YES];

        if (i == 1) {
            self.segment.startTime = self.segment.endTime;
            self.segment.endTime = CMTimeGetSeconds(self.segment.duration);
        }
        CMTime start = CMTimeMakeWithSeconds(self.segment.startTime, self.segment.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(self.segment.endTime - self.segment.startTime, self.segment.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        
        dispatch_group_enter(serviceGroup);
        [LZVideoTools exportVideo:self.segment.asset videoComposition:nil filePath:tempPath timeRange:range completion:^(NSURL *savedPath) {
            if(savedPath) {
                DLog(@"导出视频路径：%@", savedPath);
                LZSessionSegment * newSegment = [LZSessionSegment segmentWithURL:tempPath filter:self.segment.filter];
                [self.recordSegments removeObject:self.segment];
                [self.recordSegments insertObject:newSegment atIndex:self.currentSelected + i];
            }
            dispatch_group_leave(serviceGroup);
        }];
    }
    
    
    dispatch_group_notify(serviceGroup, dispatch_get_main_queue(),^{
        for (int i = 0; i < self.recordSegments.count; i++) {
            LZSessionSegment * segment = self.recordSegments[i];
            NSAssert(segment.url != nil, @"segment url must be non-nil");
            if (segment.url != nil) {
                [self.recordSession insertSegment:segment atIndex:i];
            }
        }
        
        [self.navigationController popViewControllerAnimated:YES];
    });
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
- (void)videoRange:(LZVideoCropperSlider *)videoRange didChangePosition:(CGFloat)position{
    [self.playerView.player pause];
    self.imageView.hidden = NO;
    self.segment.endTime = position;
    
    //控制快进，后退
    CMTime time = CMTimeMakeWithSeconds(position, self.segment.asset.duration.timescale);
    [self.playerView.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)dealloc{
    [self.playerView.player removeTimeObserver:self.timeObser];
}

@end
