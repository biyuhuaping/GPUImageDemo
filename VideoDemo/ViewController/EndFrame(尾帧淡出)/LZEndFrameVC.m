//
//  LZEndFrameVC.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/8/18.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZEndFrameVC.h"
#import "LZVideoTools.h"

@interface LZEndFrameVC ()


@property (strong, nonatomic) IBOutlet UIView *subView;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) id timeObser;

@property (strong, nonatomic) AVAsset *asset;
@property (assign, nonatomic) CGFloat duration;

@end

@implementation LZEndFrameVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.asset = self.recordSession.assetRepresentingSegments;

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
    [button setTitle:LZLocalizedString(@"edit_done", @"") forState:UIControlStateNormal];
    [button setTitleColor:UIColorFromRGB(0xffffff, 1) forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectMake(0, 0, CGRectGetWidth(button.bounds), 40);
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
    [button addTarget:self action:@selector(navbarRightButtonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:button];
}

- (void)configPlayerView{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.asset];
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    layer.frame = CGRectMake(0, 0, kScreenWidth, kScreenWidth);
    [self.subView.layer addSublayer:layer];
    
    WS(weakSelf);
    self.timeObser = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time){
        double current = CMTimeGetSeconds(time);
        double total = CMTimeGetSeconds(weakSelf.asset.duration);
        DLog(@"当前已经播放%.2fs.",current);
        if (current >= total) {
            DLog(@"播放完毕");
            CMTime time = CMTimeMakeWithSeconds(0, weakSelf.asset.duration.timescale);
            [weakSelf.player seekToTime:time];
            [weakSelf.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
        }
    }];
}

#pragma mark - Event
- (void)navbarRightButtonClickAction:(UIButton *)sender {
    NSURL *filePath = [LZVideoTools filePathWithFileName:@"LZVideoEdit-0.m4v"];
    [self.recordSession removeAllSegments];
    [LZVideoTools exportVideo:self.asset filePath:filePath timeRange:kCMTimeRangeZero duration:self.duration completion:^(NSURL *savedPath) {
        if(savedPath) {
            DLog(@"导出视频路径：%@", savedPath);
            LZSessionSegment *newSegment = [LZSessionSegment segmentWithURL:filePath filter:nil];
            [self.recordSession addSegment:newSegment];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
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

- (IBAction)updateSliderValue:(UISlider *)sender{
    self.duration = sender.value;
    DLog(@"rateValue:======%f",sender.value);
}

- (void)dealloc{
    [self.player removeTimeObserver:self.timeObser];
    DLog(@"========= dealloc =========");
}

@end
