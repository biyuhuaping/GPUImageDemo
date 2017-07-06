//
//  LZMovieWriter.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/6.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZMovieWriter.h"
@interface LZMovieWriter ()
{
    NSURL *_movieURL;
    CGSize _outputSize;
    CMTime startTime, previousFrameTime, previousAudioTime;
}
@end

@implementation LZMovieWriter

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize {
    self = [super init];
    if (self) {
        _movieURL = newMovieURL;
        _outputSize = newSize;
        startTime = kCMTimeInvalid;
    }
    return self;
}

- (AVAssetWriter *)assetWriter{
    if (_assetWriter == nil) {
        _assetWriter = [AVAssetWriter assetWriterWithURL:_movieURL fileType:AVFileTypeQuickTimeMovie error:nil];
        
        NSDictionary *videoSet = @{AVVideoCodecKey:AVVideoCodecH264,
                                   AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                   AVVideoWidthKey:[NSNumber numberWithInt:_outputSize.width],
                                   AVVideoHeightKey:[NSNumber numberWithInt:_outputSize.height],
                                   };
        
        self.assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSet];
        self.assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        
        self.assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:nil];
        self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;
        
        if ([_assetWriter canAddInput:self.assetWriterVideoInput]) {
            [_assetWriter addInput:self.assetWriterVideoInput];
        }
        if ([_assetWriter canAddInput:self.assetWriterAudioInput]) {
            [_assetWriter addInput:self.assetWriterAudioInput];
        }
    }
    return _assetWriter;
}



- (void)startRecording{
//    startTime = kCMTimeInvalid;
//    [self.assetWriter startWriting];
//    [self.assetWriter startSessionAtSourceTime:self.startTime];
}

- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler{
    [self.assetWriterVideoInput markAsFinished];
    [self.assetWriterAudioInput markAsFinished];
    [self.assetWriter finishWritingWithCompletionHandler:^{
        handler();
        [self destroyWrite];
    }];
}

- (CMTime)duration {
    if( ! CMTIME_IS_VALID(startTime) )
        return kCMTimeZero;
    if( ! CMTIME_IS_NEGATIVE_INFINITY(previousFrameTime) )
        return CMTimeSubtract(previousFrameTime, startTime);
    if( ! CMTIME_IS_NEGATIVE_INFINITY(previousAudioTime) )
        return CMTimeSubtract(previousAudioTime, startTime);
    return kCMTimeZero;
}

- (void)destroyWrite {
    _assetWriter = nil;
    _assetWriterAudioInput = nil;
    _assetWriterVideoInput = nil;
    _movieURL = nil;
}

@end
