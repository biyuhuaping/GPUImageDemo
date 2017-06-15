//
//  LZRecordSession.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/5.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZRecordSession.h"

@interface LZRecordSession ()<GPUImageVideoCameraDelegateEx>
{
    CMTime _lastMovieFileOutputTime;
    CMTime _startTime;
    CMTime _endTime;
    CMTime _currentSegmentDuration;//当前片段的时长
}
@property (strong, nonatomic) dispatch_queue_t writeQueue;
@property (nonatomic, assign) BOOL canWrite;

@end

@implementation LZRecordSession

- (id)init {
    self = [super init];
    if (self) {
        _segments = [[NSMutableArray alloc] init];
        _segmentsDuration = kCMTimeZero;
        
        _startTime = kCMTimeZero;
        _endTime = kCMTimeZero;

        _writeQueue = dispatch_queue_create("LZWriteQueue", DISPATCH_QUEUE_SERIAL);
        [self initVideoCamera:AVCaptureDevicePositionBack];
    }
    
    return self;
}

- (void)initVideoCamera:(AVCaptureDevicePosition)position{
    _videoCamera = [[GPUImageVideoCameraEx alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:position];
    
    //输出方向为竖屏
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    [_videoCamera addAudioInputsAndOutputs];
    //相机开始运行
    [_videoCamera startCameraCapture];
    _videoCamera.delegateEx = self;
}

- (void)initGPUImageView:(GPUImageOutput<GPUImageInput> * _Nullable)filter {
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, 0.125f, 1.f, .75f)];
//    [cropFilter addTarget:self.movieWriter];
    [filter addTarget:cropFilter];
    [self.videoCamera addTarget:filter];
    
    //设置声音
//    self.videoCamera.audioEncodingTarget = self.movieWriterFilter;
}

//- (GPUImageMovieWriter *)movieWriterFilter {
//    if (_movieWriterFilter == nil) {
//        _movieWriterFilter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.movieURLFilter size:CGSizeMake(480.0, 480.0)];
//    }
//    return _movieWriterFilter;
//}

- (LZMovieWriter *)movieWriter {
    if (_movieWriter == nil) {
        _movieWriter = [[LZMovieWriter alloc] initWithMovieURL:self.movieURL size:CGSizeMake(480.0, 480.0)];
    }
    return _movieWriter;
}

- (NSURL *)movieURL{
    if (_movieURL == nil) {
        NSString *filename = [NSString stringWithFormat:@"LZVideoEdit-%ld.m4v", (long)_segments.count];
        _movieURL = [self filePathWithFileName:filename isFilter:NO];
    }
    return _movieURL;
}

//- (NSURL *)movieURLFilter{
//    if (_movieURLFilter == nil) {
//        NSString *filename = [NSString stringWithFormat:@"LZVideoEdit-%ld.m4v", (long)_segments.count];
//        _movieURLFilter = [self filePathWithFileName:filename isFilter:YES];
//    }
//    return _movieURLFilter;
//}

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

- (CMTime)duration {
    return CMTimeAdd(_segmentsDuration, _currentSegmentDuration);
}

#pragma mark - Action
//开始录制
- (void)startRecording{
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.movieWriterFilter startRecording];
        self.canWrite = YES;
    });
    DLog(@"开始录制");
}

- (void)updateProgress{
    if ([self.delegate respondsToSelector:@selector(didAppendVideoSampleBufferInSession:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate didAppendVideoSampleBufferInSession:CMTimeGetSeconds(self.duration)];
        });
    }
}

//结束录制
- (void)endRecordingFilter:(GPUImageOutput<GPUImageInput> * _Nullable)filter Completion:(void (^)(NSMutableArray * _Nullable segments))completion {
    DLog(@"保存地址：%@",_movieURL);
        AVAssetWriter *writer = self.movieWriter.assetWriter;
        DLog(@"writer.outputURL:----%@",filter);

        
//        [self.movieWriter finishRecordingWithCompletionHandler:^{
        [self finishRecordingWithCompletionHandler:^{
            [self appendRecordSegmentUrl:writer.outputURL filter:filter Completion:^(LZSessionSegment *segment) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //在主线程里更新UI
                    completion(_segments);
                });
            }];
        }];
    
