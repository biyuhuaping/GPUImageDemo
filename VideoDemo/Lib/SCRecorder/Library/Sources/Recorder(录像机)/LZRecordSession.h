//
//  LZRecordSession.h
//  VideoDemo
//
//  Created by biyuhuaping on 2017/5/26.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImageMovieWriter.h"
#import "LZRecordSessionSegment.h"

@interface LZRecordSession : NSObject
{
    NSMutableArray *_segments;
    AVAssetWriter *_assetWriter;
    CMTime _currentSegmentDuration;
    CMTime _sessionStartTime;

}

/**
 The duration of the recorded record segments.
 */
@property (readonly, atomic) CMTime segmentsDuration;

/**
 Add a recorded segment.
 */
- (void)addSegment:(LZRecordSessionSegment *__nonnull)segment;


@end
