//
//  LZSelectVideoVC.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/7/17.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//  选择视频页面

#import <UIKit/UIKit.h>
#import "LZRecordSession.h"

@interface LZSelectVideoVC : UIViewController

@property (strong, nonatomic) LZRecordSession *recordSession;
@property (strong, nonatomic) NSMutableArray *videoListSegmentArrays;

@end
