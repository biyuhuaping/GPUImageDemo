//
//  LZCameraFilterCollectionView.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/12.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LZCameraFilterViewDelegate;
@protocol LZCameraFilterViewDelegate <NSObject>

- (void)switchCameraFilter:(NSInteger)index;
@end


@interface LZCameraFilterCollectionView : UICollectionView<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSMutableArray *picArray;
@property (strong, nonatomic) id <LZCameraFilterViewDelegate> cameraFilterDelegate;

@end
