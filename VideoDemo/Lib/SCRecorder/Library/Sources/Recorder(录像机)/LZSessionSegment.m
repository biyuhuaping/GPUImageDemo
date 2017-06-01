//
//  LZSessionSegment.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/5/26.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZSessionSegment.h"
#import "LZSession.h"

@interface LZSessionSegment ()
{
    AVAsset *_asset;
    __weak UIImage *_thumbnail;
    __weak UIImage *_lastImage;
}

@end

@implementation LZSessionSegment

//- (instancetype)initWithDictionaryRepresentation:(NSDictionary *)dictionary directory:(NSString *)directory {
//    NSString *filename = dictionary[SCRecordSessionSegmentFilenameKey];
//    NSDictionary *info = dictionary[SCRecordSessionSegmentInfoKey];
//    
//    if (filename != nil) {
//        NSURL *url = [LZSessionSegment segmentURLForFilename:filename andDirectory:directory];
//        return [self initWithURL:url info:info];
//    }
//    
//    return nil;
//}

- (nonnull instancetype)initWithURL:(NSURL *__nonnull)url filter:(GPUImageOutput<GPUImageInput> * _Nullable)filter {
    self = [self init];
    if (self) {
        _url = url;
        _filter = filter;
    }
    return self;
}

+ (LZSessionSegment *)segmentWithURL:(NSURL *)url filter:(GPUImageOutput<GPUImageInput> * _Nullable)filter {
    return [[LZSessionSegment alloc] initWithURL:url filter:filter];
}

- (void)deleteFile {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:_url error:&error];
    _url = nil;
    _asset = nil;
}

- (AVAsset *)asset {
    if (_asset == nil) {
        _asset = [AVAsset assetWithURL:_url];
    }
    
    return _asset;
}

- (CMTime)duration {
    return [self asset].duration;
}

- (UIImage *)thumbnail {
    UIImage *image = _thumbnail;
    if (image == nil) {
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:self.asset];
        imageGenerator.appliesPreferredTrackTransform = YES;
        
        NSError *error = nil;
        CGImageRef thumbnailImage = [imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:nil error:&error];
        
        if (error == nil) {
            image = [UIImage imageWithCGImage:thumbnailImage];
            _thumbnail = image;
        } else {
            NSLog(@"Unable to generate thumbnail for %@: %@", self.url, error.localizedDescription);
        }
    }
    
    return image;
}

- (UIImage *)lastImage {
    UIImage *image = _lastImage;
    if (image == nil) {
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:self.asset];
        imageGenerator.appliesPreferredTrackTransform = YES;
        
        NSError *error = nil;
        CGImageRef lastImage = [imageGenerator copyCGImageAtTime:self.duration actualTime:nil error:&error];
        
        if (error == nil) {
            image = [UIImage imageWithCGImage:lastImage];
            _lastImage = image;
        } else {
            NSLog(@"Unable to generate lastImage for %@: %@", self.url, error.localizedDescription);
        }
    }
    
    return image;
}

- (float)frameRate {
    NSArray *tracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
    
    if (tracks.count == 0) {
        return 0;
    }
    
    AVAssetTrack *videoTrack = [tracks firstObject];
    
    return videoTrack.nominalFrameRate;
}

- (void)setUrl:(NSURL *)url {
    _url = url;
    _asset = nil;
}

- (BOOL)fileUrlExists {
    return [[NSFileManager defaultManager] fileExistsAtPath:self.url.path];
}

@end
