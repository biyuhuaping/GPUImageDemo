//
//  LZNewPromotionVC.m
//  laziz_Merchant
//
//  Created by biyuhuaping on 2017/3/31.
//  Copyright © 2017年 XBN. All rights reserved.
//  视频录制页面

#import "LZNewPromotionVC.h"
#import "LZSelectVideoViewController.h"
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
#import "GPUImageVideoCameraEx.h"
#import "GPUImageMovieWriterEx.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "UINavigationController+FDFullscreenPopGesture.h"

#import "LZSession.h"

@interface LZNewPromotionVC ()<SCRecorderDelegate>

@property (strong, nonatomic) IBOutlet GPUImageView *filterView;
@property (strong, nonatomic) GPUImageOutput<GPUImageInput> *filter;
@property (strong, nonatomic) GPUImageVideoCameraEx *videoCamera;
//@property (strong, nonatomic) GPUImageMovieWriterEx *movieWriter;
@property (strong, nonatomic) LZSession *session;


@property (strong, nonatomic) IBOutlet UIView *previewView;         //试映view
@property (strong, nonatomic) IBOutlet LZGridView *girdView;        //网格view
@property (strong, nonatomic) IBOutlet UIImageView *ghostImageView; //快照imageView
@property (strong, nonatomic) IBOutlet LZLevelView *levelView;      //水平仪view
@property (strong, nonatomic) IBOutlet RecordProgressView *progressView;    //进度条
@property (strong, nonatomic) IBOutlet SCRecorderToolsView *focusView;

@property (strong, nonatomic) IBOutlet UIButton *recordBtn;         //录制按钮
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;      //删除按钮
@property (strong, nonatomic) IBOutlet UIButton *confirmButton;     //确认按钮
@property (strong, nonatomic) IBOutlet LZButton *gridOrlineButton;  //网格按钮
@property (strong, nonatomic) IBOutlet UIButton *snapshotButton;    //快照按钮

//recorder
@property (nonatomic, strong) SCRecorder *recorder;
@property (nonatomic, strong) NSMutableArray *videoListSegmentArrays; //音频库

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *recordBtnWidth;

//titleView
@property (strong, nonatomic) UILabel *labelTime;//计时显示
@property (strong, nonatomic) UILabel *labelCount;//段数

@property (strong, nonatomic) IBOutlet UIView *maskView;//遮罩View
@end

@implementation LZNewPromotionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.videoListSegmentArrays = [NSMutableArray array];    
    [_gridOrlineButton setLoopImages:@[[UIImage imageNamed:@"lz_recorder_grid"], [UIImage imageNamed:@"lz_recorder_grid_hd"], [UIImage imageNamed:@"lz_recorder_line_hd"]] ];
    
    [self configNavigationBar];
//    [self initSCRecorder];
//    [self.progressView resetProgress];
    
    self.recordBtn.layer.cornerRadius = 26;
    self.recordBtn.layer.masksToBounds = YES;
    
    self.session = [[LZSession alloc]init];
    [self configGPUImageView];
}

- (void)configGPUImageView {
    self.videoCamera = [[GPUImageVideoCameraEx alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
//    self.videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    
    //输出方向为竖屏
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    //相机开始运行
    [self.videoCamera startCameraCapture];
    
    
    //显示view、freme
    GPUImageView *filterView = [[GPUImageView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)];
    [self.filterView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
    [self.filterView addSubview:filterView];
    
    
    //滤镜
    self.filter = [[GPUImageSepiaFilter alloc] init];
    
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, 0.125f, 1.f, .75f)];
    [cropFilter addTarget:self.session.movieWriter];
    [self.filter addTarget:cropFilter];
    [self.filter addTarget:self.filterView];
    [self.videoCamera addTarget:self.filter];

    //设置声音
    self.videoCamera.audioEncodingTarget = self.session.movieWriter;
}

//- (GPUImageVideoCamera *)videoCamera {
//    if (!_videoCamera) {
//        _videoCamera = [[GPUImageVideoCameraEx alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
//        //输出方向为竖屏
//        _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
//        [_videoCamera addAudioInputsAndOutputs];
//    }
//    return _videoCamera;
//}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self enumVideoUrl];
    [self updateGhostImage];
    [self updateProgressBar];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [_recorder previewViewFrameChanged];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_recorder startRunning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_recorder stopRunning];
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
    label2.text = @"1ß";
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
    WS(weakSelf);
    [self.videoListSegmentArrays removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {//获取所有group
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {//从group里面
                NSString* assetType = [result valueForProperty:ALAssetPropertyType];
                if([assetType isEqualToString:ALAssetTypeVideo]){
                    DLog(@"Video");
                    NSDictionary *assetUrls = [result valueForProperty:ALAssetPropertyURLs];
                    NSUInteger assetCounter = 0;
                    for (NSString *assetURLKey in assetUrls) {
                        DLog(@"Asset URL %lu = %@",(unsigned long)assetCounter, assetUrls[assetURLKey]);
                        SCRecordSessionSegment * segment = [[SCRecordSessionSegment alloc] initWithURL:assetUrls[assetURLKey] info:nil];
                        [weakSelf.videoListSegmentArrays addObject:segment];
                    }
                    DLog(@"Representation Size = %lld",[[result defaultRepresentation]size]);
                }
            }];
        } failureBlock:^(NSError *error) {
            DLog(@"Enumerate the asset groups failed.");
        }];
    });
}

