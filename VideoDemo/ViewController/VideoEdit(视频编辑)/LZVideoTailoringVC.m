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

@interface LZVideoTailoringVC ()<SAVideoRangeSliderDelegate>

@property (strong, nonatomic) IBOutlet GPUImageView *gpuImageView;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) LZSessionSegment *segment;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) id timeObser;


@property (strong, nonatomic) IBOutlet SAVideoRangeSlider *trimmerView;     //微调视图
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;//计时显示

@end

@implementation LZVideoTailoringVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LZLocalizedString(@"edit_video", nil);
    self.segment = self.recordSegments[self.currentSelected];

    [self.trimmerView performSelectorInBackground:@selector(getMovieFrameWithAsset:) withObject:self.segment.asset];
    self.trimmerView.delegate = self;
    
    [self configNavigationBar];
    [self configPlayerView];
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

- (void)configPlayerView{    
//    AVPlayerItem *playerItem = [LZVideoTools videoFadeOut:self.segment];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithURL:self.segment.url];
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    self.player.volume = self.segment.isMute?0:1;
    [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
    
    GPUImageMovie *movieFile = [[GPUImageMovie alloc] initWithPlayerItem:playerItem];
    movieFile.playAtActualSpeed = YES;
    
    GPUImageOutput<GPUImageInput> *filter = [[GPUImageFilter alloc] init];//原图
    [filter addTarget:self.gpuImageView];
    [movieFile addTarget:filter];
    [movieFile startProcessing];
    
    WS(weakSelf);
    self.timeObser = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        double current = CMTimeGetSeconds(time);
        double total = CMTimeGetSeconds(weakSelf.segment.asset.duration);
        if (current >= total) {
            CMTime time = CMTimeMakeWithSeconds(weakSelf.segment.startTime, weakSelf.segment.duration.timescale);
            [weakSelf.player seekToTime:time];
            [weakSelf.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
        }
    }];
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
//    [self cutVideo];
    [self saveCutVideo];
}

- (void)cutVideo {
//    NSURL *tempPath = self.segment.url;
//    NSString *filename = [LZVideoTools getFileName:[tempPath absoluteString]];
//    tempPath = [LZVideoTools filePathWithFileName:[NSString stringWithFormat:@"%@.m4v", filename] isFilter:YES];
    NSURL *tempPath = [LZVideoTools filePathWithFilter:YES];
    CMTime start = CMTimeMakeWithSeconds(self.segment.startTime, self.segment.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(self.segment.endTime - self.segment.startTime, self.segment.duration.timescale);
    CMTimeRange range = CMTimeRangeMake(start, duration);
    
    [LZVideoTools exportVideo:self.segment.asset videoComposition:nil filePath:tempPath timeRange:range completion:^(NSURL *savedPath) {
        if(savedPath) {
            DLog(@"导出视频路径：%@", savedPath);
            LZSessionSegment * newSegment = [LZSessionSegment segmentWithURL:savedPath filter:self.segment.filter];
            [self.recordSession replaceSegmentsAtIndex:self.currentSelected withSegment:newSegment];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

//保存
- (void)saveCutVideo {
    [self.recordSegments removeObjectAtIndex:self.currentSelected];
    [self.recordSegments insertObject:self.segment atIndex:self.currentSelected];
    
    WS(weakSelf);
    dispatch_group_t serviceGroup = dispatch_group_create();
    for (int i = 0; i < weakSelf.recordSegments.count; i++) {
        LZSessionSegment * segment = weakSelf.recordSegments[i];
        NSString *filename = [NSString stringWithFormat:@"Video-%ld.m4v", (long)i];
        NSURL *tempPath = [LZVideoTools filePathWithFileName:filename isFilter:YES];
        
        CMTime start = CMTimeMakeWithSeconds(segment.startTime, segment.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(segment.endTime - segment.startTime, segment.asset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        
        dispatch_group_enter(serviceGroup);
        [LZVideoTools exportVideo:segment.asset videoComposition:nil filePath:tempPath timeRange:range completion:^(NSURL *savedPath) {
            LZSessionSegment * newSegment = [[LZSessionSegment alloc] initWithURL:tempPath filter:nil];
            DLog(@"url:%@", [tempPath path]);
            [weakSelf.recordSegments removeObject:segment];
            [weakSelf.recordSegments insertObject:newSegment atIndex:i];
            dispatch_group_leave(serviceGroup);
        }];
    }
    
    dispatch_group_notify(serviceGroup, dispatch_get_main_queue(),^{
        [self.recordSession removeAllSegments:NO];
        for (int i = 0; i < weakSelf.recordSegments.count; i++) {
            LZSessionSegment * segment = weakSelf.recordSegments[i];
            NSAssert(segment.url != nil, @"segment url must be non-nil");
            if (segment.url != nil) {
                [weakSelf.recordSession insertSegment:segment atIndex:i];
            }
        }
        [weakSelf.navigationController popViewControllerAnimated:YES];
    });
}

//播放或暂停
- (IBAction)playOrPause{
    if (!(self.player.rate > 0)) {
        [self.player play];
        [self.playButton setImage:nil forState:UIControlStateNormal];
    }else{
        [self.player pause];
        [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
    }
}

#pragma mark - SAVideoRangeSliderDelegate
- (void)videoRange:(SAVideoRangeSlider *)videoRange isLeft:(BOOL)isLeft didChangeLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition
{
    [self.player pause];
    [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
    self.segment.startTime = leftPosition;
    self.segment.endTime = rightPosition;
    
    CGFloat durationSeconds = rightPosition - leftPosition;
    self.timeLabel.text = [NSString stringWithFormat:@" 00:%02ld ", lround(durationSeconds)];
    
    //控制快进，后退
    double f = isLeft?leftPosition:rightPosition;
    CMTime time = CMTimeMakeWithSeconds(f, self.segment.asset.duration.timescale);
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)dealloc{
    [self.player removeTimeObserver:self.timeObser];
    DLog(@"========= dealloc =========");
}

@end
