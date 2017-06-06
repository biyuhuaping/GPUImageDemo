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
    if ((self = [super init]))
    {
        _assetWriter = [AVAssetWriter assetWriterWithURL:newMovieURL fileType:AVFileTypeQuickTimeMovie error:nil];
        assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:nil];
        assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:nil];
        assetWriterAudioInput.expectsMediaDataInRealTime = YES;
        
        if ([_assetWriter canAddInput:assetWriterVideoInput]) {
            [_assetWriter addInput:assetWriterVideoInput];
        }
        if ([_assetWriter canAddInput:assetWriterAudioInput]) {
            [_assetWriter addInput:assetWriterAudioInput];
        }
        
        
        
//        assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:nil];
//        assetWriterVideoInput.expectsMediaDataInRealTime = YES;
//        [_assetWriter addInput:assetWriterVideoInput];
//        
//        
//        assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:nil];
//        [_assetWriter addInput:assetWriterAudioInput];
//        assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    }
    return nil;
}

- (void)startRecording;{
    [self.assetWriter startWriting];
    //    [assetWriter startSessionAtSourceTime:kCMTimeZero];
}

- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler{
    [assetWriterVideoInput markAsFinished];
    [assetWriterAudioInput markAsFinished];
    [self.assetWriter finishWritingWithCompletionHandler:(handler ?: ^{ })];
}

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
