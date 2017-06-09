
#import "AVUtilities.h"
#import <AVFoundation/AVFoundation.h>

@implementation AVUtilities

+ (AVAsset *)assetByReversingAsset:(AVAsset *)asset outputURL:(NSURL *)outputURL progressHandle:(HKProgressHandle)progressHandle {
    NSError * error;

    AVAssetReader * reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    
    AVAssetTrack * videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    AVAssetTrack * audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] lastObject];
    
    NSDictionary * readerVideoOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],
                                           kCVPixelBufferPixelFormatTypeKey,
                                           nil];
    
    AVAssetReaderTrackOutput * readerVideoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                                              outputSettings:readerVideoOutputSettings];
    
    AVAssetReaderTrackOutput * readerAudioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack
                                                                                              outputSettings:nil];
    [reader addOutput:readerVideoOutput];
    [reader addOutput:readerAudioOutput];
    
    [reader startReading];
    
    NSMutableArray *samples_V_arrays = [[NSMutableArray alloc] init];
    
    CMSampleBufferRef sample_V;
    while((sample_V = [readerVideoOutput copyNextSampleBuffer])) {
        [samples_V_arrays addObject:(__bridge id)sample_V];
        CFRelease(sample_V);
    }
    
    DLog(@"samples_V_arrays: %lu", (unsigned long)samples_V_arrays.count);
    
    NSMutableArray *samples_A_arrays = [[NSMutableArray alloc] init];
    
    CMSampleBufferRef samples_A;
    while((samples_A = [readerAudioOutput copyNextSampleBuffer])) {
        [samples_A_arrays addObject:(__bridge id)samples_A];
        CFRelease(samples_A);
    }
    
    DLog(@"samples_A_arrays: %lu", (unsigned long)samples_A_arrays.count);

    AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:outputURL
                                                      fileType:AVFileTypeQuickTimeMovie
                                                         error:&error];
    
    NSParameterAssert(writer);
    
    NSDictionary * videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @(videoTrack.estimatedDataRate), AVVideoAverageBitRateKey,
                                           nil];
    
    NSDictionary * writerVideoOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:videoTrack.naturalSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:videoTrack.naturalSize.height], AVVideoHeightKey,
                                   videoCompressionProps, AVVideoCompressionPropertiesKey,
                                   nil];
    
    AVAssetWriterInput *writerVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                                          outputSettings:writerVideoOutputSettings
                                                                        sourceFormatHint:(__bridge CMFormatDescriptionRef)
                                            [videoTrack.formatDescriptions lastObject]];
    writerVideoInput.transform = videoTrack.preferredTransform;
    [writerVideoInput setExpectsMediaDataInRealTime:NO];
    
    NSParameterAssert(writerVideoInput);
    
    NSParameterAssert([writer canAddInput:writerVideoInput]);
    [writer addInput:writerVideoInput];
    
    AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:writerVideoInput
                                                                                                          sourcePixelBufferAttributes:nil];
    AudioChannelLayout acl;
    bzero( &acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    
    NSDictionary* writerAudioOutputSettings = nil;
    writerAudioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
                           [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                           [ NSNumber numberWithInt:64000], AVEncoderBitRateKey,
                           [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                           [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                           [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                           nil ];
    
    AVAssetWriterInput *writerAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                                                          outputSettings:writerAudioOutputSettings];
    [writerAudioInput setExpectsMediaDataInRealTime:NO];
    NSParameterAssert(writerAudioInput);
    
    NSParameterAssert([writer canAddInput:writerAudioInput]);
    [writer addInput:writerAudioInput];
    
    [writer startWriting];
    [writer startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp((__bridge CMSampleBufferRef)samples_V_arrays[0])];
    
    NSInteger counter = 0;

    for(NSInteger i = 0; i < samples_V_arrays.count; i++) {
        
        if (counter > samples_V_arrays.count - 1) {
            break;
        }

        CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp((__bridge CMSampleBufferRef)samples_V_arrays[i]);
        CVPixelBufferRef imageBufferRef = CMSampleBufferGetImageBuffer((__bridge CMSampleBufferRef)samples_V_arrays[samples_V_arrays.count - i - 1]);
        while (!writerVideoInput.readyForMoreMediaData) {
            [NSThread sleepForTimeInterval:0.1];
        }
        [pixelBufferAdaptor appendPixelBuffer:imageBufferRef withPresentationTime:presentationTime];
        
        progressHandle(((CGFloat)counter/(CGFloat)samples_V_arrays.count));
        counter++;
    }
    
    [writer finishWritingWithCompletionHandler:^{}];
    
    progressHandle(1.00);
    
    return [AVAsset assetWithURL:outputURL];
}

@end
