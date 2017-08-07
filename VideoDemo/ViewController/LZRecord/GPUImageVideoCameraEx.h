//
//  GPUImageVideoCameraEx.h
//  aikan
//
//  Created by lihejun on 14-1-13.
//  Copyright (c) 2014年 taobao. All rights reserved.
//

#import "GPUImageVideoCamera.h"

typedef enum {
    GPUImageVideoCaptureNone,
    GPUImageVideoCapturing,
    GPUImageVideoCapturePaused,
    GPUImageVideoCaptureStopped
}GPUImageVideoStatus;

@protocol GPUImageVideoCameraDelegateEx <NSObject>

@optional
- (void)myCaptureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
@end

@interface GPUImageVideoCameraEx : GPUImageVideoCamera
@property (assign, nonatomic) id<GPUImageVideoCameraDelegateEx> delegateEx;
@property (assign, nonatomic, getter = isFlash)BOOL flash;
@property (assign, nonatomic) GPUImageVideoStatus status;
@property (assign, nonatomic) CGFloat videoZoomFactor;

@end
