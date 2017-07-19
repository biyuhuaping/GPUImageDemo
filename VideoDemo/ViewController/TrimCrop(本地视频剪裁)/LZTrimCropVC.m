//
//  LZTrimCropVC.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/7/18.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZTrimCropVC.h"
#import "SAVideoRangeSlider.h"
#import "LZVideoTools.h"


@interface LZTrimCropVC ()<SAVideoRangeSliderDelegate>

@property (strong, nonatomic) IBOutlet UIView *subView;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) id timeObser;

@property (strong, nonatomic) IBOutlet SAVideoRangeSlider *trimmerView;     //微调视图

@end

@implementation LZTrimCropVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LZLocalizedString(@"trim_crop", nil);
    [self.trimmerView performSelectorInBackground:@selector(getMovieFrameWithAsset:) withObject:self.segment.asset];
    self.trimmerView.delegate = self;
    
    [self showVideo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showVideo{
    LZSessionSegment *segment = self.segment;
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithURL:segment.url];
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    layer.frame = CGRectMake(0, 0, kScreenWidth, kScreenWidth);
    [self.subView.layer addSublayer:layer];

    [self.playButton setImage:nil forState:UIControlStateNormal];
    [self.player play];
    
    WS(weakSelf);
    self.timeObser = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        double current = CMTimeGetSeconds(time);
        double total = CMTimeGetSeconds(segment.asset.duration);
        if (current >= total) {
            CMTime time = CMTimeMakeWithSeconds(segment.startTime, segment.duration.timescale);
            [weakSelf.player seekToTime:time];
            [weakSelf.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
        }
    }];
}

#pragma mark - Event
- (IBAction)nextButtonAction:(UIButton *)sender {
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:self.segment.asset];
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        NSURL *tempPath = [LZVideoTools filePathWithFileName:@"ConponVideo.m4v"];
        WS(weakSelf);
        [LZVideoTools cutVideoWith:self.segment filePath:tempPath completion:^{
            LZSessionSegment * newSegment = [[LZSessionSegment alloc] initWithURL:tempPath filter:nil];
            [weakSelf.recordSession addSegment:newSegment];
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }];
    }
}

//播放或暂停
- (IBAction)lzPlayOrPause:(UIButton *)button{
    if (!(self.player.rate > 0)) {
        [self.player play];
        [self.playButton setImage:nil forState:UIControlStateNormal];
    }else{
        [self.player pause];
        [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
    }
}

#pragma mark - SAVideoRangeSliderDelegate
- (void)videoRange:(SAVideoRangeSlider *)videoRange isLeft:(BOOL)isLeft didChangeLeftPosition:(CGFloat)leftPosition rightPosition:(CGFloat)rightPosition {
    NSAssert(self.segment.url != nil, @"segment must be non-nil");
    if(self.segment) {
        [self.segment setStartTime:leftPosition];
        [self.segment setEndTime:rightPosition];

        //控制快进，后退
        float f = 0;
        if (isLeft) {
            f = self.segment.startTime;
        }else{
            f = self.segment.endTime;
        }
        CMTime time = CMTimeMakeWithSeconds(f, self.player.currentTime.timescale);
        [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
}

@end
