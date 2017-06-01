//
//  GPUImageMovieWriterEx.m
//  aikan
//
//  Created by lihejun on 14-1-14.
//  Copyright (c) 2014年 taobao. All rights reserved.
//

#import "GPUImageMovieWriterEx.h"

@interface GPUImageMovieWriterEx()
{
    int32_t _currentFrame;
    CMTime _timeOffset;
    CMTime _audioTimestamp;
	CMTime _videoTimestamp;
    // flags
    struct {
        unsigned int previewRunning:1;
        unsigned int changingModes:1;
        unsigned int readyForAudio:1;
        unsigned int readyForVideo:1;
        unsigned int recording:1;
        unsigned int isPaused:1;
        unsigned int interrupted:1;
        unsigned int videoWritten:1;
    } __block _flags;
}
@end
@implementation GPUImageMovieWriterEx

- (float)getProgress{
    if (self.maxFrames > 0) {
        return (float)_currentFrame / self.maxFrames;
    }
    return 0;
}

- (void)startRecording{
    self.started = YES;
    _flags.recording = YES;
    _currentFrame = 0;
    [super startRecording];
    DLog(@"开始录制");
}

- (BOOL)isPaused{
    return _flags.isPaused;
}

- (void)pauseRecording
{
    if (!self.assetWriter) {
        DLog(@"assetWriter 无法停止");
        return;
    }
    
    DLog(@"暂停视频录制");
    _flags.isPaused = YES;
    _flags.interrupted = YES;
}

- (void)resumeRecording
{
    if (!self.assetWriter) {
        DLog(@"assetWriter 无法恢复");
        return;
    }
    
    DLog(@"恢复视频录制");
    _flags.isPaused = NO;
}

- (void)finishRecording{
    if (!_flags.recording)
        return;
    
    if (!self.assetWriter) {
        DLog(@"assetWriter 无法结束");
        return;
    }
    
    if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
        DLog(@"asset writer 处于未知状态,没有录制");
        return;
    }
    
    _flags.recording = NO;
    _flags.isPaused = YES;
    [super finishRecording];
}

