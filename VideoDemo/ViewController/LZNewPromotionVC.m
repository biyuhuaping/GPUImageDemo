//
//  LZNewPromotionVC.m
//  laziz_Merchant
//
//  Created by biyuhuaping on 2017/3/31.
//  Copyright © 2017年 XBN. All rights reserved.
//  视频录制页面

#import "LZNewPromotionVC.h"
#import "LZSelectVideoVC.h"
#import "LZVideoDetailsVC.h"//视频详情

#import "LZGridView.h"
#import "LZLevelView.h"
#import "RecordProgressView.h"
#import "LZButton.h"
#import "LZVideoEditCollectionViewCell.h"

//#import "SCRecorder.h"
//#import "SCRecordSessionManager.h"
//#import <AVFoundation/AVFoundation.h>

//#import <MobileCoreServices/MobileCoreServices.h>
//#import <MediaPlayer/MediaPlayer.h>

#import "ClearCacheTool.h"

#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "UINavigationController+FDFullscreenPopGesture.h"

#import "LZRecordSession.h"
#import "LZCameraFilterCollectionView.h"

@interface LZNewPromotionVC ()<LZRecorderDelegate,LZCameraFilterViewDelegate>

@property (strong, nonatomic) IBOutlet GPUImageView *filterView;
@property (strong, nonatomic) GPUImageOutput<GPUImageInput> *filter;
@property (strong, nonatomic) LZRecordSession *recordSession;


@property (strong, nonatomic) IBOutlet UIView *previewView;         //试映view
@property (strong, nonatomic) IBOutlet LZGridView *girdView;        //网格view
@property (strong, nonatomic) IBOutlet UIImageView *ghostImageView; //快照imageView
@property (strong, nonatomic) IBOutlet LZLevelView *levelView;      //水平仪view
@property (strong, nonatomic) IBOutlet RecordProgressView *progressView;    //进度条
//@property (strong, nonatomic) IBOutlet SCRecorderToolsView *focusView;

@property (strong, nonatomic) IBOutlet UIButton *recordBtn;         //录制按钮
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;      //删除按钮
@property (strong, nonatomic) IBOutlet UIButton *confirmButton;     //确认按钮
@property (strong, nonatomic) IBOutlet LZButton *gridOrlineButton;  //网格按钮
@property (strong, nonatomic) IBOutlet UIButton *snapshotButton;    //快照按钮

//recorder
//@property (nonatomic, strong) SCRecorder *recorder;
@property (nonatomic, strong) NSMutableArray *videoListSegmentArrays; //音频库

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *recordBtnWidth;

//titleView
@property (strong, nonatomic) UILabel *labelTime;//计时显示
@property (strong, nonatomic) UILabel *labelCount;//段数

@property (strong, nonatomic) IBOutlet UIView *maskView;//遮罩View
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *toTopDistance;
@property (strong, nonatomic) IBOutlet LZCameraFilterCollectionView *cameraFilterView;

@end

@implementation LZNewPromotionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.videoListSegmentArrays = [NSMutableArray array];    
    [_gridOrlineButton setLoopImages:@[[UIImage imageNamed:@"lz_recorder_grid"], [UIImage imageNamed:@"lz_recorder_grid_hd"], [UIImage imageNamed:@"lz_recorder_line_hd"]] ];
    
    [self configNavigationBar];
    
    self.recordBtn.layer.cornerRadius = 26;
    self.recordBtn.layer.masksToBounds = YES;
    
    self.recordSession = [[LZRecordSession alloc]init];
    self.recordSession.delegate = self;
    
    //显示view、freme
    [self.filterView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    
    //滤镜
    self.filter = [[GPUImageFilter alloc] init];
    [self.filter addTarget:self.filterView];

//    [self configGPUImageView];
    [self.recordSession initGPUImageView:self.filter];
    [self configCameraFilterView];
}

//- (void)configGPUImageView {
//    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, 0.125f, 1.f, .75f)];
//    [cropFilter addTarget:self.recordSession.movieWriterFilter];
//    [self.filter addTarget:cropFilter];
//    [self.filter addTarget:self.filterView];
//    [self.recordSession.videoCamera addTarget:self.filter];
//
////    //设置声音
//    self.recordSession.videoCamera.audioEncodingTarget = self.recordSession.movieWriterFilter;
//}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.recordSession.videoCamera startCameraCapture];
    [self updateGhostImage];
    [self updateProgressBar];
    [self enumVideoUrl];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
