//
//  LZSession.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/5/27.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZSession.h"

@interface LZSession ()
{
    int32_t _currentFrame;
    CMTime _currentSegmentDuration;
}

@end

@implementation LZSession

- (id)init {
    self = [super init];
    if (self) {
        _segments = [[NSMutableArray alloc] init];
        _segmentsDuration = kCMTimeZero;
        _currentSegmentDuration = kCMTimeZero;
//        _sessionSegment = [[LZSessionSegment alloc]init];
//        [self initMovieWriter];
    }
    
    return self;
}

- (GPUImageMovieWriter *)movieWriter {
    if (_movieWriter == nil) {
        _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.movieURL size:CGSizeMake(480.0, 480.0)];
        _movieWriter.encodingLiveVideo = YES;
    }
    return _movieWriter;
}

- (NSURL *)movieURL{
    if (_movieURL == nil) {
        NSString *filename = [NSString stringWithFormat:@"LZVideoEdit-%ld.m4v", (long)_segments.count];
        _movieURL = [self filePathWithFileName:filename];
    }
    return _movieURL;
}

- (AVAsset *)assetRepresentingSegments {
    __block AVAsset *asset = nil;
    if (_segments.count == 1) {
        LZSessionSegment *segment = _segments.firstObject;
        asset = segment.asset;
    } else {
        AVMutableComposition *composition = [AVMutableComposition composition];
        [self appendSegmentsToComposition:composition audioMix:nil];
        
        asset = composition;
    }
    return asset;
}

- (CMTime)currentSegmentDuration {
    return _movieWriter.assetWriter.startWriting ? _movieWriter.duration : _currentSegmentDuration;
}

- (CMTime)duration {
    return CMTimeAdd(_segmentsDuration, [self currentSegmentDuration]);
}

#pragma mark -
//开始录制
- (void)startRecording{
    _currentFrame = 0;
//    _currentSegmentDuration = kCMTimeZero;
    
//    [self initMovieWriter];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.movieWriter startRecording];
//        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(ddd) userInfo:nil repeats:YES];
//        [self performSelectorInBackground:@selector(ddd) withObject:nil];
    });
    DLog(@"开始录制");
}

-(void)ddd{
    
//    [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
//        DLog(@"%f",CMTimeGetSeconds(self.movieWriter.duration));
//    }];
}

//结束录制
- (void)endRecordingFilter:(GPUImageOutput<GPUImageInput> * _Nullable)filter Completion:(void (^)(NSMutableArray * _Nullable segments))completion {
    DLog(@"保存地址：%@",_movieURL);
    dispatch_async(dispatch_get_main_queue(), ^{
        AVAssetWriter *writer = self.movieWriter.assetWriter;
//        [writer endSessionAtSourceTime:CMTimeAdd(self.currentSegmentDuration, kCMTimeZero)];
        DLog(@"writer.outputURL:----%@",writer.outputURL);
        
        [self.movieWriter finishRecordingWithCompletionHandler:^{
            [self appendRecordSegmentUrl:writer.outputURL filter:filter Completion:^(LZSessionSegment *segment) {
                completion(_segments);
            }];
        }];
    });
}

- (void)appendRecordSegmentUrl:(NSURL *)url filter:(GPUImageOutput<GPUImageInput> * _Nullable)filter Completion:(void (^)(LZSessionSegment *))completion {
    LZSessionSegment *segment = nil;
    segment = [LZSessionSegment segmentWithURL:url filter:filter];
    [self addSegment:segment];
    [self _destroyAssetWriter];
    completion(segment);
}

- (void)_destroyAssetWriter {
    _movieWriter = nil;
    _movieURL = nil;
//    _currentSegmentHasAudio = NO;
//    _currentSegmentHasVideo = NO;
//    _assetWriter = nil;
//    _lastTimeAudio = kCMTimeInvalid;
//    _lastTimeVideo = kCMTimeInvalid;
//    _currentSegmentDuration = kCMTimeZero;
//    _sessionStartTime = kCMTimeInvalid;
//    _movieFileOutput = nil;
}

//保存视频片段
- (void)saveSegment{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.movieWriter finishRecording];
    });
//    self.sessionSegment.url = _movieURL;
    [_segments addObject:_movieURL];

    DLog(@"保存地址：%@",_movieURL);
}

#pragma mark -
- (void)addSegment:(LZSessionSegment *)segment {
    [_segments addObject:segment];
    _segmentsDuration = CMTimeAdd(_segmentsDuration, segment.duration);
}

- (void)insertSegment:(LZSessionSegment *)segment atIndex:(NSInteger)segmentIndex {
    [_segments insertObject:segment atIndex:segmentIndex];
    _segmentsDuration = CMTimeAdd(_segmentsDuration, segment.duration);
}

- (void)removeSegment:(LZSessionSegment *)segment {
    NSUInteger index = [_segments indexOfObject:segment];
    if (index != NSNotFound) {
        [self removeSegmentAtIndex:index deleteFile:NO];
    }
}

