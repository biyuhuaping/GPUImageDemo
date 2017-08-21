//
//  PlayView.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/8/21.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "PlayView.h"

@interface PlayView ()

@property (strong, nonatomic) id timeObser;
@property (strong, nonatomic) UIButton *playButton;

@end


@implementation PlayView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.playButton.frame = CGRectMake(0, 0, kScreenWidth, kScreenWidth);
        [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
        [self addSubview:self.playButton];
        [self showVideo];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.playButton.frame = CGRectMake(0, 0, kScreenWidth, kScreenWidth);
        [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
        [self addSubview:self.playButton];
        [self showVideo];
    }
    return self;
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}


- (void)play{
    [self.player play];
}

- (void)pause{
    [self.player pause];
}

- (void)showVideo{
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithAsset:self.asset];
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    layer.frame = CGRectMake(0, 0, kScreenWidth, kScreenWidth);
    [self.layer addSublayer:layer];
    
    [self.playButton setImage:nil forState:UIControlStateNormal];
    [self.player play];
    
    WS(weakSelf);
    self.timeObser = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        double current = CMTimeGetSeconds(time);
        double total = CMTimeGetSeconds(weakSelf.asset.duration);
        if (current >= total) {
            CMTime time = CMTimeMakeWithSeconds(0, weakSelf.asset.duration.timescale);
            [weakSelf.player seekToTime:time];
            [weakSelf.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
        }
    }];
}

@end
