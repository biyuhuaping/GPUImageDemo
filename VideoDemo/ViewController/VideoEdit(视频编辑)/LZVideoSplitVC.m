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

@property (strong, nonatomic) IBOutlet GPUImageView *gpuImageView;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) LZSessionSegment *segment;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) id timeObser;

@property (strong, nonatomic) IBOutlet LZVideoCropperSlider *trimmerView;     //微调视图

@end

@implementation LZVideoSplitVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LZLocalizedString(@"edit_video", nil);
    self.segment = self.recordSegments[self.currentSelected];
    
    [self.trimmerView performSelectorInBackground:@selector(getMovieFrameWithAsset:) withObject:self.segment.asset];
    self.trimmerView.delegate = self;
    
    [self configNavigationBar];
    [self configPlayerView];
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

#pragma mark - Event
//保存
- (void)navbarRightButtonClickAction:(UIButton*)sender {
    [self cutVideo];
    
//    [self.recordSegments removeObjectAtIndex:self.currentSelected];
//    [self.recordSegments insertObject:self.segment atIndex:self.currentSelected];
//    [self.recordSession removeAllSegments:NO];
//    
//    WS(weakSelf);
//    dispatch_group_t serviceGroup = dispatch_group_create();
//    for (int i = 0; i < weakSelf.recordSegments.count; i++) {
//        DLog(@"遍历数组：%d", i);
//        LZSessionSegment * segment = weakSelf.recordSegments[i];
//        NSString *filename = [NSString stringWithFormat:@"Video-%ld.m4v", (long)i];
//        NSURL *tempPath = [LZVideoTools filePathWithFileName:filename isFilter:YES];
//        
//        CMTime start = CMTimeMakeWithSeconds(segment.startTime, segment.duration.timescale);
//        CMTime duration = CMTimeMakeWithSeconds(segment.endTime - segment.startTime, segment.asset.duration.timescale);
//        CMTimeRange range = CMTimeRangeMake(start, duration);
//        
//        dispatch_group_enter(serviceGroup);
//        [LZVideoTools exportVideo:segment.asset videoComposition:nil filePath:tempPath timeRange:range completion:^(NSURL *savedPath) {
//            LZSessionSegment * newSegment = [[LZSessionSegment alloc] initWithURL:tempPath filter:nil];
//            DLog(@"url:%@", [tempPath path]);
//            [weakSelf.recordSegments removeObject:segment];
//            [weakSelf.recordSegments insertObject:newSegment atIndex:i];
//            dispatch_group_leave(serviceGroup);
//        }];
//    }
//    
//    dispatch_group_notify(serviceGroup, dispatch_get_main_queue(),^{
//        DLog(@"保存到recordSession");
//        for (int i = 0; i < weakSelf.recordSegments.count; i++) {
//            LZSessionSegment * segment = weakSelf.recordSegments[i];
//            NSAssert(segment.url != nil, @"segment url must be non-nil");
//            if (segment.url != nil) {
//                [weakSelf.recordSession insertSegment:segment atIndex:i];
//            }
//        }
//        [weakSelf.navigationController popViewControllerAnimated:YES];
//    });
}

- (void)cutVideo {
//    __block NSURL *tempPath = self.segment.url;
//    __block NSString *filename = [LZVideoTools getFileName:[tempPath absoluteString]];
    [self.recordSegments removeObjectAtIndex:self.currentSelected];
    
    double startTime = 0.0;
    double endTime = CMTimeGetSeconds(self.segment.duration)/2;
    dispatch_group_t serviceGroup = dispatch_group_create();
    for (int i = 0; i < 2; i++) {
        NSString *filename = [NSString stringWithFormat:@"Video-%.f.m4v", self.recordSession.fileIndex];
        NSURL *filePath = [LZVideoTools filePathWithFileName:filename isFilter:YES];

        if (i == 1) {
            startTime = CMTimeGetSeconds(self.segment.duration)/2;
            endTime = self.segment.endTime;
        }
        CMTime start = CMTimeMakeWithSeconds(startTime, self.segment.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(endTime - startTime, self.segment.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        
        dispatch_group_enter(serviceGroup);
        [LZVideoTools exportVideo:self.segment.asset videoComposition:nil filePath:filePath timeRange:range completion:^(NSURL *savedPath) {
            if(savedPath) {
                DLog(@"导出视频路径：%@", savedPath);
                LZSessionSegment * newSegment = [LZSessionSegment segmentWithURL:filePath filter:self.segment.filter];
                [self.recordSegments insertObject:newSegment atIndex:self.currentSelected];
            }
            dispatch_group_leave(serviceGroup);
        }];
    }
    
    dispatch_group_notify(serviceGroup, dispatch_get_main_queue(),^{
        [self.recordSession removeAllSegments:NO];
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
- (void)videoRange:(LZVideoCropperSlider *)videoRange didChangePosition:(CGFloat)position{
    [self.player pause];
    [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
    self.segment.endTime = position;
    
    //控制快进，后退
    CMTime time = CMTimeMakeWithSeconds(position, self.segment.asset.duration.timescale);
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

- (void)dealloc{
    [self.player removeTimeObserver:self.timeObser];
    DLog(@"========= dealloc =========");
}

@end