//    [_recorder previewViewFrameChanged];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    [self.recordSession.videoCamera startCameraCapture];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.recordSession.videoCamera stopCameraCapture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    //清除缓存
    [ClearCacheTool clearAction];
}

#pragma mark - configViews
//配置navi
- (void)configNavigationBar{
    UIImage *btn_image = [UIImage imageNamed:@"lz_new_rightbutton"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 40, 40);
    button.imageEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    button.selected = NO;
    [button setImage:btn_image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(navbarRightButtonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:button];
    
    UIView *dotView = [[UIView alloc]initWithFrame:CGRectMake(0, 20, 4, 4)];
    dotView.backgroundColor = [UIColor greenColor];
    dotView.layer.masksToBounds = YES;
    dotView.layer.cornerRadius = 2;
    
    
    UILabel *label1 = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, 48, 44)];
    label1.backgroundColor = [UIColor blackColor];
    label1.textAlignment = NSTextAlignmentCenter;
    label1.textColor = [UIColor whiteColor];
    label1.text = @"00:00";
    self.labelTime = label1;
    
    UILabel *label2 = [[UILabel alloc]initWithFrame:CGRectMake(64, 12, 20, 20)];
    label2.backgroundColor = [UIColor redColor];
    label2.textAlignment = NSTextAlignmentCenter;
    label2.layer.masksToBounds = YES;
    label2.layer.cornerRadius = 10;
    label2.adjustsFontSizeToFitWidth = YES;
    label2.text = @"1";
    self.labelCount = label2;
    
    UIView *titleView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 84, 44)];
    titleView.backgroundColor = [UIColor blackColor];
    titleView.center = self.navigationItem.titleView.center;

    [titleView addSubview:dotView];
    [titleView addSubview:label1];
    [titleView addSubview:label2];
    
    self.navigationItem.titleView = titleView;
    self.navigationItem.titleView.hidden = YES;
}

- (void)enumVideoUrl {
    [self.videoListSegmentArrays removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {//获取所有group
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {//从group里面
                NSString* assetType = [result valueForProperty:ALAssetPropertyType];
                if([assetType isEqualToString:ALAssetTypeVideo]){
//                    DLog(@"Video");
                    NSDictionary *assetUrls = [result valueForProperty:ALAssetPropertyURLs];
                    for (NSString *assetURLKey in assetUrls) {
                        LZSessionSegment * segment = [[LZSessionSegment alloc] initWithURL:assetUrls[assetURLKey] filter:nil];
                        [self.videoListSegmentArrays addObject:segment];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                       //在主线程里更新UI
                    });
//                    DLog(@"Representation Size = %lld",[[result defaultRepresentation]size]);
                }
            }];
        } failureBlock:^(NSError *error) {
//            DLog(@"Enumerate the asset groups failed.");
        }];
    });
}

//配置选择滤镜的CollectionView
- (void)configCameraFilterView {
    NSMutableArray *filterNameArray = [[NSMutableArray alloc] initWithCapacity:9];
    for (NSInteger index = 0; index < 10; index++) {
        UIImage *image = [UIImage imageNamed:@"18"];
        [filterNameArray addObject:image];
    }
    _cameraFilterView.cameraFilterDelegate = self;
    _cameraFilterView.picArray = filterNameArray;
}

//更新进度条
- (void)updateProgressBar {
//    if (CMTimeGetSeconds(self.recordSession.duration) >= 3) {
    if (self.recordSession.segments.count > 0) {
        self.confirmButton.enabled = YES;
    }else{
        self.confirmButton.enabled = NO;
        [self.progressView updateProgressWithValue:0];
        return;
    }
    
    CGFloat progress = 0;
    for (int i = 0; i < self.recordSession.segments.count; i++) {
        LZSessionSegment * segment = self.recordSession.segments[i];
        
        NSAssert(segment != nil, @"segment must be non-nil");
        CMTime currentTime = kCMTimeZero;
        if (segment) {
            currentTime = segment.duration;
            progress += CMTimeGetSeconds(currentTime) / MAX_VIDEO_DUR;
        }
    }
    [self.progressView updateProgressWithValue:progress];
}

