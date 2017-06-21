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
#import "LZPlayerView.h"

@interface LZVideoDetailsVC ()<SAVideoRangeSliderDelegate>

@property (strong, nonatomic) IBOutlet LZPlayerView *playerView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet SAVideoRangeSlider *trimmerView;     //微调视图
@property (strong, nonatomic) AVAsset *asset;


@property (strong, nonatomic) IBOutlet UIButton *tailoringButton;//剪裁按钮
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;//计时显示

@property (strong, nonatomic) IBOutlet UIView *subView;
@property (strong, nonatomic) IBOutlet UIButton *clipsButton;//剪辑按钮

//@property (strong, nonatomic) LZSessionSegment *segment;
@property (assign, nonatomic) CGFloat startTime;
@property (assign, nonatomic) CGFloat endTime;

@end

@implementation LZVideoDetailsVC
- (void)viewDidLoad {
    [super viewDidLoad];
    self.timeLabel.layer.masksToBounds = YES;
    self.timeLabel.layer.cornerRadius = 10;

    self.asset = self.recordSession.assetRepresentingSegments;
//    self.segment = self.recordSession.segments[0];//初始化segment，随意指向一个LZSessionSegment类型，只要不为空就行。
    self.startTime = 0;
    self.endTime = CMTimeGetSeconds(self.asset.duration);
    
    [self.trimmerView getMovieFrameWithAsset:self.asset];
    self.trimmerView.delegate = self;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playOrPause)];
    [self.playerView addGestureRecognizer:tap];

    
    [self configNavigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.asset];
    self.playerView.player = [AVPlayer playerWithPlayerItem:item];
    
    WS(weakSelf);
    [self.playerView.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
//        float total = CMTimeGetSeconds(weakSelf.asset.duration);
        DLog(@"当前已经播放%.2fs.",current);
        if (current >= _endTime) {
            DLog(@"播放完毕");
            [weakSelf.playerView.player pause];
            weakSelf.imageView.hidden = NO;
        }
    }];
    
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
    [self.playerView.player pause];
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
    
    CMTime start = CMTimeMakeWithSeconds(self.startTime, self.asset.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(self.endTime - self.startTime, self.asset.duration.timescale);
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

//播放或暂停
- (void)playOrPause{
    if (!(self.playerView.player.rate > 0)) {
        CMTime time = CMTimeMakeWithSeconds(self.startTime, self.asset.duration.timescale);
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
    self.startTime = leftPosition;
    self.endTime = rightPosition;
    
//    CGFloat screenWidth = (rightPosition-leftPosition) / MAX_VIDEO_DUR * SCREEN_WIDTH;
    CGFloat durationSeconds = rightPosition - leftPosition;
    
    DLog(@"startTime:%f, endTime:%f, width:%f", self.startTime, self.endTime, durationSeconds);
//    DLog(@"%f", CMTimeGetSeconds(self.playerView.player.playableDuration));
    
    self.timeLabel.text = [NSString stringWithFormat:@" 00:%02ld ", lround(durationSeconds)];
    
    //控制快进，后退
    float f = 0;
    if (isLeft) {
        f = self.startTime;
    }else{
        f = self.endTime;
    }
    CMTime time = CMTimeMakeWithSeconds(f, self.asset.duration.timescale);
    [self.playerView.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

#warning  暂时弃用
- (void)nextView {
    LZVideoEditClipVC * vc = [[LZVideoEditClipVC alloc] initWithNibName:@"LZVideoEditClipVC" bundle:nil];
    vc.recordSession = self.recordSession;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
