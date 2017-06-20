//
//  LZVideoDetailsVC.m
//  laziz_Merchant
//
//  Created by biyuhuaping on 2017/4/19.
//  Copyright © 2017年 XBN. All rights reserved.
//  视频详情

#import "LZVideoDetailsVC.h"
#import "LZVideoEditClipVC.h"
#import "SAVideoRangeSlider.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "LZVideoTools.h"

@interface LZVideoDetailsVC ()<SCPlayerDelegate,GPUImageMovieDelegate,SAVideoRangeSliderDelegate>
{
    GPUImageMovieWriter *movieWriter;
    GPUImageVideoCamera *videoCamera;
    BOOL _isRunning;
}
@property (strong, nonatomic) IBOutlet GPUImageView *filterView;
@property (strong, nonatomic) IBOutlet SCVideoPlayerView *videoPlayerView;
@property (strong, nonatomic) GPUImageMovie *movieFile;
@property (strong, nonatomic) dispatch_queue_t writeQueue;

@property (strong, nonatomic) SCPlayer *player;


@property (strong, nonatomic) IBOutlet SAVideoRangeSlider *trimmerView;     //微调视图
@property (strong, nonatomic) AVAsset *asset;


@property (strong, nonatomic) IBOutlet UIButton *tailoringButton;//剪裁按钮
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;//计时显示

@property (strong, nonatomic) IBOutlet UIView *subView;
@property (strong, nonatomic) IBOutlet UIButton *clipsButton;//剪辑按钮

@property (strong, nonatomic) LZSessionSegment *segment;

@end

@implementation LZVideoDetailsVC
- (void)viewDidLoad {
    [super viewDidLoad];
    _writeQueue = dispatch_queue_create("LZWriteQueue", DISPATCH_QUEUE_SERIAL);
    self.timeLabel.layer.masksToBounds = YES;
    self.timeLabel.layer.cornerRadius = 10;

    self.asset = self.recordSession.assetRepresentingSegments;
    self.segment = self.recordSession.segments[0];//初始化segment，随意指向一个LZSessionSegment类型，只要不为空就行。

    [self.trimmerView getMovieFrameWithAsset:self.asset];
    self.trimmerView.delegate = self;
    
    [self configNavigationBar];
}

- (void)didCompletePlayingMovie {
    NSLog(@"已完成播放");
//    _movieFile = nil;
}

- (void)processingVideo{
    for (int i = 0; i < self.recordSession.segments.count; i++) {
        dispatch_async(self.writeQueue, ^{
            LZSessionSegment *segment = self.recordSession.segments[i];
            GPUImageFilter *filter = (GPUImageFilter *)segment.filter;
            
            NSString *filename = [NSString stringWithFormat:@"LZVideoEdit-%d.m4v", i];
            NSURL *movieURL = [LZVideoTools getFilePathWithFileName:filename isFilter:NO];
            NSURL *movieURLFilter = [LZVideoTools filePathWithFileName:filename isFilter:YES];
            
//            AVPlayer *mainPlayer = [[AVPlayer alloc] init];
//            AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:segment.asset];
//            [mainPlayer replaceCurrentItemWithPlayerItem:playerItem];
            
            // 播放
            _movieFile = [[GPUImageMovie alloc] initWithURL:movieURL];
            _movieFile.delegate = self;
            _movieFile.runBenchmark = YES;
            _movieFile.playAtActualSpeed = YES;
            _movieFile.shouldRepeat = YES;
            [_movieFile addTarget:filter];
            
            
            movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURLFilter size:CGSizeMake(480.0, 480.0)];
            movieWriter.transform = CGAffineTransformMakeRotation(M_PI_2);
            movieWriter.shouldPassthroughAudio = YES;
            _movieFile.audioEncodingTarget = movieWriter;
            [_movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
            
            // 显示到界面
            [filter addTarget:self.filterView];
            [filter addTarget:movieWriter];
        
            [movieWriter startRecording];
            [_movieFile startProcessing];
            
            __weak typeof(self) weakSelf = self;
            [movieWriter setCompletionBlock:^{
                __strong typeof(self) strongSelf = weakSelf;
                [filter removeTarget:strongSelf->movieWriter];
                [strongSelf->movieWriter finishRecording];
            }];
        });
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self.player setItemByAsset:self.asset];
//    [self.player play];
    [self.videoPlayerView.player setItemByAsset:self.asset];
    self.videoPlayerView.tapToPauseEnabled = YES;
    [self.videoPlayerView.player play];
    
    CGFloat durationSeconds = CMTimeGetSeconds(self.asset.duration);
    if (durationSeconds > MAX_VIDEO_DUR) {
        self.trimmerView.maxGap = MAX_VIDEO_DUR;
        self.timeLabel.text = @" 00:15 ";
    }else{
        self.timeLabel.text = [NSString stringWithFormat:@" 00:%02ld ", lround(durationSeconds)];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player pause];
    [self.videoPlayerView.player pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 
- (IBAction)pushButton {
    if (!_isRunning) {
        _isRunning = YES;
        [self loadVideo:nil];
    }
}

- (void)loadVideo:(NSURL *)videoUrl {
//    _playerItem = [[AVPlayerItem alloc]initWithURL:sampleURL];
    videoUrl = self.recordSession.segments[0];
    [self.player setItemByAsset:self.asset];
    _movieFile = [[GPUImageMovie alloc] initWithURL:videoUrl];
    
    _movieFile.runBenchmark = YES;
    _movieFile.playAtActualSpeed = NO;
    
    GPUImageToonFilter *filter = [[GPUImageToonFilter alloc] init];//胶片效果
    
    [_movieFile addTarget:filter];
    [filter addTarget:self.filterView];
    
    [_movieFile startProcessing];
    _player.rate = 2.0;
    
    
    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCompletePlayingMovie) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
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
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
    button1.titleLabel.font = [UIFont systemFontOfSize:15];
    [button1 setTitle:@"保存到本地" forState:UIControlStateNormal];
    [button1 setTitleColor:UIColorFromRGB(0xffffff, 1) forState:UIControlStateNormal];
    [button1 sizeToFit];
    button1.frame = CGRectMake(0, 0, CGRectGetWidth(button1.bounds), 40);
    [button1 addTarget:self action:@selector(cutVideo) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc]initWithCustomView:button],[[UIBarButtonItem alloc]initWithCustomView:button1]];
}