- (void)removeSegmentAtIndex:(NSInteger)segmentIndex deleteFile:(BOOL)deleteFile {
        LZSessionSegment *segment = [_segments objectAtIndex:segmentIndex];
        [_segments removeObjectAtIndex:segmentIndex];
        
        CMTime segmentDuration = segment.duration;
        
        if (CMTIME_IS_VALID(segmentDuration)) {
//            NSLog(@"Removed duration of %fs", CMTimeGetSeconds(segmentDuration));
            _segmentsDuration = CMTimeSubtract(_segmentsDuration, segmentDuration);
        } else {
            CMTime newDuration = kCMTimeZero;
            for (LZSessionSegment *segment in _segments) {
                if (CMTIME_IS_VALID(segment.duration)) {
                    newDuration = CMTimeAdd(newDuration, segment.duration);
                }
            }
            _segmentsDuration = newDuration;
        }
        
        if (deleteFile) {
            [segment deleteFile];
        }
}

- (void)removeLastSegment {
    if (_segments.count > 0) {
        [self removeSegmentAtIndex:_segments.count - 1 deleteFile:YES];
    }
}

- (void)removeAllSegments {
    [self removeAllSegments:YES];
}

- (void)removeAllSegments:(BOOL)removeFiles {
    while (_segments.count > 0) {
        if (removeFiles) {
            LZSessionSegment *segment = [_segments objectAtIndex:0];
            [segment deleteFile];
        }
        [_segments removeObjectAtIndex:0];
    }
    _segmentsDuration = kCMTimeZero;
}

#pragma mark -


//- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex{
//    CMTime newTime = frameTime;
//    if (_timeOffset.value > 0) {
//        newTime = CMTimeSubtract(frameTime, _timeOffset);
//    }
//    if (newTime.value > _videoTimestamp.value) {
//        [self.movieWriter newFrameReadyAtTime:newTime atIndex:textureIndex];
//        _videoTimestamp = newTime;
//        _currentFrame++;
//    }
//}

- (void)appendSegmentsToComposition:(AVMutableComposition *)composition audioMix:(AVMutableAudioMix *)audioMix {
    AVMutableCompositionTrack *audioTrack = nil;
    AVMutableCompositionTrack *videoTrack = nil;
    
    int currentSegment = 0;
    CMTime currentTime = composition.duration;
    for (LZSessionSegment *recordSegment in _segments) {
        AVAsset *asset = recordSegment.asset;
        
        NSArray *audioAssetTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
        NSArray *videoAssetTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        
        CMTime maxBounds = kCMTimeInvalid;
        
        CMTime videoTime = currentTime;
        for (AVAssetTrack *videoAssetTrack in videoAssetTracks) {
            if (videoTrack == nil) {
                NSArray *videoTracks = [composition tracksWithMediaType:AVMediaTypeVideo];
                
                if (videoTracks.count > 0) {
                    videoTrack = [videoTracks firstObject];
                } else {
                    videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
                    videoTrack.preferredTransform = videoAssetTrack.preferredTransform;
                }
            }
            
            videoTime = [self _appendTrack:videoAssetTrack toCompositionTrack:videoTrack atTime:videoTime withBounds:maxBounds];
            maxBounds = videoTime;
        }
        
        CMTime audioTime = currentTime;
        for (AVAssetTrack *audioAssetTrack in audioAssetTracks) {
            if (audioTrack == nil) {
                NSArray *audioTracks = [composition tracksWithMediaType:AVMediaTypeAudio];
                
                if (audioTracks.count > 0) {
                    audioTrack = [audioTracks firstObject];
                } else {
                    audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
                }
            }
            
            audioTime = [self _appendTrack:audioAssetTrack toCompositionTrack:audioTrack atTime:audioTime withBounds:maxBounds];
        }
        
        currentTime = composition.duration;
        
        currentSegment++;
    }
}


- (CMTime)_appendTrack:(AVAssetTrack *)track toCompositionTrack:(AVMutableCompositionTrack *)compositionTrack atTime:(CMTime)time withBounds:(CMTime)bounds {
    CMTimeRange timeRange = track.timeRange;
    time = CMTimeAdd(time, timeRange.start);
    
    if (CMTIME_IS_VALID(bounds)) {
        CMTime currentBounds = CMTimeAdd(time, timeRange.duration);
        
        if (CMTIME_COMPARE_INLINE(currentBounds, >, bounds)) {
            timeRange = CMTimeRangeMake(timeRange.start, CMTimeSubtract(timeRange.duration, CMTimeSubtract(currentBounds, bounds)));
        }
    }
    
    if (CMTIME_COMPARE_INLINE(timeRange.duration, >, kCMTimeZero)) {
        NSError *error = nil;
        [compositionTrack insertTimeRange:timeRange ofTrack:track atTime:time error:&error];
        
        if (error != nil) {
            NSLog(@"Failed to insert append %@ track: %@", compositionTrack.mediaType, error);
        } else {
            //        NSLog(@"Inserted %@ at %fs (%fs -> %fs)", track.mediaType, CMTimeGetSeconds(time), CMTimeGetSeconds(timeRange.start), CMTimeGetSeconds(timeRange.duration));
        }
        
        return CMTimeAdd(time, timeRange.duration);
    }
    
    return time;
}











/**
 配置文件路径
 
 @param fileName 文件名称
 @return 文件路径：..LZVideo/fileName
 */
- (NSURL *)filePathWithFileName:(NSString *)fileName {
    NSString * tempPath = [tempPath = NSTemporaryDirectory() stringByAppendingPathComponent:@"LZVideo"];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL exists = [manager fileExistsAtPath:tempPath isDirectory:NULL];
    if (!exists) {
        [manager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    tempPath = [tempPath stringByAppendingPathComponent:fileName];
    if (exists) {
        [manager removeItemAtPath:tempPath error:NULL];
    }
    
    return [NSURL fileURLWithPath:tempPath];
}


@end
