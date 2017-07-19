//
//  LZVideoTools.m
//  laziz_Merchant
//
//  Created by biyuhuaping on 2017/3/29.
//  Copyright © 2017年 XBN. All rights reserved.
//

#import "LZVideoTools.h"

@implementation LZVideoTools

/**
 视频压缩+剪切+导出
 
 @param segment 视频资源
 @param filePath 文件路径
 @param completion 完成回调
 */
+ (void)cutVideoWith:(LZSessionSegment *)segment filePath:(NSURL *)filePath completion:(void (^)(void))completion{
    
//    1.将素材拖入到素材库中
    AVAsset *asset = segment.asset;
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];//素材的视频轨
    AVAssetTrack *audioAssertTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];//素材的音频轨
    
    
//    2.将素材的视频插入视频轨，音频插入音频轨
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];//这是工程文件
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];//视频轨道
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];//在视频轨道插入一个时间段的视频
    
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];//音频轨道
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:audioAssertTrack atTime:kCMTimeZero error:nil];//插入音频数据，否则没有声音
    
    
//    3.裁剪视频，就是要将所有视频轨进行裁剪，就需要得到所有的视频轨，而得到一个视频轨就需要得到它上面所有的视频素材
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    CMTime totalDuration = CMTimeAdd(kCMTimeZero, asset.duration);
    
    CGFloat videoAssetTrackNaturalWidth = videoAssetTrack.naturalSize.width;
    CGFloat videoAssetTrackNaturalHeight = videoAssetTrack.naturalSize.height;
    CGSize renderSize = CGSizeMake(videoAssetTrackNaturalWidth, videoAssetTrackNaturalHeight);
    
    CGFloat renderW = MAX(renderSize.width, renderSize.height);
    CGFloat rate;
    rate = renderW / MIN(videoAssetTrackNaturalWidth, videoAssetTrackNaturalHeight);
    CGAffineTransform layerTransform = CGAffineTransformMake(videoAssetTrack.preferredTransform.a, videoAssetTrack.preferredTransform.b, videoAssetTrack.preferredTransform.c, videoAssetTrack.preferredTransform.d, videoAssetTrack.preferredTransform.tx * rate, videoAssetTrack.preferredTransform.ty * rate);
    //    layerTransform = CGAffineTransformConcat(layerTransform, CGAffineTransformMake(1, 0, 0, 1, 0, -(videoAssetTrackNaturalWidth - videoAssetTrackNaturalHeight) / 2.0));//zhoubo fix 2017.03.31
    layerTransform = CGAffineTransformScale(layerTransform, rate, rate);
    [layerInstruction setTransform:layerTransform atTime:kCMTimeZero];//得到视频素材

    
    //设置淡出时间
    CMTime start1 = CMTimeMake(composition.duration.value - composition.duration.timescale*1, composition.duration.timescale);
    CMTimeRange timeRange = CMTimeRangeFromTimeToTime(start1, composition.duration);

    //视频合成指令
    [layerInstruction setOpacityRampFromStartOpacity:1 toEndOpacity:0 timeRange:timeRange];

    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    instruction.layerInstructions = @[layerInstruction];
    
    
    //设置音频输出参数
    AVMutableAudioMixInputParameters *parameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
    [parameters setVolumeRampFromStartVolume:1 toEndVolume:0 timeRange:timeRange];
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = @[parameters];
    
    
    
    //视频合成
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = @[instruction];
    videoComposition.frameDuration = CMTimeMake(1, 30);// 30 fps
    videoComposition.renderSize = CGSizeMake(renderW, renderW);//渲染（剪裁）出对应的大小
    
    
//    4.导出
    CMTime start = CMTimeMakeWithSeconds(segment.startTime, segment.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(segment.endTime - segment.startTime, segment.asset.duration.timescale);
    CMTimeRange range = CMTimeRangeMake(start, duration);

    
    [self exportVideo:composition videoComposition:videoComposition filePath:filePath timeRange:range completion:^(NSURL *savedPath) {
        if (completion) {
            completion();
            DLog(@"视频导出成功：%@", savedPath);
        }
    }];
}


/**
 导出视频
 
 @param asset 视频资源
 @param videoComposition 视频合成物
 @param filePath 文件路径
 @param range 时长范围
 @param completion 完成回调
 */
+ (void)exportVideo:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition filePath:(NSURL *)filePath timeRange:(CMTimeRange)range completion:(void (^)(NSURL *savedPath))completion {
    
    //导出
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
    session.videoComposition = videoComposition;
    session.outputURL = filePath;
    session.shouldOptimizeForNetworkUse = YES;
    session.outputFileType = AVFileTypeMPEG4;//AVFileTypeQuickTimeMovie
    session.timeRange = range;
    [session exportAsynchronouslyWithCompletionHandler:^{
        if ([session status] == AVAssetExportSessionStatusCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(session.outputURL);
                    DLog(@"视频导出成功：%@", [session.outputURL path]);
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil);
                    DLog(@"视频导出失败：%@", [session.outputURL path]);
                }
            });
        }
    }];
}


/**
 配置文件路径
 
 @param fileName 文件名称
 @return 文件路径：..LZVideo/fileName
 */
+ (NSURL *)filePathWithFileName:(NSString *)fileName {
    return [self filePathWithFileName:fileName isFilter:NO];
}

/**
 配置文件路径
 
 @param fileName 文件名称
 @param isFilter 是否加滤镜
 @return 文件路径：..LZVideo/fileName
 */
