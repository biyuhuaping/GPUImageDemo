//
//  GPUImageVideoCameraEx.m
//  aikan
//
//  Created by lihejun on 14-1-13.
//  Copyright (c) 2014年 taobao. All rights reserved.
//

#import "GPUImageVideoCameraEx.h"

@implementation GPUImageVideoCameraEx
- (void)startCameraCapture{
    _status = GPUImageVideoCapturing;
    [super startCameraCapture];
}

- (void)pauseCameraCapture{
    _status = GPUImageVideoCapturePaused;
    [super pauseCameraCapture];
}

- (void)resumeCameraCapture{
    _status = GPUImageVideoCapturing;
    [super resumeCameraCapture];
}

- (void)stopCameraCapture{
    _status = GPUImageVideoCaptureStopped;
    [super stopCameraCapture];
}

//设置闪光灯
- (void)setFlash:(BOOL)flash {
    self->_flash = flash;
    if (self.backFacingCameraPresent) {
        [self setTorch:_flash forCameraInPosition:AVCaptureDevicePositionBack];
    }
    else {
        [self setTorch:_flash forCameraInPosition:AVCaptureDevicePositionFront];
    }
}

- (void)setTorch:(BOOL)torch forCameraInPosition:(AVCaptureDevicePosition)position {
    if ([[self cameraInPosition:position] hasTorch]) {
        if ([[self cameraInPosition:position] lockForConfiguration:nil]) {
            if (torch) {
                if ([[self cameraInPosition:position] isTorchModeSupported:AVCaptureTorchModeOn]) {
                    [[self cameraInPosition:position] setTorchMode:AVCaptureTorchModeOn];
                }
            } else {
                if ([[self cameraInPosition:position] isTorchModeSupported:AVCaptureTorchModeOff]) {
                    [[self cameraInPosition:position] setTorchMode:AVCaptureTorchModeOff];
                }
            }
            [[self cameraInPosition:position] unlockForConfiguration];
        }
    }
}

- (AVCaptureDevice *)cameraInPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    
    return nil;
}

- (void)setVideoZoomFactor:(CGFloat)videoZoomFactor {
//    AVCaptureDevice *device = [self cameraInPosition:AVCaptureDevicePositionBack];
    AVCaptureDevice *device = self.inputCamera;
    if ([device respondsToSelector:@selector(videoZoomFactor)]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            if (videoZoomFactor <= device.activeFormat.videoMaxZoomFactor) {
                device.videoZoomFactor = videoZoomFactor;
            } else {
                NSLog(@"Unable to set videoZoom: (max %f, asked %f)", device.activeFormat.videoMaxZoomFactor, videoZoomFactor);
            }
            
            [device unlockForConfiguration];
        } else {
            NSLog(@"Unable to set videoZoom: %@", error.localizedDescription);
        }
    }
}

#pragma mark - 重写AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    [super captureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
    [self.delegateEx myCaptureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
}

@end
