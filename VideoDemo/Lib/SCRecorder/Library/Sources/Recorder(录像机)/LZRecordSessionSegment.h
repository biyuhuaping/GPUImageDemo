//
//  LZRecordSessionSegment.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/5/26.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface LZRecordSessionSegment : NSObject

/**
 The url containing the segment data
 */
@property (strong, nonatomic) NSURL *__nonnull url;

/**
 The AVAsset created from the url.
 */
@property (readonly, nonatomic) AVAsset *__nullable asset;

/**
 The duration of this segment
 */
@property (readonly, nonatomic) CMTime duration;

/**
 The thumbnail that represents this segment
 */
@property (readonly, nonatomic) UIImage *__nullable thumbnail;

/**
 The lastImage of this segment. This can be used for implement
 features like Vine's ghost mode.
 */
@property (readonly, nonatomic) UIImage *__nullable lastImage;

/**
 The average frameRate of this segment
 */
@property (readonly, nonatomic) float frameRate;

/**
 The custom info dictionary.
 */
@property (readonly, nonatomic) NSDictionary *__nullable info;


/**
 Initialize with an URL and an info dictionary
 */
- (nonnull instancetype)initWithURL:(NSURL *__nonnull)url info:(NSDictionary *__nullable)info;


/**
 Create and init a segment using an URL and an info dictionary
 */
+ (LZRecordSessionSegment *__nonnull)segmentWithURL:(NSURL *__nonnull)url info:(NSDictionary *__nullable)info;

@end