//更新进度条
- (void)updateProgressBar {
    if (self.session.segments.count == 0) {
        [self.progressView updateProgressWithValue:0];
        return;
    }
    
//    self.cancelButton.enabled = YES;
    if (CMTimeGetSeconds(self.session.segmentsDuration) >= 3) {
        self.confirmButton.enabled = YES;
    } else {
        self.confirmButton.enabled = NO;
    }
    
//    [self.progressBar removeAllSubViews];
    CGFloat progress = 0;
    for (int i = 0; i < self.session.segments.count; i++) {
        LZSessionSegment * segment = self.session.segments[i];
        
        NSAssert(segment != nil, @"segment must be non-nil");
        CMTime currentTime = kCMTimeZero;
        if (segment) {
            currentTime = segment.duration;
            progress += CMTimeGetSeconds(currentTime) / MAX_VIDEO_DUR;
//            [self.progressBar setCurrentProgressToWidth:progress];
        }
    }
    [self.progressView updateProgressWithValue:progress];
}

- (void)changeToRecordStyle {
    [UIView animateWithDuration:0.5 animations:^{
        self.recordBtnWidth.constant = 28;
        self.recordBtn.layer.cornerRadius = 4;
    }];
}

- (void)changeToStopStyle {
    [UIView animateWithDuration:0.5 animations:^{
        self.recordBtnWidth.constant = 52;
        self.recordBtn.layer.cornerRadius = 26;
    }];
}

//更新快照
- (void)updateGhostImage {
    if (self.snapshotButton.selected && self.recorder.session.segments.count > 0) {
        SCRecordSessionSegment *segment = [self.recorder.session.segments lastObject];
        self.ghostImageView.image = segment.lastImage;
        self.ghostImageView.hidden = NO;
    }else{
        self.ghostImageView.hidden = YES;
    }
}

#pragma mark - Event
- (void)navbarRightButtonClickAction:(UIButton*)sender {
    if (self.videoListSegmentArrays.count > 0) {
        LZSelectVideoViewController * vc = [[LZSelectVideoViewController alloc] init];
        vc.recordSession = self.recorder.session;
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
    _recorder.videoZoomFactor = sender.value;
}

//取消/删除视频按钮
- (IBAction)cancelButton:(UIButton *)sender {
    if (sender.selected == NO && sender.enabled == YES) {//第一次按下删除按钮
        sender.selected = YES;
    }
    else if (sender.selected == YES) {//第二次按下删除按钮
        [self.session removeLastSegment];
        [self updateProgressBar];
        if (self.session.segments.count > 0) {
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
//        [self.recorder record];//开始录制
        [self changeToRecordStyle];
        
        [self.session startRecording];
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateText) userInfo:nil repeats:YES];

        [self.session addObserver:self forKeyPath:@"duration" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    }else {
        self.cancelButton.enabled = YES;
//        [self.recorder pause];//暂停录制
        [self changeToStopStyle];

        [self.session endRecordingFilter:self.filter Completion:^(NSMutableArray<NSURL *> *segments) {
            DLog("===================== %@",segments);
            GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, 0.125f, 1.f, .75f)];
            [cropFilter addTarget:self.session.movieWriter];
            [self.filter addTarget:cropFilter];
            //设置声音
            self.videoCamera.audioEncodingTarget = self.session.movieWriter;
        }];
    }
    self.fd_interactivePopDisabled = !sender.selected;
    self.maskView.hidden = sender.selected;
    self.navigationItem.titleView.hidden = sender.selected;
    self.navigationItem.hidesBackButton = !sender.selected;
    self.navigationItem.rightBarButtonItem.customView.hidden = !sender.selected;
    sender.selected = !sender.selected;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@"%@", keyPath);
    NSLog(@"%@", object);
    NSLog(@"%@", change[NSKeyValueChangeNewKey]);
}

