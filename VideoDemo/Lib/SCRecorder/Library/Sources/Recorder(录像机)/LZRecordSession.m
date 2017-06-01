//
//  LZRecordSession.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/5/26.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZRecordSession.h"

@implementation LZRecordSession


- (void)addSegment:(LZRecordSessionSegment *)segment {
//    [self dispatchSyncOnSessionQueue:^{
        [_segments addObject:segment];
        _segmentsDuration = CMTimeAdd(_segmentsDuration, segment.duration);
//    }];
}

- (void)appendRecordSegmentUrl:(NSURL *)url info:(NSDictionary *)info error:(NSError *)error completionHandler:(void (^)(LZRecordSessionSegment *, NSError *))completionHandler {
//    [self dispatchSyncOnSessionQueue:^{
        LZRecordSessionSegment *segment = nil;
        
        if (error == nil) {
            segment = [LZRecordSessionSegment segmentWithURL:url info:info];
            [self addSegment:segment];
        }
        
//        [self _destroyAssetWriter];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler != nil) {
                completionHandler(segment, error);
            }
        });
//    }];
}

- (BOOL)endSegmentWithInfo:(NSDictionary *)info completionHandler:(void(^)(LZRecordSessionSegment *segment, NSError* error))completionHandler {
    __block BOOL success = NO;
    
//    [self dispatchSyncOnSessionQueue:^{
//        dispatch_sync(_audioQueue, ^{
//            if (_recordSegmentReady) {
//                _recordSegmentReady = NO;
                success = YES;
                
                AVAssetWriter *writer = _assetWriter;
                
//                if (writer != nil) {
//                    if (currentSegmentEmpty) {
//                        [writer cancelWriting];
////                        [self _destroyAssetWriter];
//                        
//                        [self removeFile:writer.outputURL];
//                        
//                        if (completionHandler != nil) {
//                            dispatch_async(dispatch_get_main_queue(), ^{
//                                completionHandler(nil, nil);
//                            });
//                        }
//                    } else {
//                        NSLog(@"Ending session at %fs", CMTimeGetSeconds(_currentSegmentDuration));
                        [writer endSessionAtSourceTime:CMTimeAdd(_currentSegmentDuration, _sessionStartTime)];
                        
                        [writer finishWritingWithCompletionHandler: ^{
                            [self appendRecordSegmentUrl:writer.outputURL info:info error:writer.error completionHandler:completionHandler];
                        }];
//                    }
//                } else {
//                    [_movieFileOutput stopRecording];
//                }
//            } else {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (completionHandler != nil) {
//                        completionHandler(nil, [LZRecordSession createError:@"The current record segment is not ready for this operation"]);
//                    }
//                });
//            }
//        });
//    }];

    return success;
}

+ (NSError*)createError:(NSString*)errorDescription {
    return [NSError errorWithDomain:@"LZRecordSession" code:200 userInfo:@{NSLocalizedDescriptionKey : errorDescription}];
}

@end
