//
//  LZVideoTools.h
//  laziz_Merchant
//
//  Created by biyuhuaping on 2017/3/29.
//  Copyright © 2017年 XBN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LZRecordSession.h"
#import "LZSessionSegment.h"

@interface LZVideoTools : NSObject

/**
 视频压缩+剪切+导出
 
 @param segment 视频资源
 @param filePath 文件路径
 @param completion 完成回调
 */
+ (void)cutVideoWith:(LZSessionSegment *)segment filePath:(NSURL *)filePath completion:(void (^)(void))completion;


/**
 导出视频
 
 @param asset 视频资源
 @param videoComposition 视频合成物
 @param filePath 文件路径
 @param range 时长范围
 @param completion 完成回调
 */
+ (void)exportVideo:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition filePath:(NSURL *)filePath timeRange:(CMTimeRange)range completion:(void (^)(NSURL *savedPath))completion;



/**
 视频、声音淡出
 
 @param asset    视频资源
 @param duration 淡出时长
 @return 返回AVPlayerItem
 */
+ (AVPlayerItem *)videoFadeOut:(AVAsset *)asset duration:(Float64)duration;


/**
 视频速度
 
 @param segment 视频资源
 @param scale 速度比率
 @return 返回AVPlayerItem
 */
+ (AVPlayerItem *)videoSpeed:(LZSessionSegment *)segment scale:(CGFloat)scale;


#pragma mark - 
+ (NSURL *)filePathWithFileName:(NSString *)fileName;


/**
 枚举路径
 */
+ (NSArray *)enumPathisFilter:(BOOL)isFilter;

@end