- (void)updateText{
    Float64 time = CMTimeGetSeconds(self.session.duration);
    Float64 time1 = CMTimeGetSeconds(self.session.segmentsDuration);
    Float64 time2 = CMTimeGetSeconds(self.session.movieWriter.duration);
    DLog(@"%f,%f",time,time1);
    
    CGFloat progress = (time1+time2) / MAX_VIDEO_DUR;
    [self.progressView updateProgressWithValue:progress];
    
    self.labelTime.text = [self timeFormatted:(time1 + time2)];
    self.labelCount.text = [NSString stringWithFormat:@"%lu",self.session.segments.count + 1];
}

//转换成时分秒
- (NSString *)timeFormatted:(int)totalSeconds{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
//    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

- (void)stopWrite {
    dispatch_async(dispatch_get_main_queue(), ^{
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        NSArray *segments = self.session.segments;
        for (int i = 0; i < segments.count; i++) {
            LZSessionSegment *segment = (LZSessionSegment *)segments[i];
            NSURL *url = segment.url;//segments[i];
            DLog(@"+++++++:url:%@",url);
            
            if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:url]) {
                [library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error) {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                                           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            [alert show];
                        } else {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
                                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
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
//    [self stopWrite];
//    [self recordButton:nil];
    
    //视频详情
    LZVideoDetailsVC * vc = [[LZVideoDetailsVC alloc]initWithNibName:@"LZVideoDetailsVC" bundle:nil];
    vc.recordSession = self.session;
    [self.navigationController pushViewController:vc animated:YES];
}

//选择滤镜
- (IBAction)changeFilterButton:(UIButton *)sender {
    sender.selected = !sender.selected;
    //滤镜
    self.filter = [[GPUImageGrayscaleFilter alloc] init];

    [self.filter removeAllTargets];
    [self.videoCamera removeAllTargets];
    

    //组合
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.f, 0.125f, 1.f, .75f)];
    [cropFilter addTarget:self.session.movieWriter];
    [self.filter addTarget:cropFilter];
    [self.filter addTarget:self.filterView];
    [self.videoCamera addTarget:self.filter];
    
    //设置声音
    self.videoCamera.audioEncodingTarget = self.session.movieWriter;
}

//切换摄像头按钮
- (IBAction)changeButton:(UIButton *)sender {
    [UIView animateWithDuration:0.7 animations:^{
        CATransition *animation = [CATransition animation];
        animation.duration = 0.7f;
        animation.type = @"oglFlip";
        animation.subtype = kCATransitionFromLeft;
        animation.timingFunction = UIViewAnimationOptionCurveEaseInOut;
        [self.previewView.layer addAnimation:animation forKey:@"animation"];
    } completion:^(BOOL finished) {
        if (finished) {
            [self.recorder switchCaptureDevices];
        }
    }];
}

//设置声音
- (IBAction)setVoice:(UIButton *)sender {
    sender.selected = !sender.selected;

//    SCRecordSessionSegment * segment = self.recordSegments[idx];
//    //判断当前片段的声音设置
//    if (segment.isVoice) {
//        if ([segment.isVoice boolValue] == YES) {
//            self.videoPlayerView.player.volume = 1;
//            [self.lzVoiceButton setImage:[UIImage imageNamed:@"lz_videoedit_voice_on"] forState:UIControlStateNormal];
//        }
//        else {
//            self.videoPlayerView.player.volume = 0;
//            [self.lzVoiceButton setImage:[UIImage imageNamed:@"lz_videoedit_voice_off"] forState:UIControlStateNormal];
//        }
//    }
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
        self.recorder.flashMode = SCFlashModeLight;
        [self.videoCamera.inputCamera lockForConfiguration:nil];
        [self.videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
        [self.videoCamera.inputCamera unlockForConfiguration];
    }
    else {
        sender.selected = NO;
        self.recorder.flashMode = SCFlashModeOff;
        [self.videoCamera.inputCamera lockForConfiguration:nil];
        [self.videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
        [self.videoCamera.inputCamera unlockForConfiguration];
    }
}

#pragma mark - SCRecorderDelegate
- (void)recorder:(SCRecorder *)recorder didSkipVideoSampleBufferInSession:(SCRecordSession *)recordSession {
    DLog(@"Skipped video buffer(跳过视频缓冲)");
}

- (void)recorder:(SCRecorder *)recorder didReconfigureAudioInput:(NSError *)audioInputError {
    DLog(@"Reconfigured audio input: %@", audioInputError);
}

- (void)recorder:(SCRecorder *)recorder didReconfigureVideoInput:(NSError *)videoInputError {
    DLog(@"Reconfigured video input: %@", videoInputError);
}

//启动录制
- (void)recorder:(SCRecorder *__nonnull)recorder didBeginSegmentInSession:(SCRecordSession *__nonnull)session error:(NSError *__nullable)error {
//    [self.progressBar addProgressView];
//    [self.progressBar stopShining];
//    self.cancelButton.enabled = YES;
}

//更新进度条
- (void)recorder:(SCRecorder *)recorder didAppendVideoSampleBufferInSession:(SCRecordSession *)recordSession {
    CMTime recorderTime = kCMTimeZero;
    CMTime currentTime = kCMTimeZero;
    if (recordSession != nil) {
        currentTime = recordSession.currentSegmentDuration;
        recorderTime = recordSession.duration;
    }
    
    DLog(@"%@", [NSString stringWithFormat:@"current:%.2f sec, all:%.2f sec", CMTimeGetSeconds(currentTime), CMTimeGetSeconds(recorderTime)]);
    
    CGFloat width = CMTimeGetSeconds(currentTime) / MAX_VIDEO_DUR;
//    [self.progressBar setLastProgressToWidth:width];
    [self.progressView updateProgressWithValue:width];
    
    if (CMTimeGetSeconds(recorderTime) >= 3) {
        self.confirmButton.enabled = YES;
    } else {
        self.confirmButton.enabled = NO;
    }
}

//更新快照
- (void)recorder:(SCRecorder *)recorder didCompleteSegment:(SCRecordSessionSegment *)segment inSession:(SCRecordSession *)recordSession error:(NSError *)error {
//    [self.progressBar startShining];
    DLog(@"Completed record segment at %@: %@ (frameRate: %f)", segment.url, error, segment.frameRate);
    [self updateGhostImage];
}

//录制完成
- (void)recorder:(SCRecorder *)recorder didCompleteSession:(SCRecordSession *)recordSession {
    DLog(@"didCompleteSession:");
    self.cancelButton.enabled = YES;
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 8;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identify = @"VideoEditCollectionCell";
    LZVideoEditCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identify forIndexPath:indexPath];
//    SCRecordSessionSegment * segment = self.recordSegments[indexPath.row];
//    NSAssert(segment.url != nil, @"segment must be non-nil");
//    if (segment) {
//        cell.imageView.image = segment.thumbnail;
//        if ([segment.isSelect boolValue] == YES) {
//            cell.markView.hidden = YES;
//            cell.imageView.layer.borderWidth = 2;
//            cell.imageView.layer.borderColor = UIColorFromRGB(0x554c9a, 1).CGColor;
//        }
//        else {
//            cell.markView.hidden = NO;
//            cell.imageView.layer.borderWidth = 0;
//            cell.imageView.layer.borderColor = [UIColor clearColor].CGColor;
//        }
//    }

    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
//    SCRecordSessionSegment * segment = self.recordSegments[fromIndexPath.row];
//    NSAssert(segment.url != nil, @"segment must be non-nil");
//    [self.recordSegments removeObject:segment];
//    [self.recordSegments insertObject:segment atIndex:toIndexPath.row];
//    
//    //更新bar位置
//    [self.videoEditAuxiliary updateProgressBar:self.progressBar :self.recordSegments];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//    if (self.currentSelected == indexPath.row) {
//        return;
//    }
//    self.currentSelected = indexPath.row;
//    
//    //显示当前片段
//    [self showVideo:self.currentSelected];
//    
//    //更新片段
//    [self.videoEditAuxiliary updateTrimmerView:self.trimmerView recordSegments:self.recordSegments index:self.currentSelected];
}

@end