- (void)changeToRecordStyle {
    [UIView animateWithDuration:0.25 animations:^{
        self.recordBtnWidth.constant = 28;
        self.recordBtn.layer.cornerRadius = 4;
        [self.view layoutIfNeeded];
    }];
}

- (void)changeToStopStyle {
    [UIView animateWithDuration:0.25 animations:^{
        self.recordBtnWidth.constant = 52;
        self.recordBtn.layer.cornerRadius = 26;
        [self.view layoutIfNeeded];
    }];
}

//更新快照
- (void)updateGhostImage {
    if (self.snapshotButton.selected && self.recordSession.segments.count > 0) {
        LZSessionSegment *segment = self.recordSession.segments.lastObject;
        self.ghostImageView.image = segment.lastImage;
        self.ghostImageView.hidden = NO;
    }else{
        self.ghostImageView.hidden = YES;
    }
}

#pragma mark - Event
- (void)navbarRightButtonClickAction:(UIButton*)sender {
    if (self.videoListSegmentArrays.count > 0) {
        LZSelectVideoVC *vc = [[LZSelectVideoVC alloc]initWithNibName:@"LZSelectVideoVC" bundle:nil];
        vc.recordSession = self.recordSession;
        vc.videoListSegmentArrays = self.videoListSegmentArrays;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"暂无可选视频" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

//滑动调整景深
- (IBAction)sliderAction:(UISlider *)sender {
//    _recorder.videoZoomFactor = sender.value;
    self.recordSession.videoCamera.videoZoomFactor = sender.value;
}

//取消/删除视频按钮
- (IBAction)cancelButton:(UIButton *)sender {
    if (sender.selected == NO && sender.enabled == YES) {//第一次按下删除按钮
        sender.selected = YES;
    }
    else if (sender.selected == YES) {//第二次按下删除按钮
        [self.recordSession removeLastSegment];
        [self updateProgressBar];
        [self updateGhostImage];
        if (self.recordSession.segments.count > 0) {
            sender.selected = NO;
            sender.enabled = YES;
        } else {
            sender.selected = NO;
            sender.enabled = NO;
            self.confirmButton.enabled = NO;
        }
    }
}

//开始录制按钮
- (IBAction)recordButton:(UIControl *)sender {
    if (sender.selected == NO) {
        self.ghostImageView.hidden = YES;
        self.cancelButton.enabled = NO;
        [self changeToRecordStyle];
        [self.recordSession startRecording];
    }else {
        self.cancelButton.enabled = YES;
        self.confirmButton.enabled = YES;
        [self changeToStopStyle];
        [self.recordSession endRecordingFilter:self.filter Completion:^(NSMutableArray<NSURL *> *segments) {
            DLog("===================== %@",segments);
            [self updateGhostImage];
            [self.recordSession initGPUImageView:self.filter];
        }];
    }
    self.fd_interactivePopDisabled = !sender.selected;
    self.maskView.hidden = sender.selected;
    self.navigationItem.titleView.hidden = sender.selected;
    self.navigationItem.hidesBackButton = !sender.selected;
    self.navigationItem.rightBarButtonItem.customView.hidden = !sender.selected;
    sender.selected = !sender.selected;
}

- (void)stopWrite {
    dispatch_async(dispatch_get_main_queue(), ^{
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        NSArray *segments = self.recordSession.segments;
        for (int i = 0; i < segments.count; i++) {
            LZSessionSegment *segment = (LZSessionSegment *)segments[i];
            NSURL *url = segment.url;
            DLog(@"+++++++:url:%@",url);
            
            if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:url]) {
                [library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error) {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            [alert show];
                        } else {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            [alert show];
                        }
                    });
                }];
            }
        }
    });
}

//确认按钮
- (IBAction)confirmButton:(UIButton *)sender {
    //视频详情
    LZVideoDetailsVC * vc = [[LZVideoDetailsVC alloc]initWithNibName:@"LZVideoDetailsVC" bundle:nil];
    vc.recordSession = self.recordSession;
    [self.navigationController pushViewController:vc animated:YES];
}

