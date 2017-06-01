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
}

@end

@implementation LZSession

- (id)init {
    self = [super init];
    if (self) {
        _segments = [[NSMutableArray alloc] init];
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

//- (void)initMovieWriter {
//    NSString *filename = [NSString stringWithFormat:@"LZVideoEditCut-%ld.m4v", (long)_segments.count];
//    _movieURL = [self filePathWithFileName:filename];
//    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:_movieURL size:CGSizeMake(480.0, 480.0)];
//    self.movieWriter.encodingLiveVideo = YES;
//}

//开始录制
- (void)startRecording{
    _currentFrame = 0;
    _currentSegmentDuration = kCMTimeZero;
    
//    [self initMovieWriter];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.movieWriter startRecording];
    });
    DLog(@"开始录制");
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
    _currentSegmentDuration = kCMTimeZero;
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
//    _segmentsDuration = CMTimeAdd(_segmentsDuration, self.sessionSegment.duration);

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
