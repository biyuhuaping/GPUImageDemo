//
//  LZPlayerView.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/21.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZPlayerView.h"

@implementation LZPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end
