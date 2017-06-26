//
//  LZVideoSplitVC.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/26.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LZRecordSession.h"

@interface LZVideoSplitVC : UIViewController

@property (strong, nonatomic) LZRecordSession * recordSession;
@property (assign, nonatomic) NSInteger currentSelected;

@end
