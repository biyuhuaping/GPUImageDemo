//
//  LZVideoTailoringVC.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/23.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LZRecordSession.h"

@interface LZVideoTailoringVC : UIViewController

@property (strong, nonatomic) LZRecordSession * recordSession;
@property (strong, nonatomic) NSMutableArray *recordSegments;
@property (assign, nonatomic) NSInteger currentSelected;

@end