//show选择滤镜
- (IBAction)showChangeFilterView:(UIButton *)sender {
    [UIView animateWithDuration:0.25 animations:^{
        self.toTopDistance.constant = 0;
        [self.view layoutIfNeeded];
    }];
}

//hidden选择滤镜
- (IBAction)hiddenChangeFilterView:(id)sender {
    [UIView animateWithDuration:0.25 animations:^{
        self.toTopDistance.constant = 300;
        [self.view layoutIfNeeded];
    }];
}

//切换摄像头按钮
- (IBAction)turnCameraPositionButton:(UIButton *)sender {
    [UIView animateWithDuration:0.5 animations:^{
        CATransition *animation = [CATransition animation];
        animation.duration = 0.5f;
        animation.type = @"oglFlip";
        animation.subtype = kCATransitionFromLeft;
        animation.timingFunction = UIViewAnimationOptionCurveEaseInOut;
        [self.filterView.layer addAnimation:animation forKey:@"animation"];
    } completion:^(BOOL finished) {
        if (finished) {
            [self.recordSession switchCaptureDevices:_filter];
        }
    }];
}

//设置声音
- (IBAction)setVoice:(UIButton *)sender {
    sender.selected = !sender.selected;

    LZSessionSegment * segment = [self.recordSession.segments lastObject];
    //判断当前片段的声音设置
    segment.isMute = !segment.isMute;
}

//网格或线按钮
- (IBAction)gridOrlineButton:(LZButton *)sender {
    if (sender.currentIndex == 1) {
        self.girdView.hidden = NO;
    } else {
        self.girdView.hidden = YES;
    }
    
    if (sender.currentIndex == 2) {
        [self.levelView showLevelView];
    } else {
        [self.levelView hideLevelView];
    }
}

//快照按钮
- (IBAction)snapshotButton:(UIButton *)sender {
    sender.selected = !sender.selected;
    [self updateGhostImage];
}

//闪光按钮
- (IBAction)flashButton:(UIButton *)sender {
    if (sender.selected == NO) {
        sender.selected = YES;
        [self.recordSession.videoCamera setFlash:YES];
    }
    else {
        sender.selected = NO;
        [self.recordSession.videoCamera setFlash:NO];
    }
}


