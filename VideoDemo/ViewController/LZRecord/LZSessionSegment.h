//
//  LZSessionSegment.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/5/26.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPUImageOutput.h"

@interface LZSessionSegment : NSObject

/**
 The url containing the segment data
 */
@property (strong, nonatomic) NSURL *__nonnull url;

/**
 The AVAsset created from the url.
 */
@property (readonly, nonatomic) AVAsset *__nullable asset;

/**
 The filter of this segment (片段的滤镜)
 */
@property (strong, nonatomic) GPUImageOutput<GPUImageInput> *__nullable filter;

/**
 The duration of this segment (片段的时长)
 */
@property (readonly, nonatomic) CMTime duration;

/**
 The thumbnail that represents this segment(片段缩略图)
 */
@property (readonly, nonatomic) UIImage *__nullable thumbnail;

/**
 The lastImage of this segment. This can be used for implement
 features like Vine's ghost mode.
 */
@property (readonly, nonatomic) UIImage *__nullable lastImage;

/**
 The average frameRate of this segment（片段的平均帧速率）
 */
@property (readonly, nonatomic) float frameRate;

/**
 The custom info dictionary.
 */
@property (readonly, nonatomic) NSDictionary *__nullable info;

/**
 Whether the file at the url exists （文件URL是否已存在）
 */
@property (readonly, nonatomic) BOOL fileUrlExists;


@property (readwrite, nonatomic) double startTime;
@property (readwrite, nonatomic) double endTime;
@property (readwrite, nonatomic) BOOL isMute;//是否静音  YES:静音 NO:有声
@property (readwrite, nonatomic) BOOL isSelect;//是否被选中
@property (readwrite, nonatomic) BOOL isReverse;//是否倒放
@property (strong, nonatomic) NSURL * _Nullable assetSourcePath;//源路径
@property (copy, nonatomic) NSString * _Nullable assetTargetPath;//目标路径

/**
 Initialize from a dictionaryRepresentation
 */
//- (nullable instancetype)initWithDictionaryRepresentation:(NSDictionary *__nonnull)dictionary directory:(NSString *__nonnull)directory;

/**
 Delete the file at the url. This will make the segment unusable.（删除片段文件）
 */
- (void)deleteFile;

/**
 Initialize with an URL and an info dictionary
 */
- (nonnull instancetype)initWithURL:(NSURL *__nonnull)url filter:(GPUImageOutput<GPUImageInput> *__nullable)filter;
/**
 Returns a record segment URL for a filename and a directory.
 */
//+ (NSURL *__nonnull)segmentURLForFilename:(NSString *__nonnull)filename andDirectory:(NSString *__nonnull)directory;

/**
 Create and init a segment using an URL and an info dictionary
 */
+ (LZSessionSegment *__nonnull)segmentWithURL:(NSURL *__nonnull)url filter:(GPUImageOutput<GPUImageInput> * _Nullable)filter;

@end
