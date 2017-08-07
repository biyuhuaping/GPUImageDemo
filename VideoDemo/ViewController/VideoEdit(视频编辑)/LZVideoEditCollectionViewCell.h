//
//  LZVideoEditCollectionViewCell.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/7/26.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LZVideoEditCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView * imageView;
@property (strong, nonatomic) IBOutlet UIButton *deletBut;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;

@end
