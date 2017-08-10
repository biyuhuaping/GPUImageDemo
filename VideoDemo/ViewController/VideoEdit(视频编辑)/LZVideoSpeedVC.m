//
//  LZVideoSpeedVC.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/28.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZVideoSpeedVC.h"
#import "LZPlayerView.h"
#import "LZVideoTools.h"

@interface LZVideoSpeedVC ()
@property (strong, nonatomic) IBOutlet GPUImageView *gpuImageView;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) LZSessionSegment *segment;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) id timeObser;

@property (assign, nonatomic) float rateValue;

@end

@implementation LZVideoSpeedVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"变速";

    self.segment = self.recordSegments[self.currentSelected];
    self.rateValue = 1.0;

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
- (void)navbarRightButtonClickAction:(UIButton*)sender {
    NSString *filename = [NSString stringWithFormat:@"Video-%.f.m4v", self.recordSession.fileIndex];
    NSURL *filePath = [LZVideoTools filePathWithFileName:filename];

    AVPlayerItem *playerItem = [LZVideoTools videoSpeed:self.segment scale:(2.6 - self.rateValue)];
    [LZVideoTools exportVideo:playerItem.asset filePath:filePath timeRange:kCMTimeRangeZero duration:0 completion:^(NSURL *savedPath) {
        if(savedPath) {
            DLog(@"导出视频路径：%@", savedPath);
            LZSessionSegment * newSegment = [LZSessionSegment segmentWithURL:filePath filter:self.segment.filter];
            [self.recordSession replaceSegmentsAtIndex:self.currentSelected withSegment:newSegment];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

//播放或暂停
- (IBAction)playOrPause{
    if (!(self.player.rate > 0)) {
        self.player.rate = self.rateValue;
        [self.playButton setImage:nil forState:UIControlStateNormal];
    }else{
        self.player.rate = 0;
        [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
    }
}

- (IBAction)updateSliderValue:(UISlider *)sender{
    self.rateValue = sender.value;
    self.player.rate = self.rateValue;
    
    DLog(@"rateValue:======%f",self.rateValue);
}

- (void)dealloc{
    [self.player removeTimeObserver:self.timeObser];
    DLog(@"========= dealloc =========");
}

@end
