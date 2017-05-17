//
//  RecordProgressView.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/5/12.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecordProgressView : UIView
@property (nonatomic, assign) CGFloat progress;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)updateProgressWithValue:(CGFloat)progress;
- (void)resetProgress;

@end
