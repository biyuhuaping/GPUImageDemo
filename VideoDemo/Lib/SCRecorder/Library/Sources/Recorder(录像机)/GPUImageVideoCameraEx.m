//
//  GPUImageVideoCameraEx.m
//  aikan
//
//  Created by lihejun on 14-1-13.
//  Copyright (c) 2014年 taobao. All rights reserved.
//

#import "GPUImageVideoCameraEx.h"

@implementation GPUImageVideoCameraEx

- (void)setFlash:(BOOL)flash
{
    self->_flash = flash;
    if (self.backFacingCameraPresent) {
        [GPUImageVideoCameraEx setTorch:_flash forCameraInPosition:AVCaptureDevicePositionBack];
    }
    else {
        [GPUImageVideoCameraEx setTorch:_flash forCameraInPosition:AVCaptureDevicePositionFront];
    }
}

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

+ (void)setTorch:(BOOL)torch forCameraInPosition:(AVCaptureDevicePosition)position
{
    if ([[self cameraInPosition:position] hasTorch]) {
        if ([[self cameraInPosition:position] lockForConfiguration:nil]) {
            if (torch)
            {
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

+ (AVCaptureDevice *)cameraInPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    
    return nil;
}

- (void)switchCaptureDevices {
    if (self.cameraPosition == AVCaptureDevicePositionBack) {
        self.cameraPosition = AVCaptureDevicePositionFront;
    } else {
        self.cameraPosition = AVCaptureDevicePositionBack;
    }
}

- (void)setCameraPosition:(AVCaptureDevicePosition)device {
    [self willChangeValueForKey:@"cameraPosition"];
    
//    if (_resetZoomOnChangeDevice) {
//        self.videoZoomFactor = 1;
//    }
//    if (_captureSession != nil) {
//        [self reconfigureVideoInput:self.videoConfiguration.enabled audioInput:NO];
//    }
    
    [self didChangeValueForKey:@"cameraPosition"];
}

#pragma mark - 重写AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    [self.delegateEx myCaptureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
    [super captureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
}

@end