#pragma mark - Event
- (void)navbarRightButtonClickAction:(UIButton*)sender {
    DLog(@"该方法还没实现");
}

- (void)cutVideo {
    NSURL *tempPath = [LZVideoTools filePathWithFileName:@"LZVideoEdit-0.m4v" isFilter:YES];
    [self.recordSession removeAllSegments];
    
    CMTime start = CMTimeMakeWithSeconds(self.segment.startTime, self.asset.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(self.segment.endTime - self.segment.startTime, self.asset.duration.timescale);
    CMTimeRange range = CMTimeRangeMake(start, duration);
    
    [LZVideoTools exportVideo:self.asset videoComposition:nil filePath:tempPath timeRange:range completion:^(NSURL *savedPath) {
        if(savedPath) {
            DLog(@"导出视频路径：%@", savedPath);
            LZSessionSegment * newSegment = [LZSessionSegment segmentWithURL:tempPath filter:nil];
            [self.recordSession addSegment:newSegment];
            //保存到本地
            ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
            if ([assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:savedPath]) {
                [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:savedPath completionBlock:NULL];
            }
        }
        else {
            DLog(@"导出视频路径出错：%@", savedPath);
        }
    }];
}

//剪裁按钮
- (IBAction)tailoringButton:(UIButton *)sender {
    sender.selected = YES;
    self.clipsButton.selected = NO;
    self.subView.hidden = YES;
}

//剪辑按钮
- (IBAction)clipsButton:(UIButton *)sender {
    sender.selected = YES;
    self.tailoringButton.selected = NO;
    self.subView.hidden = NO;
}

#pragma mark - SAVideoRangeSliderDelegate
- (void)videoRange:(SAVideoRangeSlider *)videoRange isLeft:(BOOL)isLeft didChangeLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition
{
    NSAssert(self.segment.url != nil, @"segment must be non-nil");
    if(self.segment) {
        [self.segment setStartTime:leftPosition];
        [self.segment setEndTime:rightPosition];
        
        CGFloat screenWidth = (rightPosition-leftPosition) / MAX_VIDEO_DUR * SCREEN_WIDTH;
        CGFloat durationSeconds = rightPosition - leftPosition;
        
        DLog(@"startTime:%f, endTime:%f, width:%f", self.segment.startTime, self.segment.endTime, durationSeconds);
        
        self.timeLabel.text = [NSString stringWithFormat:@" 00:%02ld ", lround(durationSeconds)];
        
        //控制快进，后退
        float f = 0;
        if (isLeft) {
            f = self.segment.startTime;
        }else{
            f = self.segment.endTime;
        }
        CMTime time = CMTimeMakeWithSeconds(f, self.videoPlayerView.player.currentTime.timescale);
        [self.videoPlayerView.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}

#warning  暂时弃用
- (void)nextView {
    LZVideoEditClipVC * vc = [[LZVideoEditClipVC alloc] initWithNibName:@"LZVideoEditClipVC" bundle:nil];
    vc.recordSession = self.recordSession;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
