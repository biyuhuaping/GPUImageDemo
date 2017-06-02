//
//  LZSession.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/5/27.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"
#import "LZSessionSegment.h"

@interface LZSession : NSObject
//{
//    NSMutableArray *_segments;
//}

@property (strong, nonatomic) NSMutableArray * _Nullable segments;
@property (strong, nonatomic) NSURL * _Nullable movieURL;
@property (strong, nonatomic) GPUImageMovieWriter * _Nullable movieWriter; // 视频写入
//@property (strong, nonatomic) LZSessionSegment *sessionSegment;



/**
 The duration of the whole recordSession including the current recording segment
 and the previously added record segments.(整个recordSession的时长，包括当前记录的持续时间段和前面添的加记录)
 */
@property (readonly, nonatomic) CMTime duration;

/**
 The duration of the recorded record segments.(总时长)
 */
@property (readonly, atomic) CMTime segmentsDuration;

/**
 The duration of the current recording segment.(当前片段的时长)
 */
@property (readonly, atomic) CMTime currentSegmentDuration;

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
