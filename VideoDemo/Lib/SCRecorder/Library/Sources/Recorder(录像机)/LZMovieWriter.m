//
//  LZMovieWriter.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/6.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZMovieWriter.h"

@implementation LZMovieWriter

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize {
    self = [super init];
    if (self) {
        _assetWriter = [AVAssetWriter assetWriterWithURL:newMovieURL fileType:AVFileTypeQuickTimeMovie error:nil];
        
        NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
        [settings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
        [settings setObject:[NSNumber numberWithInt:newSize.width] forKey:AVVideoWidthKey];
        [settings setObject:[NSNumber numberWithInt:newSize.height] forKey:AVVideoHeightKey];
        
        assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:settings];
        assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:nil];
        assetWriterAudioInput.expectsMediaDataInRealTime = YES;
        
        if ([_assetWriter canAddInput:assetWriterVideoInput]) {
            [_assetWriter addInput:assetWriterVideoInput];
        }
        if ([_assetWriter canAddInput:assetWriterAudioInput]) {
            [_assetWriter addInput:assetWriterAudioInput];
        }
        
    }
    return self;
}

- (void)startRecording;{
    [self.assetWriter startWriting];
    //    [assetWriter startSessionAtSourceTime:kCMTimeZero];
    [self dddd];
}

- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler{
    [assetWriterVideoInput markAsFinished];
    [assetWriterAudioInput markAsFinished];
    [self.assetWriter finishWritingWithCompletionHandler:(handler ?: ^{})];
}

//首先先准备好AVCaptureSession，当录制开始后，可以控制调用相关回调来取音视频的每一贞数据。
- (void)dddd {
    NSError * error;
    
    self.session = [[AVCaptureSession alloc] init];
    [self.session beginConfiguration];
    [self.session setSessionPreset:AVCaptureSessionPreset640x480];
    [self initVideoAudioWriter];
    
    AVCaptureDevice * videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    AVCaptureDevice * audioDevice1 = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput1 = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice1 error:&error];
    
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self.videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
//numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    [self.audioOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [self.session addInput:videoInput];
    [self.session addInput:audioInput1];
    [self.session addOutput:self.videoOutput];
    [self.session addOutput:self.audioOutput];
    [self.session commitConfiguration];
    [self.session startRunning];
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
        [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
    }
    
    if (self.videoWriterInput.readyForMoreMediaData) {
        [self.videoWriterInput appendSampleBuffer:sampleBuffer];
    }
    
    if (self.audioWriterInput.readyForMoreMediaData) {
        [self.audioWriterInput appendSampleBuffer:sampleBuffer];
    }
    
    
    /*/CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    static int frame = 0;
    CMTime lastSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if( frame == 0 && self.assetWriter.status != AVAssetWriterStatusWriting){
        [self.assetWriter startWriting];
        [self.assetWriter startSessionAtSourceTime:lastSampleTime];
    }
    if (captureOutput == self.videoOutput){
        if(self.assetWriter.status > AVAssetWriterStatusWriting){
            NSLog(@"Warning: writer status is %ld", (long)self.assetWriter.status);
            if(self.assetWriter.status == AVAssetWriterStatusFailed )
                NSLog(@"Error: %@", self.assetWriter.error);
            return;
        }
        
        if ([self.videoWriterInput isReadyForMoreMediaData])
            if( ![self.videoWriterInput appendSampleBuffer:sampleBuffer] )
                NSLog(@"无法写入视频输入");
            else
                NSLog(@"已经写的视频");
    }else if (captureOutput == self.audioOutput){
        if(self.assetWriter.status > AVAssetWriterStatusWriting ){
            NSLog(@"Warning: writer status is %d", self.assetWriter.status);
            if(self.assetWriter.status == AVAssetWriterStatusFailed )
                NSLog(@"Error: %@", self.assetWriter.error);
            return;
        }
        
        if ([self.audioWriterInput isReadyForMoreMediaData])
            if( ![self.audioWriterInput appendSampleBuffer:sampleBuffer] )
                NSLog(@"无法写入视频输入");
            else{
                NSLog(@"已经写的视频");
            }
    }*/
}

- (void)captureOutput1:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

//    if let assetWriter = assetWriter where assetWriter.status == AVAssetWriterStatus.Unknown {
//        assetWriter.startWriting()
//        assetWriter.startSessionAtSourceTime(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
//    }
//    if connection == self.videoConnection {
//        dispatch_async(videoDataOutputQueue, { () -> Void in
//            if let videoWriterInput = self.videoWriterInput where videoWriterInput.readyForMoreMediaData {
//                videoWriterInput.appendSampleBuffer(sampleBuffer)
//            }
//        })
//    }
//    else if connection == self.audioConnection {
//        dispatch_async(audioDataOutputQueue, { () -> Void in
//            if let audioWriterInput = self.audioWriterInput where audioWriterInput.readyForMoreMediaData {
//                audioWriterInput.appendSampleBuffer(sampleBuffer)
//            }
//        })
//    }
//    objc_sync_exit(self)
}


//剩下的工作就是初始化AVAssetWriter，包括音频与视频输入输出：
- (void)initVideoAudioWriter{
    CGSize size = CGSizeMake(480, 320);
    NSString *betaCompressionDirectory = [NSHomeDirectory()stringByAppendingPathComponent:@"Documents/Movie.mp4"];

    NSError *error = nil;
    
    unlink([betaCompressionDirectory UTF8String]);
    
    
    
    //----initialize compression engine
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:betaCompressionDirectory] fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(self.assetWriter);
    
    if(error)
        NSLog(@"error = %@", [error localizedDescription]);
    NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:128.0*1024.0],AVVideoAverageBitRateKey,nil];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, [NSNumber numberWithInt:size.width], AVVideoWidthKey, [NSNumber numberWithInt:size.height],AVVideoHeightKey,videoCompressionProps, AVVideoCompressionPropertiesKey, nil];
    
    self.videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSParameterAssert(self.videoWriterInput);
    
    self.videoWriterInput.expectsMediaDataInRealTime = YES;
    
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    NSParameterAssert(self.videoWriterInput);
    NSParameterAssert([self.assetWriter canAddInput:self.videoWriterInput]);
    
    
    
    if ([self.assetWriter canAddInput:self.videoWriterInput]){
        NSLog(@"I can add this input");
    }else{
        NSLog(@"i can't add this input");
    }
    
    
    // Add the audio input
    
    AudioChannelLayout acl;
    bzero( &acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    NSDictionary* audioOutputSettings = nil;
    
    //    audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
    //                           [ NSNumber numberWithInt: kAudioFormatAppleLossless ], AVFormatIDKey,
    //                           [ NSNumber numberWithInt: 16 ], AVEncoderBitDepthHintKey,
    //                           [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
    //                           [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
    //                           [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
    //                           nil ];
    
    audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
                           [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                           [ NSNumber numberWithInt:64000], AVEncoderBitRateKey,
                           [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                           [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                           [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                           nil ];
    
    
    
    self.audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType: AVMediaTypeAudio outputSettings: audioOutputSettings ];
    self.audioWriterInput.expectsMediaDataInRealTime = YES;
    
    // add input
    [self.assetWriter addInput:self.audioWriterInput];
    [self.assetWriter addInput:self.videoWriterInput];
}

@end
