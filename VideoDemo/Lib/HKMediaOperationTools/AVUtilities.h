#import <Foundation/Foundation.h>

@class AVAsset;

typedef void(^HKProgressHandle)(CGFloat progress);

@interface AVUtilities : NSObject

+ (AVAsset *)assetByReversingAsset:(AVAsset *)asset outputURL:(NSURL *)outputURL progressHandle:(HKProgressHandle)progressHandle;

@end
