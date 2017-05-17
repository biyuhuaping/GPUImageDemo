//
//  HKMediaOperationTools.m
//  YeahMV
//
//  Created by HuangKai on 15/12/18.
//  Copyright © 2015年 QiuShiBaiKe. All rights reserved.
//

#import "HKMediaOperationTools.h"

@implementation HKMediaOperationTools

+ (AVAsset *)assetByReversingAsset:(AVAsset *)asset videoComposition:(AVMutableVideoComposition *)videoComposition duration:(CMTime)duration outputURL:(NSURL *)outputURL progressHandle:(HKProgressHandle)progressHandle cancle:(BOOL *)cancle {
    
    if (*(cancle)) {
        return nil;
    }
    
    NSError *error;
    
    //获取视频的总轨道
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    
    //按照每秒一个视频的长度，分割轨道，生成对应的时间范围
    NSMutableArray *timeRangeVideoArray = [NSMutableArray array];
    
    NSMutableArray *startTimeArray = [NSMutableArray array];

    CMTime startTime = kCMTimeZero;
    
    for (NSInteger i = 0; i <(CMTimeGetSeconds(duration)); i ++) {
        
        CMTimeRange timeRange = CMTimeRangeMake(startTime, CMTimeMakeWithSeconds(1, duration.timescale));
        
        //视频
        if (CMTimeRangeContainsTimeRange(videoTrack.timeRange, timeRange)) {
            [timeRangeVideoArray addObject:[NSValue valueWithCMTimeRange:timeRange]];
        }
        else {
            timeRange = CMTimeRangeMake(startTime, CMTimeSubtract(duration, startTime));
            [timeRangeVideoArray addObject:[NSValue valueWithCMTimeRange:timeRange]];
        }
        
        [startTimeArray addObject:[NSValue valueWithCMTime:startTime]];
        startTime = CMTimeAdd(timeRange.start, timeRange.duration);
    }
    
    NSMutableArray *videoTracks = [NSMutableArray array];
    NSMutableArray *assets = [NSMutableArray array];
    
    for (NSInteger i = 0; i < timeRangeVideoArray.count; i ++) {
        
        //AVMutableComposition 对象主要是音频和视频组合
        AVMutableComposition *subAsset = [AVMutableComposition composition];
        
        //视频
        AVMutableCompositionTrack *subVideoTrack = [subAsset addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                         preferredTrackID:kCMPersistentTrackID_Invalid];
        [subVideoTrack insertTimeRange:[timeRangeVideoArray[i] CMTimeRangeValue]
                               ofTrack:videoTrack
                                atTime:[startTimeArray[i] CMTimeValue]
                                 error:nil];

        AVAsset *assetNew = [subAsset copy];
        
        AVAssetTrack *assetTrackVideo = [[assetNew tracksWithMediaType:AVMediaTypeVideo] lastObject];
        [videoTracks addObject:assetTrackVideo];
        [assets addObject:assetNew];
    }
    
    NSDictionary * videoReaderOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],
                                               kCVPixelBufferPixelFormatTypeKey,
                                               nil];
    
    AVAssetReaderOutput *videoReaderOutput = nil;
    
    if (videoComposition) {
        videoReaderOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:@[videoTrack]
                                                                                                    videoSettings:videoReaderOutputSettings];
        ((AVAssetReaderVideoCompositionOutput *)videoReaderOutput).videoComposition = videoComposition;
    }
    else {
        videoReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                       outputSettings:videoReaderOutputSettings];
    }
    
    AVAssetReader *totalReader = nil;
    
    totalReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    
    if([totalReader canAddOutput:videoReaderOutput]){
        [totalReader addOutput:videoReaderOutput];
    }
    else {
        return nil;
    }
    
    [totalReader startReading];
    
    NSMutableArray *sampleTimes = [NSMutableArray array];
    CMSampleBufferRef totalSample;
    
    while((totalSample = [videoReaderOutput copyNextSampleBuffer])) {
        CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(totalSample);
        [sampleTimes addObject:[NSValue valueWithCMTime:presentationTime]];
        CFRelease(totalSample);
    }
    
    //配置Writer
    AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:outputURL
                                                      fileType:AVFileTypeQuickTimeMovie
                                                         error:&error];
    
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @(videoTrack.estimatedDataRate), AVVideoAverageBitRateKey,
                                           nil];
    
    CGFloat width = videoTrack.naturalSize.width;
    CGFloat height = videoTrack.naturalSize.height;
    
    if (videoComposition) {
        width = videoComposition.renderSize.width;
        width = videoComposition.renderSize.height;
    }

    NSDictionary * writerVideoOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                          AVVideoCodecH264, AVVideoCodecKey,
                                          [NSNumber numberWithInt:height], AVVideoHeightKey,
                                          [NSNumber numberWithInt:width], AVVideoWidthKey,
                                          videoCompressionProps, AVVideoCompressionPropertiesKey,
                                          nil];
    
    //写入视频
    AVAssetWriterInput * writerVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                                     outputSettings:writerVideoOutputSettings
                                                                   sourceFormatHint:(__bridge CMFormatDescriptionRef)[videoTrack.formatDescriptions lastObject]];
    
    writerVideoInput.transform = videoTrack.preferredTransform;
    [writerVideoInput setExpectsMediaDataInRealTime:NO];
    
    // Initialize an input adaptor so that we can append PixelBuffer
    AVAssetWriterInputPixelBufferAdaptor *vidioAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:writerVideoInput
                                                                                                          sourcePixelBufferAttributes:nil];
    [writer addInput:writerVideoInput];
    
    [writer startWriting];
    [writer startSessionAtSourceTime:videoTrack.timeRange.start];
    
    NSInteger counter = 0;
    size_t countOfFrames = 0;
    size_t totalCountOfArray = 40;
    size_t arrayIncreasment = 40;
    CMSampleBufferRef *sampleBufferRefs = (CMSampleBufferRef *) malloc(totalCountOfArray * sizeof(CMSampleBufferRef *));
    memset(sampleBufferRefs, 0, sizeof(CMSampleBufferRef *) * totalCountOfArray);
    
    for (NSInteger i=videoTracks.count -1; i<=videoTracks.count; i--) {
        
        if (*(cancle)) {
            [writer cancelWriting];
            free(sampleBufferRefs);
            return nil;
        }
        
        AVAssetReader *reader = nil;
        
        countOfFrames = 0;
        
        AVAssetReaderOutput *readerVideoOutput = nil;
        
        if (videoComposition) {
            readerVideoOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:@[videoTracks[i]]
                                                                                                   videoSettings:videoReaderOutputSettings];
            ((AVAssetReaderVideoCompositionOutput *)readerVideoOutput).videoComposition = videoComposition;
        }
        else {
            readerVideoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTracks[i]
                                                                      outputSettings:videoReaderOutputSettings];
        }
        
        reader = [[AVAssetReader alloc] initWithAsset:assets[i] error:&error];
        if([reader canAddOutput:readerVideoOutput]){
            [reader addOutput:readerVideoOutput];
        }
        else {
            break;
        }

        [reader startReading];
        
        CMSampleBufferRef sample;
        while((sample = [readerVideoOutput copyNextSampleBuffer])) {
            
            CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sample);
            
            if (CMTIME_COMPARE_INLINE(presentationTime, >=, [startTimeArray[i] CMTimeValue])) {
                
                if (countOfFrames  + 1 > totalCountOfArray) {
                    totalCountOfArray += arrayIncreasment;
                    sampleBufferRefs = (CMSampleBufferRef *)realloc(sampleBufferRefs, totalCountOfArray);
                }
                
                *(sampleBufferRefs + countOfFrames) = sample;
                
                countOfFrames++;
            }
            else {
                if (sample != NULL) {
                    CFRelease(sample);
                }
            }
        }
        
        [reader cancelReading];
        
        for(NSInteger j = 0; j < countOfFrames; j++) {
            // Get the presentation time for the frame
            if (counter > sampleTimes.count - 1) {
                break;
            }
            
            CMTime presentationTime = [sampleTimes[counter] CMTimeValue];
            
            // take the image/pixel buffer from tail end of the array
            CMSampleBufferRef bufferRef = *(sampleBufferRefs + countOfFrames - j - 1);
            CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer(bufferRef);
            
            while (!writerVideoInput.readyForMoreMediaData) {
                [NSThread sleepForTimeInterval:0.1];
            }
            
            [vidioAdaptor appendPixelBuffer:imageBufferRef withPresentationTime:presentationTime];

            progressHandle(((CGFloat)counter/(CGFloat)sampleTimes.count));
            
            counter++;
            
            CFRelease(bufferRef);
            *(sampleBufferRefs + countOfFrames - j - 1) = NULL;
        }
    }
    
    free(sampleBufferRefs);
    
//    [writer finishWriting];
    [writer finishWritingWithCompletionHandler:^{
        progressHandle(1.0);
    }];
    
    return [AVAsset assetWithURL:outputURL];
}
@end
