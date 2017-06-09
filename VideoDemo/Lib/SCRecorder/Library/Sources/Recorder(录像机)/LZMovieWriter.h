//
//  LZMovieWriter.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/6.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPUImageVideoCamera.h"

@interface LZMovieWriter : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

@property (strong, nonatomic) AVAssetWriter *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput *assetWriterAudioInput;
@property (strong, nonatomic) AVAssetWriterInput *assetWriterVideoInput;
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *adaptor;

//@property (strong, nonatomic) AVCaptureSession *session;
//@property (strong, nonatomic) AVCaptureVideoDataOutput *videoOutput;
//@property (strong, nonatomic) AVCaptureAudioDataOutput *audioOutput;


- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize;

- (void)startRecording;
- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler;

@end
