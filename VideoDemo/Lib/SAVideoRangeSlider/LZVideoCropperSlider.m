//
//  LZVideoCropperSlider.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/26.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZVideoCropperSlider.h"
#import "LZImageView.h"

@interface LZVideoCropperSlider ()

@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic, strong) UIView * bgView;
@property (nonatomic, strong) UIView * centerView;
@property (nonatomic, strong) UIImageView * dragView;
@property (nonatomic, strong) NSURL * videoUrl;

@property (nonatomic, strong) UIImageView * rightThumb;

@property (nonatomic) CGFloat frame_width;
@property (nonatomic) Float64 durationSeconds;

@end

@implementation LZVideoCropperSlider
#define SLIDER_BORDERS_SIZE 2.0f
#define BG_VIEW_BORDERS_SIZE 2.0f

- (id)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize{
    _frame_width = SCREEN_WIDTH;
    CGFloat height = self.bounds.size.height;
    _rightPosition = _frame_width/2;
    
    _bgView = [[UIControl alloc] initWithFrame:CGRectMake(0, 10, _frame_width, height-20)];
    _bgView.clipsToBounds = YES;
    [self addSubview:_bgView];
    
//    _centerView = [[UIView alloc] initWithFrame:self.bounds];
//    _centerView.backgroundColor = UIColorFromRGB(0x000000, 0.5);
//    [self addSubview:_centerView];

    
    //right Thumb
    _rightThumb = [[LZImageView alloc] initWithFrame:CGRectMake(0, 0, 9.5, 73)];
    _rightThumb.userInteractionEnabled = YES;
    _rightThumb.image = [UIImage imageNamed:@"分割内容"];
    [self addSubview:_rightThumb];
    
    UIPanGestureRecognizer *rightPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightPan:)];
    [_rightThumb addGestureRecognizer:rightPan];
}

- (void)delegateNotification {
    if ([_delegate respondsToSelector:@selector(videoRange:didChangePosition:)]){
        [_delegate videoRange:self didChangePosition:self.rightPosition];
    }
}

#pragma mark - Gestures

- (void)handleRightPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan ||
        gesture.state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gesture translationInView:self];
        _rightPosition += translation.x;
        if (_rightPosition < 0) {
            _rightPosition = 0;
        }
        
        if (_rightPosition > _frame_width){
            _rightPosition = _frame_width;
        }
        
        if (_rightPosition <= 0){
            _rightPosition -= translation.x;
        }
        
        if ((_rightPosition <= _rightThumb.frame.size.width) ||
            ((self.maxGap > 0) && (self.rightPosition > self.maxGap)) ||
            ((self.minGap > 0) && (self.rightPosition < self.minGap)) ) {
            _rightPosition -= translation.x;
        }
        
        [gesture setTranslation:CGPointZero inView:self];
        [self setNeedsLayout];
        
        [self delegateNotification];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _rightThumb.center = CGPointMake(_rightPosition, CGRectGetMaxY(_rightThumb.frame) / 2);
    _centerView.frame = CGRectMake(0, _centerView.frame.origin.y, _rightThumb.frame.origin.x, _centerView.frame.size.height);
    _dragView.center = CGPointMake(_centerView.frame.size.width/2, _centerView.frame.size.height/2);
}

#pragma mark - Video

- (void)getMovieFrame:(NSURL *)videoUrl{
    AVAsset *myAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    [self getMovieFrameWithAsset:myAsset];
}

- (void)getMovieFrameWithAsset:(AVAsset *)myAsset{
    if ([self.bgView subviews].count > 0) {
        for (UIView * v in [self.bgView subviews]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [v removeFromSuperview];
            });
        }
    }
    
    //    AVAsset *myAsset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:myAsset];
    
    if ([self isRetina]){
        self.imageGenerator.maximumSize = CGSizeMake(self.bgView.frame.size.width * 2, self.bgView.frame.size.height * 2);
    } else {
        self.imageGenerator.maximumSize = CGSizeMake(self.bgView.frame.size.width, self.bgView.frame.size.height);
    }
    
    int picWidth = 20;
    
    // First image
    CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:NULL error:NULL];
    if (halfWayImage != NULL) {
        UIImage *videoScreen;
        if ([self isRetina]) {
            videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationRight];
        } else {
            videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
        }
        
        UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
        CGRect rect = tmp.frame;
        rect.size.width = picWidth;
        tmp.frame = rect;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.bgView addSubview:tmp];
        });
        
        picWidth = tmp.frame.size.width;
        CGImageRelease(halfWayImage);
    }
    
    self.durationSeconds = CMTimeGetSeconds([myAsset duration]);
    
    int picsCnt = ceil(self.bgView.frame.size.width/picWidth);//返回大于或者等于指定表达式的最小整数
    
    NSMutableArray *allTimes = [[NSMutableArray alloc] init];
    
    int time4Pic = 0;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        
        int prefreWidth = 0;
        
        for (int i=1, ii=1; i<=picsCnt; i++){
            
            time4Pic = i*picWidth;
            
            CMTime timeFrame = CMTimeMakeWithSeconds(self.durationSeconds*time4Pic/self.bgView.frame.size.width, 600);
            
            [allTimes addObject:[NSValue valueWithCMTime:timeFrame]];
            
            CGImageRef halfWayImage = [self.imageGenerator copyCGImageAtTime:timeFrame actualTime:NULL error:NULL];
            
            UIImage *videoScreen;
            if ([self isRetina]) {
                videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:2.0 orientation:UIImageOrientationRight];
            } else {
                videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
            }
            
            UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
            
            CGRect currentFrame = tmp.frame;
            currentFrame.origin.x = ii*picWidth;
            
            currentFrame.size.width = picWidth;
            prefreWidth += currentFrame.size.width;
            
            tmp.frame = currentFrame;
            int all = (ii+1)*tmp.frame.size.width;
            
            if (all > self.bgView.frame.size.width) {
                int delta = all - self.bgView.frame.size.width;
                currentFrame.size.width -= delta;
            }
            
            ii++;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.bgView addSubview:tmp];
            });
            
            CGImageRelease(halfWayImage);
        }
    }
}

#pragma mark - Properties
- (CGFloat)rightPosition {
    return _rightPosition * _durationSeconds / _frame_width;
}

- (void)setNewRightPosition:(CGFloat)newrightPosition {
    
    if (newrightPosition == 0) {
        _rightPosition = _frame_width;
    } else {
        _rightPosition = newrightPosition * _frame_width / _durationSeconds;
    }
    
    [self setNeedsLayout];
}

#pragma mark - Helpers

- (BOOL)isRetina {
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale == 2.0));
}


@end
