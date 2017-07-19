//
//  LZTrimCropVC.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/7/18.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//  选择视频剪切页面

#import <UIKit/UIKit.h>
#import "LZRecordSession.h"

@interface LZTrimCropVC : UIViewController

@property (strong, nonatomic) LZRecordSession *recordSession;
@property (strong, nonatomic) LZSessionSegment *segment;

@end