//处理音频缓冲
- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer{
    if (!CMSampleBufferDataIsReady(audioBuffer)) {
        DLog(@"样品缓冲数据没有准备好");
        //CFRelease(audioBuffer);
        return;
    }
    
    if (!_flags.recording || _flags.isPaused) {
        //CFRelease(audioBuffer);
        return;
    }
    // calculate the length of the interruption
    if (_flags.interrupted) {
        _flags.interrupted = NO;
        
        CMTime time = _audioTimestamp;
        // calculate the appropriate time offset
        if (CMTIME_IS_VALID(time)) {
            CMTime pTimestamp = CMSampleBufferGetPresentationTimeStamp(audioBuffer);
            if (CMTIME_IS_VALID(_timeOffset)) {
                pTimestamp = CMTimeSubtract(pTimestamp, _timeOffset);
            }
            
            CMTime offset = CMTimeSubtract(pTimestamp, _audioTimestamp);
            _timeOffset = (_timeOffset.value == 0) ? offset : CMTimeAdd(_timeOffset, offset);
            DLog(@"新计算出的偏移 %f 有效的 (%d)", CMTimeGetSeconds(_timeOffset), CMTIME_IS_VALID(_timeOffset));
        } else {
            DLog(@"无效的音频的时间戳,没有抵消更新");
        }
        
        _audioTimestamp.flags = 0;
        _videoTimestamp.flags = 0;
        
    }
    CMSampleBufferRef bufferToWrite = NULL;
    if (_timeOffset.value > 0) {
        bufferToWrite = [self _createOffsetSampleBuffer:audioBuffer withTimeOffset:_timeOffset];
        if (!bufferToWrite) {
//            DLog(@"error subtracting the timeoffset from the sampleBuffer");
        }
    } else {
        bufferToWrite = audioBuffer;
        CFRetain(bufferToWrite);
    }
    if (bufferToWrite && _flags.videoWritten) {
        // update the last audio timestamp
        CMTime time = CMSampleBufferGetPresentationTimeStamp(bufferToWrite);
        CMTime duration = CMSampleBufferGetDuration(bufferToWrite);
        if (duration.value > 0)
            time = CMTimeAdd(time, duration);
        
        if (time.value > _audioTimestamp.value) {
            [super processAudioBuffer:bufferToWrite]; //pass to super 传递给父类
            _audioTimestamp = time;
        }
        CFRelease(bufferToWrite);
    }
    
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex{
    if (!_flags.recording || _flags.isPaused) {
        return;
    }
    
    if (!_flags.interrupted) {
        CMTime newTime = frameTime;
        if (_timeOffset.value > 0) {
            newTime = CMTimeSubtract(frameTime, _timeOffset);
        }
        if (newTime.value > _videoTimestamp.value) {
            [super newFrameReadyAtTime:newTime atIndex:textureIndex];
            _videoTimestamp = newTime;
            _flags.videoWritten = YES;
            
            /*
             if (self.currentFrame % 10 == 0) {
             [self convertImageFromSampleBuffer:bufferToWrite];
             }
             */
            _currentFrame++;
        }
    }
}


- (CMSampleBufferRef)_createOffsetSampleBuffer:(CMSampleBufferRef)sampleBuffer withTimeOffset:(CMTime)timeOffset
{
    CMItemCount itemCount;
    
    OSStatus status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, NULL, &itemCount);
    if (status) {
//        DLog(@"couldn't determine the timing info count");
        return NULL;
    }
    
    CMSampleTimingInfo *timingInfo = (CMSampleTimingInfo *)malloc(sizeof(CMSampleTimingInfo) * (unsigned long)itemCount);
    if (!timingInfo) {
//        DLog(@"couldn't allocate timing info");
        return NULL;
    }
    
    status = CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, itemCount, timingInfo, &itemCount);
    if (status) {
        free(timingInfo);
        timingInfo = NULL;
//        DLog(@"failure getting sample timing info array");
        return NULL;
    }
    
    for (CMItemCount i = 0; i < itemCount; i++) {
        timingInfo[i].presentationTimeStamp = CMTimeSubtract(timingInfo[i].presentationTimeStamp, timeOffset);
        timingInfo[i].decodeTimeStamp = CMTimeSubtract(timingInfo[i].decodeTimeStamp, timeOffset);
    }
    
    CMSampleBufferRef outputSampleBuffer;
    CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, sampleBuffer, itemCount, timingInfo, &outputSampleBuffer);
    
    if (timingInfo) {
        free(timingInfo);
        timingInfo = NULL;
    }
    
    return outputSampleBuffer;
}

//- (UIImage *)imageFromPixBuffer:(CVPixelBufferRef)pixelBuffer{
//    size_t w = CVPixelBufferGetWidth(pixelBuffer);
//    size_t h = CVPixelBufferGetHeight(pixelBuffer);
//    size_t r = CVPixelBufferGetBytesPerRow(pixelBuffer);
//    size_t bytesPerPixel = r/w;
//    
//    unsigned char *buffer = CVPixelBufferGetBaseAddress(pixelBuffer);
//    
//    UIGraphicsBeginImageContext(CGSizeMake(w, h));
//    
//    CGContextRef c = UIGraphicsGetCurrentContext();
//    
//    unsigned char* data = CGBitmapContextGetData(c);
//    if (data != NULL) {
//        int maxY = h;
//        for(int y = 0; y<maxY; y++) {
//            for(int x = 0; x<w; x++) {
//                int offset = bytesPerPixel*((w*y)+x);
//                data[offset] = buffer[offset];     // R
//                data[offset+1] = buffer[offset+1]; // G
//                data[offset+2] = buffer[offset+2]; // B
//                data[offset+3] = buffer[offset+3]; // A
//            }
//        }
//    } 
//    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
//    
//    UIGraphicsEndImageContext();
//    return img;
//}

@end
