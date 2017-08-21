//
//  PlayView.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/8/21.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PlayView : UIView

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVAsset *asset;

- (void)play;

- (void)pause;

@end
