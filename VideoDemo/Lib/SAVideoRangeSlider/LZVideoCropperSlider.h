//
//  LZVideoCropperSlider.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/26.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@protocol LZVideoCropperSliderDelegate;

@interface LZVideoCropperSlider : UIView{
    CGFloat _position;
}

@property (nonatomic, weak) id <LZVideoCropperSliderDelegate> delegate;
@property (nonatomic, assign) CGFloat maxGap;
@property (nonatomic, assign) CGFloat minGap;

- (void)getMovieFrame:(NSURL *)videoUrl;
- (void)getMovieFrameWithAsset:(AVAsset *)myAsset;

- (void)setNewRightPosition:(CGFloat)newrightPosition;

@end




@protocol LZVideoCropperSliderDelegate <NSObject>
@optional
- (void)videoRange:(LZVideoCropperSlider *)videoRange didChangePosition:(CGFloat)position;

@end
