//
//  LZVideoEditCollectionViewCell.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/7/26.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZVideoEditCollectionViewCell.h"

@implementation LZVideoEditCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    _timeLabel.layer.masksToBounds = YES;
}

@end