+ (NSURL *)filePathWithFileName:(NSString *)fileName isFilter:(BOOL)isFilter{
    NSString *tempPath = @"";
    if (isFilter) {
        tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"LZVideoFilter"];
    }else{
        tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"LZVideo"];
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL exists = [manager fileExistsAtPath:tempPath isDirectory:NULL];
    if (!exists) {
        [manager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    tempPath = [tempPath stringByAppendingPathComponent:fileName];
    exists = [manager fileExistsAtPath:tempPath isDirectory:NULL];
    if (exists) {
        [manager removeItemAtPath:tempPath error:NULL];
    }
    return [NSURL fileURLWithPath:tempPath];
}

/**
 生成文件路径名称
 
 @param fileName 文件名
 @param isFilter 是否有滤镜（存了两份文件：有滤镜和无滤镜文件）
 @return 返回完整路径
 */
+ (NSURL *)getFilePathWithFileName:(NSString *)fileName isFilter:(BOOL)isFilter{
    NSString *tempPath = @"";
    if (isFilter) {
        tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"LZVideoFilter"];
    }else{
        tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"LZVideo"];
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL exists = [manager fileExistsAtPath:tempPath isDirectory:NULL];
    if (exists) {
        tempPath = [tempPath stringByAppendingPathComponent:fileName];
        exists = [manager fileExistsAtPath:tempPath isDirectory:NULL];
        if (exists) {
            return [NSURL fileURLWithPath:tempPath];
        }
    }
    
    return nil;
}

/**
 获取文件名称

 @param path 文件路径 如//file:///private/var/mobile/Containers/Data/Application/C91A7103-ED23-4578-AB00-DA59EEB36E86/tmp/LZVideo/Video-1.m4v
 @return 文件名称 如：Video-1
 */
+ (NSString *)getFileName:(NSString *)path {
    NSString *tempPath = @"";
    if ([path containsString:@"LZVideoFilter"]) {
        tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"LZVideoFilter"];
    } else {
        tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"LZVideo"];
    }
    
    NSString *fileName = @"";
    NSRange range = [path rangeOfString:@"Video-"];
    fileName = [path substringFromIndex:range.location];
    fileName = [fileName stringByReplacingOccurrencesOfString:@".m4v" withString:@""];
    return fileName;
}

/**
 视频、声音淡出

 @param segment 输入：LZSessionSegment
 @return 返回：AVPlayerItem
 */
+ (AVPlayerItem *)videoFadeOut:(LZSessionSegment *)segment {
//    1.将素材拖入到素材库中
    AVAsset *asset = segment.asset;
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];//素材的视频轨
    AVAssetTrack *audioAssertTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];//素材的音频轨
    
    
//    2.将素材的视频插入视频轨，音频插入音频轨
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];//这是工程文件
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];//视频轨道
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];//在视频轨道插入一个时间段的视频
    
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];//音频轨道
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:audioAssertTrack atTime:kCMTimeZero error:nil];//插入音频数据，否则没有声音
    
    
//    3.设置声音淡出时间
    CMTime start = CMTimeMake(composition.duration.value - composition.duration.timescale*1, composition.duration.timescale);
    CMTimeRange timeRange = CMTimeRangeFromTimeToTime(start, composition.duration);
    
    //视频淡出
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoAssetTrack];
    [layerInstruction setOpacityRampFromStartOpacity:1 toEndOpacity:0 timeRange:timeRange];
    
    //音频淡出
    AVMutableAudioMixInputParameters *parameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
    [parameters setVolumeRampFromStartVolume:1 toEndVolume:0 timeRange:timeRange];
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = @[parameters];//配置到播放器中
    
    
    
    //得到视频轨道
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration);
    instruction.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = @[instruction];
    videoComposition.renderSize = videoTrack.naturalSize;
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:composition];
    item.videoComposition = videoComposition;
    item.audioMix = audioMix;
    return item;
}

//视频速度
+ (AVPlayerItem *)videoSpeed:(LZSessionSegment *)segment scale:(CGFloat)scale{
//    1.将素材拖入到素材库中
    AVAsset *asset = segment.asset;
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];//素材的视频轨
    AVAssetTrack *audioAssertTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];//素材的音频轨
    
    
//    2.将素材的视频插入视频轨，音频插入音频轨
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];//这是工程文件
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];//视频轨道
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];//音频轨道

    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoAssetTrack atTime:kCMTimeZero error:nil];//在视频轨道插入一个时间段的视频
    [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:audioAssertTrack atTime:kCMTimeZero error:nil];//插入音频数据，否则没有声音
    
    // 根据速度比率调节音频和视频
    [videoTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(asset.duration.value, asset.duration.timescale)) toDuration:CMTimeMake(asset.duration.value / scale, asset.duration.timescale)];
    [audioTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(asset.duration.value, asset.duration.timescale)) toDuration:CMTimeMake(asset.duration.value / scale, asset.duration.timescale)];
    
    
//    3.设置淡出时间
    CMTime start = CMTimeMake(composition.duration.value - composition.duration.timescale*1, composition.duration.timescale);
    CMTimeRange timeRange = CMTimeRangeFromTimeToTime(start, composition.duration);
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoAssetTrack];
    [layerInstruction setOpacityRampFromStartOpacity:1 toEndOpacity:0 timeRange:timeRange];
    
    //得到视频轨道
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration);
    instruction.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.instructions = @[instruction];
    videoComposition.renderSize = videoTrack.naturalSize;
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:composition];
    item.videoComposition = videoComposition;
    return item;
}

@end
