//
//  LZRecordSessionSegment.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/5/26.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZRecordSessionSegment.h"

@implementation LZRecordSessionSegment

- (instancetype)initWithURL:(NSURL *)url info:(NSDictionary *)info {
    self = [self init];
    if (self) {
        _url = url;
        _info = info;
    }
    return self;
}

+ (LZRecordSessionSegment *)segmentWithURL:(NSURL *)url info:(NSDictionary *)info {
    return [[LZRecordSessionSegment alloc] initWithURL:url info:info];
}

- (CMTime)duration {
    return [self asset].duration;
}

@end
