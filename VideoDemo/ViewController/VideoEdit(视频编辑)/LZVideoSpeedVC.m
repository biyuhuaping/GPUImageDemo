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
@property (strong, nonatomic) LZSessionSegment *segment;

@property (strong, nonatomic) IBOutlet LZPlayerView *playerView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic) id timeObser;
@property (strong, nonatomic) NSMutableArray *recordSegments;

@end

@implementation LZVideoSpeedVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.recordSegments = [NSMutableArray arrayWithArray:self.recordSession.segments];
    self.segment = self.recordSession.segments[self.currentSelected];
    
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

- (void)dealloc{
    [self.playerView.player removeTimeObserver:self.timeObser];
    DLog(@"========= dealloc =========");
}

@end