#pragma mark - 调整焦距方法
/*/调整焦距方法
-(void)focusDisdance:(UIPinchGestureRecognizer*)pinch {
    self.effectiveScale = self.beginGestureScale * pinch.scale;
    if (self.effectiveScale < 1.0f) {
        self.effectiveScale = 1.0f;
    }
    CGFloat maxScaleAndCropFactor = 3.0f;//设置最大放大倍数为3倍
    if (self.effectiveScale > maxScaleAndCropFactor)
        self.effectiveScale = maxScaleAndCropFactor;
    [CATransaction begin];
    [CATransaction setAnimationDuration:.025];
    NSError *error;
    if([self.cameraManager.inputCamera lockForConfiguration:&error]){
        [self.cameraManager.inputCamera setVideoZoomFactor:self.effectiveScale];
        [self.cameraManager.inputCamera unlockForConfiguration];
    }
    else {
        NSLog(@"ERROR = %@", error);
    }
    
    [CATransaction commit];
}

//手势代理方法
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}

#pragma mark - 对焦方法
//对焦方法
- (void)focus:(UITapGestureRecognizer *)tap {
    self.preview.userInteractionEnabled = NO;
    CGPoint touchPoint = [tap locationInView:tap.view];
    // CGContextRef *touchContext = UIGraphicsGetCurrentContext();
    [self layerAnimationWithPoint:touchPoint];
    //下面是照相机焦点坐标轴和屏幕坐标轴的映射问题，这个坑困惑了我好久，花了各种方案来解决这个问题，以下是最简单的解决方案也是最准确的坐标转换方式
    if(_cameraManager.cameraPosition == AVCaptureDevicePositionBack){
        touchPoint = CGPointMake( touchPoint.y /tap.view.bounds.size.height ,1-touchPoint.x/tap.view.bounds.size.width);
    }
    else
        touchPoint = CGPointMake(touchPoint.y /tap.view.bounds.size.height ,touchPoint.x/tap.view.bounds.size.width);
    //以下是相机的聚焦和曝光设置，前置不支持聚焦但是可以曝光处理，后置相机两者都支持，下面的方法是通过点击一个点同时设置聚焦和曝光，当然根据需要也可以分开进行处理

    if([self.cameraManager.inputCamera isExposurePointOfInterestSupported] && [self.cameraManager.inputCamera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
    {
        NSError *error;
        if ([self.cameraManager.inputCamera lockForConfiguration:&error]) {
            [self.cameraManager.inputCamera setExposurePointOfInterest:touchPoint];
            [self.cameraManager.inputCamera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            if ([self.cameraManager.inputCamera isFocusPointOfInterestSupported] && [self.cameraManager.inputCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                [self.cameraManager.inputCamera setFocusPointOfInterest:touchPoint];
                [self.cameraManager.inputCamera setFocusMode:AVCaptureFocusModeAutoFocus];
            }
            [self.cameraManager.inputCamera unlockForConfiguration];
        } else {
            NSLog(@"ERROR = %@", error);
        }
    }
}

//对焦动画
- (void)layerAnimationWithPoint:(CGPoint)point {
    if (_focusLayer) {
        ///聚焦点聚焦动画设置
        CALayer *focusLayer = _focusLayer;
        focusLayer.hidden = NO;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [focusLayer setPosition:point];
        focusLayer.transform = CATransform3DMakeScale(2.0f,2.0f,1.0f);
        [CATransaction commit];
        
        CABasicAnimation *animation = [ CABasicAnimation animationWithKeyPath: @"transform" ];
        animation.toValue = [ NSValue valueWithCATransform3D: CATransform3DMakeScale(1.0f,1.0f,1.0f)];
        animation.delegate = self;
        animation.duration = 0.3f;
        animation.repeatCount = 1;
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        [focusLayer addAnimation: animation forKey:@"animation"];
    }
}

//动画的delegate方法
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    //    1秒钟延时
    [self performSelector:@selector(focusLayerNormal) withObject:self afterDelay:0.5f];
}

//focusLayer回到初始化状态
- (void)focusLayerNormal {
    self.preview.userInteractionEnabled = YES;
    _focusLayer.hidden = YES;
}*/

#pragma mark - LZRecorderDelegate 更新进度条
- (void)didAppendVideoSampleBufferInSession:(Float64)time {
    CGFloat progress = time / MAX_VIDEO_DUR;
    [self.progressView updateProgressWithValue:progress];
    
    self.labelTime.text = [self timeFormatted:time];
    self.labelCount.text = [NSString stringWithFormat:@"%lu",self.recordSession.segments.count + 1];
}

//转换成时分秒
- (NSString *)timeFormatted:(int)totalSeconds{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    //    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

#pragma mark - cameraFilterView delegate
- (void)switchCameraFilter:(NSInteger)index {
    [self.recordSession.videoCamera removeAllTargets];
    
    switch (index) {
        case 0:
            _filter = [[GPUImageFilter alloc] init];//原图
            break;
        case 1:
            _filter = [[GPUImageHueFilter alloc] init];//绿巨人
            break;
        case 2:
            _filter = [[GPUImageColorInvertFilter alloc] init];//负片
            break;
        case 3:
            _filter = [[GPUImageSepiaFilter alloc] init];//老照片
            break;
        case 4:
            _filter = [[GPUImageToonFilter alloc] init];//卡通滤镜
            break;
        case 5:
            _filter = [[GPUImageSketchFilter alloc] init];//素描
            break;
        case 6:
            _filter = [[GPUImageVignetteFilter alloc] init];//黑晕
            break;
        case 7:
            _filter = [[GPUImageGrayscaleFilter alloc] init];//灰度
            break;
        case 8:
            _filter = [[GPUImageBilateralFilter alloc] init];
            break;
        case 9:
            _filter = [[GPUImageEmbossFilter alloc] init];//浮雕
            break;
    }
    
    [self.filter addTarget:self.filterView];
    [self.recordSession initGPUImageView:self.filter];
}

@end
