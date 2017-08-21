//
//  LZRecordSession.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/5.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZRecordSession.h"
#import "LZVideoTools.h"

@interface LZRecordSession ()<GPUImageVideoCameraDelegateEx>
{
    CMTime _lastMovieFileOutputTime;
    CMTime _startTime;
    CMTime _endTime;
    CMTime _currentSegmentDuration;//当前片段的时长
}
@property (strong, nonatomic) dispatch_queue_t writeQueue;
@property (assign, nonatomic) BOOL canWrite;
@property (assign, nonatomic) BOOL stopWrite;

@end

@implementation LZRecordSession

- (id)init {
    self = [super init];
    if (self) {
        _segments = [[NSMutableArray alloc] init];
        _segmentsDuration = kCMTimeZero;
        
        _startTime = kCMTimeZero;
        _endTime = kCMTimeZero;
        
        _fileIndex = 0;
        
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
    [self _destroyAssetWriter];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, 0.125f, 1.f, .75f)];
    [cropFilter addTarget:self.movieWriter];
    [filter addTarget:cropFilter];
    [self.videoCamera addTarget:filter];
    
    //设置声音
    self.videoCamera.audioEncodingTarget = self.movieWriter;
}

- (GPUImageMovieWriter *)movieWriter {
    if (_movieWriter == nil) {
        _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.movieURL size:CGSizeMake(480.0, 480.0)];
    }
    return _movieWriter;
}

- (NSURL *)movieURL{
    if (_movieURL == nil) {
        NSString *filename = [NSString stringWithFormat:@"Video-%.f.m4v", _fileIndex];
        _movieURL = [LZVideoTools filePathWithFileName:filename];
    }
    return _movieURL;
}

- (AVAsset *)assetRepresentingSegments {
    AVAsset *asset = nil;
    AVMutableComposition *composition = [AVMutableComposition composition];
    [self appendSegmentsToComposition:composition audioMix:nil];
    asset = composition;
    return asset;
}

- (CMTime)duration {
    return CMTimeAdd(_segmentsDuration, _currentSegmentDuration);
}

- (double)fileIndex{
    return _fileIndex++;
}

#pragma mark - Action
//开始录制
- (void)startRecording{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.movieWriter startRecording];
        self.canWrite = YES;
        self.stopWrite = YES;
    });
    DLog(@"开始录制");
}

//结束录制
- (void)endRecordingFilter:(GPUImageOutput<GPUImageInput> * _Nullable)filter Completion:(void (^)(NSMutableArray * _Nullable segments))completion {
    [self.movieWriter finishRecordingWithCompletionHandler:^{
        [self appendRecordSegmentUrl:_movieURL filter:filter Completion:^(LZSessionSegment *segment) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //在主线程里更新UI
                completion(_segments);
            });
        }];
        self.stopWrite = NO;
    }];
    _fileIndex++;
}


#pragma mark -
- (void)appendRecordSegmentUrl:(NSURL *)url filter:(GPUImageOutput<GPUImageInput> * _Nullable)filter Completion:(void (^)(LZSessionSegment *))completion {
    LZSessionSegment *segment = nil;
    segment = [LZSessionSegment segmentWithURL:url filter:filter];
    [self addSegment:segment];
    [self _destroyAssetWriter];
    completion(segment);
}

- (void)addSegment:(LZSessionSegment *_Nullable)segment {
    [_segments addObject:segment];
    _segmentsDuration = CMTimeAdd(_segmentsDuration, segment.duration);
}

- (void)insertSegment:(LZSessionSegment *)segment atIndex:(NSInteger)segmentIndex {
    [_segments insertObject:segment atIndex:segmentIndex];
    _segmentsDuration = CMTimeAdd(_segmentsDuration, segment.duration);
}

- (void)replaceSegmentsAtIndex:(NSInteger)index withSegment:(LZSessionSegment *_Nullable)segment{
    [_segments replaceObjectAtIndex:index withObject:segment];
    CMTime segmentDuration = segment.duration;
    if (CMTIME_IS_VALID(segmentDuration)) {
//        NSLog(@"Removed duration of %fs", CMTimeGetSeconds(segmentDuration));
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
}

- (void)removeSegment:(LZSessionSegment *)segment {
    NSUInteger index = [_segments indexOfObject:segment];
    if (index != NSNotFound) {
        [self removeSegmentAtIndex:index deleteFile:NO];
    }
}

- (void)removeSegmentAtIndex:(NSInteger)segmentIndex{
    [self removeSegmentAtIndex:segmentIndex deleteFile:NO];
}

- (void)removeSegmentAtIndex:(NSInteger)segmentIndex deleteFile:(BOOL)deleteFile {
    LZSessionSegment *segment = [_segments objectAtIndex:segmentIndex];
    [_segments removeObjectAtIndex:segmentIndex];
    
    CMTime segmentDuration = segment.duration;
    
    if (CMTIME_IS_VALID(segmentDuration)) {
//        NSLog(@"Removed duration of %fs", CMTimeGetSeconds(segmentDuration));
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
            
            audioTime = [self _appendTrack:(recordSegment.isMute?nil:audioAssetTrack) toCompositionTrack:audioTrack atTime:audioTime withBounds:maxBounds];
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
        if (self.canWrite){
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            _startTime = startTime;
            self.canWrite = NO;
        }
        
        if ([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]]) {
            if (self.stopWrite) {
                _endTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                _currentSegmentDuration = CMTimeSubtract(_endTime, _startTime);
                DLog(@"%lld",_currentSegmentDuration.value/_currentSegmentDuration.timescale);
                if ([self.delegate respondsToSelector:@selector(didAppendVideoSampleBufferInSession:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate didAppendVideoSampleBufferInSession:CMTimeGetSeconds(self.duration)];
                    });
                }
            }
        }

        CFRelease(sampleBuffer);
    });
}

@end