//    [self.movieWriterFilter finishRecordingWithCompletionHandler:^{
//        [self appendRecordSegmentUrl:_movieURLFilter filter:filter Completion:^(LZSessionSegment *segment) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                //在主线程里更新UI
//                completion(_segmentsFilter);
//            });
//        }];
//    }];
}

- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler{
    [self.movieWriter.assetWriterVideoInput markAsFinished];
    [self.movieWriter.assetWriterAudioInput markAsFinished];
    [self.movieWriter.assetWriter finishWritingWithCompletionHandler:^{
        handler();
    }];
}

#pragma mark -
- (void)appendRecordSegmentUrl:(NSURL *)url filter:(GPUImageOutput<GPUImageInput> * _Nullable)filter Completion:(void (^)(LZSessionSegment *))completion {
    LZSessionSegment *segment = nil;
    segment = [LZSessionSegment segmentWithURL:url filter:filter];
    [self addSegment:segment];
    [self _destroyAssetWriter];
    completion(segment);
}

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


- (void)_destroyAssetWriter {
    _movieWriter = nil;
    _movieURL = nil;
    

//    _currentSegmentHasAudio = NO;
//    _currentSegmentHasVideo = NO;
//    _assetWriter = nil;
//    _lastTimeAudio = kCMTimeInvalid;
//    _lastTimeVideo = kCMTimeInvalid;
//    _sessionStartTime = kCMTimeInvalid;
//    _movieFileOutput = nil;
}








/**
 配置文件路径
 
 @param fileName 文件名称
 @param isFilter 是否加滤镜
 @return 文件路径：..LZVideo/fileName
 */
- (NSURL *)filePathWithFileName:(NSString *)fileName isFilter:(BOOL)isFilter{
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

#pragma mark -
#pragma mark 转置摄像头
- (void)switchCaptureDevices:(GPUImageOutput<GPUImageInput>*)filter {
    [self.videoCamera stopCameraCapture];
    if (self.videoCamera.cameraPosition == AVCaptureDevicePositionFront) {
        _videoCamera = [_videoCamera initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
    }
    else if(self.videoCamera.cameraPosition == AVCaptureDevicePositionBack) {
        _videoCamera = [_videoCamera initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionFront];
    }
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.videoCamera.horizontallyMirrorRearFacingCamera = NO;
    
    [self.videoCamera addTarget:filter];
    
    //    [self setBeginGestureScale:1.0f];//在转换摄像头的时候把摄像头的焦距调回1.0
    //    [self setEffectiveScale:1.0f];
    
    [self.videoCamera startCameraCapture];
}

#pragma mark - GPUImageVideoCameraDelegateEx
- (void)myCaptureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    CFRetain(sampleBuffer);
    dispatch_async(self.writeQueue, ^{
//        if (self.movieWriter.assetWriter == AVAssetWriterStatusUnknown) {
        if (self.canWrite){
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            _startTime = startTime;
            [self.movieWriter.assetWriter startWriting];
            [self.movieWriter.assetWriter startSessionAtSourceTime:startTime];
            self.canWrite = NO;
        }
        
        if ([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]]) {
            if (self.movieWriter.assetWriter.status == AVAssetWriterStatusWriting && [self.movieWriter.assetWriterVideoInput isReadyForMoreMediaData]) {
                [self.movieWriter.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                _endTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//                _currentSegmentDuration = CMTimeGetSeconds(CMTimeSubtract(_endTime, _startTime));
                _currentSegmentDuration = CMTimeSubtract(_endTime, _startTime);
                DLog(@"%lld",_currentSegmentDuration.value/_currentSegmentDuration.timescale);
                [self updateProgress];
            }
        }
        if ([captureOutput isKindOfClass:[AVCaptureAudioDataOutput class]]) {
            if (self.movieWriter.assetWriter.status == AVAssetWriterStatusWriting  && [self.movieWriter.assetWriterAudioInput isReadyForMoreMediaData]) {
                [self.movieWriter.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
            }
        }
        CFRelease(sampleBuffer);
    });
}

@end
