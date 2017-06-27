//
//  LZVideoTools.h
//  laziz_Merchant
//
//  Created by biyuhuaping on 2017/3/29.
//  Copyright © 2017年 XBN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCRecorder.h"

#import "LZRecordSession.h"
#import "LZSessionSegment.h"

@interface LZVideoTools : NSObject

/**
 视频压缩+剪切+导出
 
 @param selectSegment 所选视频资源
 @param filePath 文件路径
 @param completion 完成回调
 */
+ (void)cutVideoWith:(LZSessionSegment *)selectSegment filePath:(NSURL *)filePath completion:(void (^)(void))completion;


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
 配置文件路径

 @param fileName 文件名称
 @return 文件路径
 */
+ (NSURL *)filePathWithFileName:(NSString *)fileName;
+ (NSURL *)filePathWithFileName:(NSString *)fileName isFilter:(BOOL)isFilter;

/**
 获取文件名称
 
 @param path 文件路径 如//file:///private/var/mobile/Containers/Data/Application/C91A7103-ED23-4578-AB00-DA59EEB36E86/tmp/LZVideo/Video-1.m4v
 @return 文件名称 如：Video-1
 */
+ (NSString *)getFileName:(NSString *)path;



//声音淡出
+ (AVPlayerItem *)audioFadeOut:(LZSessionSegment *)selectSegment;

//视频淡出
+ (AVPlayerItem *)videoFadeOut:(LZSessionSegment *)selectSegment;

@end
