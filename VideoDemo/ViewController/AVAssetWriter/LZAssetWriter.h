//
//  LZAssetWriter.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/8.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//录制状态，（这里把视频录制与写入合并成一个状态）
typedef NS_ENUM(NSInteger, LZRecordState) {
    LZRecordStateInit = 0,
    LZRecordStatePrepareRecording,
    LZRecordStateRecording,
    LZRecordStateFinish,
    LZRecordStateFail,
};

@interface LZAssetWriter : NSObject

//1. 创建捕捉会话
//2. 设置视频的输入 和 输出
//3. 设置音频的输入 和 输出
//4. 添加视频预览层
//5. 开始采集数据，这个时候还没有写入数据，用户点击录制后就可以开始写入数据
//6. 初始化AVAssetWriter, 我们会拿到视频和音频的数据流，用AVAssetWriter写入文件，这一步需要我们自己实现。

@property (strong, nonatomic) AVCaptureSession *session;

@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureDeviceInput *audioInput;

@property (strong, nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property (strong, nonatomic) AVCaptureAudioDataOutput *audioOutput;

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;//预览View

@property (strong, nonatomic) AVAssetWriter *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput *assetWriterVideoInput;
@property (strong, nonatomic) AVAssetWriterInput *assetWriterAudioInput;

@property (weak, nonatomic) UIView *superView;

- (instancetype)initWithSuperView:(UIView *)superView;
- (instancetype)initWithURL:(NSURL *)url size:(CGSize)newSize;
- (void)startRecording;
- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler;

@end
