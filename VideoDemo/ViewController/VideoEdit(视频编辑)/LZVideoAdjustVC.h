//
//  LZVideoAdjustVC.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/28.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LZRecordSession.h"

@interface LZVideoAdjustVC : UIViewController

@property (strong, nonatomic) LZRecordSession *recordSession;
@property (strong, nonatomic) NSMutableArray *recordSegments;
@property (assign, nonatomic) NSInteger currentSelected;

@end
