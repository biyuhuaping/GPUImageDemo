//
//  LZRecordSession.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/5.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"
#import "GPUImageVideoCameraEx.h"
#import "LZSessionSegment.h"
#import "LZMovieWriter.h"

@class LZRecordSession;
@protocol LZRecorderDelegate <NSObject>
@optional
- (void)didAppendVideoSampleBufferInSession:(Float64)time;
@end

@interface LZRecordSession : NSObject

@property (strong, nonatomic) GPUImageVideoCameraEx * _Nullable videoCamera;
@property (strong, nonatomic) LZMovieWriter * _Nullable movieWriter;
@property (strong, nonatomic) NSMutableArray * _Nullable segments;
@property (strong, nonatomic) NSURL * _Nullable movieURL;

@property (strong, nonatomic) GPUImageMovieWriter * _Nullable movieWriterFilter;
@property (strong, nonatomic) NSURL * _Nullable movieURLFilter;


@property (weak, nonatomic) id<LZRecorderDelegate> __nullable delegate;
@property (readwrite, nonatomic) double fileIndex;

/**
 The duration of the whole recordSession including the current recording segment
 and the previously added record segments.(总时长)
 */
@property (readonly, nonatomic) CMTime duration;

/**
 The duration of the recorded record segments.
 */
@property (readonly, atomic) CMTime segmentsDuration;

/**
 Returns an asset representing all the record segments
 from this record session. This can be called anytime.
 */
- (AVAsset *__nonnull)assetRepresentingSegments;

- (void)initGPUImageView:(GPUImageOutput<GPUImageInput> * _Nullable)filter;


//开始录制
- (void)startRecording;

//结束录制
- (void)endRecordingFilter:(GPUImageOutput<GPUImageInput> * _Nullable)filter Completion:(void (^_Nullable)(NSMutableArray * _Nullable segments))completion;

#pragma mark -
- (void)addSegment:(LZSessionSegment *_Nullable)segment;
- (void)insertSegment:(LZSessionSegment *_Nullable)segment atIndex:(NSInteger)segmentIndex;
- (void)replaceSegmentsAtIndex:(NSInteger)index withSegment:(LZSessionSegment *_Nullable)segment;
- (void)removeSegmentAtIndex:(NSInteger)segmentIndex;
- (void)removeSegmentAtIndex:(NSInteger)segmentIndex deleteFile:(BOOL)deleteFile;
- (void)removeLastSegment;
- (void)removeAllSegments;
- (void)removeAllSegments:(BOOL)removeFiles;

#pragma mark -
- (void)switchCaptureDevices:(GPUImageOutput<GPUImageInput>*_Nullable)filter;

@end
