//
//  LZVideoAdjustVC.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/28.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZVideoAdjustVC.h"
#import "LZPlayerView.h"
#import "LZVideoTools.h"

@interface LZVideoAdjustVC ()
@property (strong, nonatomic) LZSessionSegment *segment;

@property (strong, nonatomic) IBOutlet LZPlayerView *playerView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) id timeObser;
@property (strong, nonatomic) NSMutableArray *recordSegments;

@property (strong, nonatomic) IBOutlet UISlider *slider1;
@property (strong, nonatomic) IBOutlet UISlider *slider2;
@property (strong, nonatomic) IBOutlet UISlider *slider3;
@property (strong, nonatomic) IBOutlet UISlider *slider4;
@property (strong, nonatomic) IBOutlet UISlider *slider5;
@property (strong, nonatomic) IBOutlet UISlider *slider6;

@end

@implementation LZVideoAdjustVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.recordSegments = [NSMutableArray arrayWithArray:self.recordSession.segments];
    self.segment = self.recordSession.segments[self.currentSelected];
    
    [self configNavigationBar];
    [self configPlayerView];
    
    self.slider1.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider2.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider3.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider4.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider5.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider6.transform = CGAffineTransformMakeRotation(-M_PI_2);
//    [self configSliderView];
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
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(playOrPause)];
    [self.playerView addGestureRecognizer:tap];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.segment.asset];
    self.playerView.player = [AVPlayer playerWithPlayerItem:item];
    
    WS(weakSelf);
    self.timeObser = [self.playerView.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        double current = CMTimeGetSeconds(time);
        double total = CMTimeGetSeconds(weakSelf.segment.asset.duration);
        if (current >= total) {
            CMTime time = CMTimeMakeWithSeconds(weakSelf.segment.startTime, weakSelf.segment.duration.timescale);
            [weakSelf.playerView.player seekToTime:time];
            weakSelf.imageView.hidden = NO;
        }
    }];
}

- (void)configSliderView{
    double with = kScreenWidth/6;
    for (int i = 0; i < 6; i++) {
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(i*with, 450, 200, 20)];
        slider.minimumValue = 0.0;
        slider.maximumValue = 1;
        slider.value = 0.5;
        slider.tag = i;
        [slider addTarget:self action:@selector(updateValue:) forControlEvents:UIControlEventValueChanged];
        slider.transform = CGAffineTransformMakeRotation(M_PI_2); //旋转一下即可
    }
}

#pragma mark - Event
- (void)navbarRightButtonClickAction:(UIButton*)sender {
    NSURL *tempPath = self.segment.url;
    NSString *filename = [LZVideoTools getFileName:[tempPath absoluteString]];
    tempPath = [LZVideoTools filePathWithFileName:[NSString stringWithFormat:@"%@.m4v", filename] isFilter:YES];
    
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
        [self.playerView.player play];
        _imageView.hidden = YES;
    }else{
        [self.playerView.player pause];
        _imageView.hidden = NO;
    }
}

- (IBAction)updateValue:(UISlider *)sender{
    switch (sender.tag) {
        case 1: {//亮度
            
        }
            break;
        case 2: {//对比度
            
        }
            break;
        case 3: {//饱和度
            
        }
            break;
        case 4: {//锐度
            
        }
            break;
        case 5: {//色温
            
        }
            break;
        case 6: {//暗度
            
        }
            break;
            
    }
    if (sender.value == sender.maximumValue/2) {
        sender.thumbTintColor = [UIColor blueColor];
    }else{
        sender.thumbTintColor = [UIColor greenColor];
    }
    DLog(@"%f",sender.value);
}

- (void)dealloc{
    [self.playerView.player removeTimeObserver:self.timeObser];
    DLog(@"========= dealloc =========");
}

@end
