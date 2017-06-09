//
//  LZRecordSession.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/5.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"
#import "LZSessionSegment.h"
#import "LZMovieWriter.h"

@class LZRecordSession;
@protocol LZRecorderDelegate <NSObject>
@optional
- (void)didAppendVideoSampleBufferInSession:(LZRecordSession *_Nullable)recordSession;
@end

@interface LZRecordSession : NSObject

@property (strong, nonatomic) GPUImageVideoCamera * _Nullable videoCamera;
@property (strong, nonatomic) LZMovieWriter * _Nullable movieWriter;

@property (strong, nonatomic) NSMutableArray * _Nullable segments;
@property (strong, nonatomic) NSURL * _Nullable movieURL;
@property (weak, nonatomic) id<LZRecorderDelegate> __nullable delegate;

/**
 The duration of the recorded record segments.(总时长)
 */
@property (readonly, atomic) CMTime segmentsDuration;

/**
 Returns an asset representing all the record segments
 from this record session. This can be called anytime.
 */
- (AVAsset *__nonnull)assetRepresentingSegments;








//开始录制
- (void)startRecording;

//结束录制
- (void)endRecordingFilter:(GPUImageOutput<GPUImageInput> * _Nullable)filter Completion:(void (^_Nullable)(NSMutableArray * _Nullable segments))completion;

#pragma mark -
- (void)removeLastSegment;

@end
