//
//  LZAssetWriter.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/8.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZAssetWriter.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface LZAssetWriter ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (strong, nonatomic) dispatch_queue_t writeQueue;
@property (strong, nonatomic) NSURL *movieURL;
@property (assign, nonatomic) CGSize outputSize;
@property (assign, nonatomic) LZRecordState writeState;
@property (nonatomic, assign) BOOL canWrite;

@end

@implementation LZAssetWriter

- (instancetype)initWithSuperView:(UIView *)superView{
    self = [super init];
    if (self) {
        _superView = superView;
        
        ///1. 初始化捕捉会话，数据的采集都在会话中处理
        //        [self setUpInit];
        
        ///2. 设置视频的输入输出
        [self setUpVideo];
        
        ///3. 设置音频的输入输出
        [self setUpAudio];
        
        ///4. 视频的预览层
        [self setUpPreviewLayer];
        
        ///5. 开始采集画面
        [self.session startRunning];
        
        /// 6. 初始化writer， 用writer 把数据写入文件
        [self setUpWriter];
    }
    return self;
}

- (dispatch_queue_t)videoQueue {
    if (!_videoQueue) {
        _videoQueue = dispatch_queue_create("com.5miles", DISPATCH_QUEUE_SERIAL);
    }
    return _videoQueue;
}

- (AVCaptureVideoPreviewLayer *)previewlayer {
    if (!_previewLayer) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}

//1. 创建捕捉会话:需要确保在同一个队列，最好队列只创建一次
- (AVCaptureSession *)session {
    // 录制5秒钟视频 高画质10M,压缩成中画质 0.5M
    // 录制5秒钟视频 中画质0.5M,压缩成中画质 0.5M
    // 录制5秒钟视频 低画质0.1M,压缩成中画质 0.1M
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {//设置分辨率
            _session.sessionPreset = AVCaptureSessionPresetHigh;
        }
    }
    return _session;
}

//2.设置视频的输入 和 输出
- (void)setUpVideo {
    // 2.1 获取视频输入设备(摄像头)
    AVCaptureDevice *videoCaptureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//取得后置摄像头
    // 2.2 创建视频输入源
    NSError *error = nil;
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoCaptureDevice error:&error];
    // 2.3 将视频输入源添加到会话
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES; //立即丢弃旧帧，节省内存，默认YES
    [self.videoOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
    }
}

//3. 设置音频的输入 和 输出
- (void)setUpAudio {
    // 2.2 获取音频输入设备
    AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    NSError *error = nil;
    // 2.4 创建音频输入源
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
    // 2.6 将音频输入源添加到会话
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if([self.session canAddOutput:self.audioOutput]) {
        [self.session addOutput:self.audioOutput];
    }
}

//4. 添加视频预览层
- (void)setUpPreviewLayer{
    self.previewlayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenWidth);
    [_superView.layer insertSublayer:self.previewlayer atIndex:0];
}

//5. 开始采集画面

//6. 初始化AVAssetWriter:AVAssetWriter 写入数据的过程需要在子线程中执行，并且每次写入数据都需要保证在同一个线程。
- (void)setUpWriter{
    self.assetWriter = [AVAssetWriter assetWriterWithURL:_movieURL fileType:AVFileTypeQuickTimeMovie error:nil];
    
    NSDictionary *videoSet = @{AVVideoCodecKey:AVVideoCodecH264,
                               AVVideoWidthKey:[NSNumber numberWithInt:_outputSize.width],
                               AVVideoHeightKey:[NSNumber numberWithInt:_outputSize.height]
                               };
    NSDictionary *aodioSet = @{ AVEncoderBitRatePerChannelKey : @(28000),
                                AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                AVNumberOfChannelsKey : @(1),
                                AVSampleRateKey : @(22050) };
    
    self.assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoSet];
    self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
    self.assetWriterVideoInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);

    self.assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:aodioSet];
    self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;
    
    if ([_assetWriter canAddInput:self.assetWriterVideoInput]) {
        [_assetWriter addInput:self.assetWriterVideoInput];
    }
    if ([_assetWriter canAddInput:self.assetWriterAudioInput]) {
        [_assetWriter addInput:self.assetWriterAudioInput];
    }
    self.writeState = LZRecordStatePrepareRecording;
}

#pragma mark - 获取摄像头
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
//    CFRetain(sampleBuffer);
    dispatch_async(self.writeQueue, ^{
        if (self.writeState > LZRecordStateRecording){
            CFRelease(sampleBuffer);
            return;
        }
        
        if (!self.canWrite && captureOutput == self.videoOutput) {
            [self.assetWriter startWriting];
            [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
            self.canWrite = YES;
        }
        
        //            if (!_timer) {
        //                dispatch_async(dispatch_get_main_queue(), ^{
        //                    _timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
        //                });
        //            }
        
        //写入视频数据
        if (captureOutput == self.videoOutput) {
            if (self.assetWriterVideoInput.readyForMoreMediaData) {
                BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                if (!success) {
                    [self finishRecordingWithCompletionHandler:nil];
                    [self destroyWrite];
                }
            }
        }
        
        //写入音频数据
        if (captureOutput == self.audioOutput ) {
            if (self.assetWriterAudioInput.readyForMoreMediaData) {
                BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                if (!success) {
                    [self finishRecordingWithCompletionHandler:nil];
                    [self destroyWrite];
                }
            }
        }
        
//        CFRelease(sampleBuffer);
    } );
}

#pragma mark - writer
- (instancetype)initWithURL:(NSURL *)url size:(CGSize)newSize{
    self = [super init];
    if (self) {
        _movieURL = url;
        _outputSize = newSize;
        _writeQueue = dispatch_queue_create("com.5miles", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)startRecording{
    [self setUpWriter];
    
//    [self.assetWriter startWriting];
//    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
}

- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler{
    self.writeState = LZRecordStateFinish;
    
    __weak __typeof(self)weakSelf = self;
    if(_assetWriter && _assetWriter.status == AVAssetWriterStatusWriting){
        dispatch_async(self.writeQueue, ^{
            [_assetWriter finishWritingWithCompletionHandler:^{
                ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
                [lib writeVideoAtPathToSavedPhotosAlbum:weakSelf.movieURL completionBlock:nil];
                
            }];
        });
    }

    
//    [self.assetWriterVideoInput markAsFinished];
//    [self.assetWriterAudioInput markAsFinished];
//    [self.assetWriter finishWritingWithCompletionHandler:(handler ?: ^{})];
}

- (void)destroyWrite {
    self.assetWriter = nil;
    self.assetWriterAudioInput = nil;
    self.assetWriterVideoInput = nil;
    self.movieURL = nil;
//    self.recordTime = 0;
//    [self.timer invalidate];
//    self.timer = nil;
}

@end
