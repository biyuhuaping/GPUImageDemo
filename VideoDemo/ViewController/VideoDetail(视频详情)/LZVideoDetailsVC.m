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

#import "LZVideoFilterVC.h"//视频滤镜VC
#import "LZEndFrameVC.h"//尾帧淡出

@interface LZVideoDetailsVC ()<SAVideoRangeSliderDelegate>

@property (strong, nonatomic) IBOutlet LZPlayerView *playerView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet SAVideoRangeSlider *trimmerView;     //微调视图
@property (weak, nonatomic) AVAsset *asset;


@property (strong, nonatomic) IBOutlet UIButton *tailoringButton;//剪裁按钮
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;//计时显示

@property (strong, nonatomic) IBOutlet UIView *subView;
@property (strong, nonatomic) IBOutlet UIButton *clipsButton;//剪辑按钮

@property (assign, nonatomic) double startTime;
@property (assign, nonatomic) double endTime;

@property (strong, nonatomic) id timeObser;


@end

@implementation LZVideoDetailsVC
- (void)viewDidLoad {
    [super viewDidLoad];
    [self configNavigationBar];
    
    self.timeLabel.layer.masksToBounds = YES;
    self.timeLabel.layer.cornerRadius = 10;
    
    self.trimmerView.delegate = self;
    self.trimmerView.maxGap = MAX_VIDEO_DUR;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    CGFloat durationSeconds = CMTimeGetSeconds(self.asset.duration);

    self.startTime = 0.00;
    self.endTime = durationSeconds;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 处理耗时操作的代码块...
        [self.trimmerView getMovieFrameWithAsset:self.asset];
        //通知主线程刷新
        dispatch_async(dispatch_get_main_queue(), ^{
            //回调或者说是通知主线程刷新，
            [self.trimmerView setNewLeftPosition:0];
            if (durationSeconds > MAX_VIDEO_DUR) {
                [self.trimmerView setNewRightPosition:MAX_VIDEO_DUR];
                self.timeLabel.text = @" 00:15 ";
            }else{
                [self.trimmerView setNewRightPosition:durationSeconds];
                self.timeLabel.text = [NSString stringWithFormat:@" 00:%02ld ", lround(durationSeconds)];
            }
        });
    });
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playOrPause)];
    [self.playerView addGestureRecognizer:tap];
    
    [self configPlayerView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.playerView.player pause];
    self.asset = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (AVAsset *)asset{
    if (!_asset) {
        _asset = self.recordSession.assetRepresentingSegments;
    }
    return _asset;
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
    [button1 addTarget:self action:@selector(cutVideoAndSavedPhotosAlbum) forControlEvents:UIControlEventTouchUpInside];

    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc]initWithCustomView:button],[[UIBarButtonItem alloc]initWithCustomView:button1]];
}

- (void)configPlayerView{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.asset];
    self.playerView.player = [AVPlayer playerWithPlayerItem:playerItem];

    WS(weakSelf);
    _timeObser = [self.playerView.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time){
        double current = CMTimeGetSeconds(time);
        double total = CMTimeGetSeconds(weakSelf.asset.duration);
        DLog(@"当前已经播放%.2fs.",current);
        if (current >= total) {
            DLog(@"播放完毕");
            CMTime time = CMTimeMakeWithSeconds(0, weakSelf.asset.duration.timescale);
            [weakSelf.playerView.player seekToTime:time];
            weakSelf.imageView.hidden = NO;
        }
    }];
}

#pragma mark - Event
//提交
- (void)navbarRightButtonClickAction:(UIButton*)sender {
//    LZCreatePromotionViewController * vc = [[LZCreatePromotionViewController alloc] init];
//    vc.recordSession = self.recordSession;
//    [self.navigationController pushViewController:vc animated:YES];
}

//剪裁视频，保存到本地
- (void)cutVideoAndSavedPhotosAlbum {
    NSURL *tempPath = [LZVideoTools filePathWithFileName:@"LZVideoEdit-0.m4v"];
    [self.recordSession removeAllSegments];
    
    self.startTime = 0.00;
    self.endTime = CMTimeGetSeconds(self.asset.duration);
    
    CMTime start = CMTimeMakeWithSeconds(self.startTime, self.asset.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(self.endTime - self.startTime, self.asset.duration.timescale);
    CMTimeRange range = CMTimeRangeMake(start, duration);
    
    [LZVideoTools exportVideo:self.asset filePath:tempPath timeRange:range duration:0 completion:^(NSURL *savedPath) {
        if(savedPath) {
            DLog(@"导出视频路径：%@", savedPath);
            LZSessionSegment * newSegment = [LZSessionSegment segmentWithURL:tempPath filter:nil];
            [self.recordSession addSegment:newSegment];
            //保存到本地
            ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
            if ([assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:savedPath]) {
                [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:savedPath completionBlock:^(NSURL *assetURL, NSError *error) {
                    if (!error) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"保存成功" message:@"zhoubo" preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            DLog(@"点击了确定");
                        }]];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                }];
            }
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

    //    CGFloat screenWidth = (rightPosition-leftPosition) / MAX_VIDEO_DUR * SCREEN_WIDTH;
    double durationSeconds = rightPosition - leftPosition;
    
    DLog(@"startTime:%f, endTime:%f, width:%f", self.startTime, self.endTime, durationSeconds);
//    DLog(@"%f", CMTimeGetSeconds(self.playerView.player.playableDuration));
    
    self.timeLabel.text = [NSString stringWithFormat:@" 00:%02ld ", lround(durationSeconds)];
    
    //控制快进，后退
    double f = isLeft?leftPosition:rightPosition;
    CMTime time = CMTimeMakeWithSeconds(f, self.asset.duration.timescale);
    [self.playerView.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        self.startTime = leftPosition;
        self.endTime = rightPosition;
    }];
}

#pragma mark - 剪辑按钮们
- (IBAction)clipsButtonActions:(UIButton *)sender {
    DLog(@"%ld",(long)sender.tag);
    [self tailoringButton:self.tailoringButton];

    switch (sender.tag) {
        case 100:{//Clips edit
            LZVideoEditClipVC * vc = [[LZVideoEditClipVC alloc] initWithNibName:@"LZVideoEditClipVC" bundle:nil];
            vc.recordSession = self.recordSession;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 101:{//尾帧淡出
            LZEndFrameVC * vc = [[LZEndFrameVC alloc] initWithNibName:@"LZEndFrameVC" bundle:nil];
            vc.recordSession = self.recordSession;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 102:{//Add clips
            [self.navigationController popViewControllerAnimated:YES];
        }
            break;
    }
}

- (void)dealloc{
    [self.playerView.player removeTimeObserver:_timeObser];
    DLog(@"========= dealloc =========");
}

@end
