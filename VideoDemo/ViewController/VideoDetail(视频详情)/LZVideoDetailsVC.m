//
//  LZVideoDetailsVC.m
//  laziz_Merchant
//
//  Created by biyuhuaping on 2017/4/19.
//  Copyright © 2017年 XBN. All rights reserved.
//  视频详情

#import "LZVideoDetailsVC.h"
#import "LZVideoEditClipVC.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "LZVideoTools.h"
#import "SCWatermarkOverlayView.h"

@interface LZVideoDetailsVC ()<SCPlayerDelegate>
@property (strong, nonatomic) IBOutlet SCSwipeableFilterView *filterSwitcherView;
@property (strong, nonatomic) SCPlayer *player;
@end

@implementation LZVideoDetailsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LZLocalizedString(@"video_details", nil);
    [self configNavigationBar];
    
    _player = [SCPlayer player];
    [self.player setLoopEnabled:YES];

    if ([[NSProcessInfo processInfo] activeProcessorCount] > 1) {
//        self.filterSwitcherView.contentMode = UIViewContentModeScaleAspectFill;
        
        SCFilter *emptyFilter = [SCFilter emptyFilter];
        emptyFilter.name = @"#nofilter";
        
        self.filterSwitcherView.filters = @[
                                            emptyFilter,
//                                            [SCFilter filterWithCIFilterName:@"CIPhotoEffectNoir"],
//                                            [SCFilter filterWithCIFilterName:@"CIPhotoEffectChrome"],
//                                            [SCFilter filterWithCIFilterName:@"CIPhotoEffectInstant"],
//                                            [SCFilter filterWithCIFilterName:@"CIPhotoEffectTonal"],
//                                            [SCFilter filterWithCIFilterName:@"CIPhotoEffectFade"],
//                                            [SCFilter filterWithCIFilterName:@"CIExposureAdjust"],
//                                            [SCFilter filterWithCIFilterName:@"CIPhotoEffectProcess"],
//                                            [SCFilter filterWithCIFilterName:@"CISaturationBlendMode"],
                                            // Adding a filter created using CoreImageShop Untitled、a_filter
                                            [SCFilter filterWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"a_filter" withExtension:@"cisf"]],
                                            [self createAnimatedFilter]
                                            ];
        self.player.SCImageView = self.filterSwitcherView;
//        [self.filterSwitcherView addObserver:self forKeyPath:@"selectedFilter" options:NSKeyValueObservingOptionNew context:nil];
    } else {
        SCVideoPlayerView *playerView = [[SCVideoPlayerView alloc] initWithPlayer:self.player];
        playerView.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        playerView.frame = self.filterSwitcherView.frame;
        playerView.autoresizingMask = self.filterSwitcherView.autoresizingMask;
        [self.filterSwitcherView.superview insertSubview:playerView aboveSubview:self.filterSwitcherView];
        [self.filterSwitcherView removeFromSuperview];
    }

    /*enum color
    {
        @"CIAccordionFoldTransition",
        @"CIAdditionCompositing",
        [2] = "CIAffineClamp"
        [3] = "CIAffineTile"
        [4] = "CIAffineTransform"
        [5] = "CIAreaHistogram"
        [6] = "CIAztecCodeGenerator"
        [7] = "CIBarsSwipeTransition"
        [8] = "CIBlendWithAlphaMask"
        [9] = "CIBlendWithMask"
        [10] = "CIBloom"
        [11] = "CIBumpDistortion"
        [12] = "CIBumpDistortionLinear"
        [13] = "CICheckerboardGenerator"
        [14] = "CICircleSplashDistortion"
        [15] = "CICircularScreen"
        [16] = "CICode128BarcodeGenerator"
        [17] = "CIColorBlendMode"
        [18] = "CIColorBurnBlendMode"
        [19] = "CIColorClamp"
        [20] = "CIColorControls"
        [21] = "CIColorCrossPolynomial"
        [22] = "CIColorCube"
        [23] = "CIColorCubeWithColorSpace"
        [24] = "CIColorDodgeBlendMode"
        [25] = "CIColorInvert"
        [26] = "CIColorMap"
        [27] = "CIColorMatrix"
        [28] = "CIColorMonochrome"
        [29] = "CIColorPolynomial"
        [30] = "CIColorPosterize"
        [31] = "CIConstantColorGenerator"
        [32] = "CIConvolution3X3"
        [33] = "CIConvolution5X5"
        [34] = "CIConvolution9Horizontal"
        [35] = "CIConvolution9Vertical"
        [36] = "CICopyMachineTransition"
        [37] = "CICrop"
        [38] = "CIDarkenBlendMode"
        [39] = "CIDifferenceBlendMode"
        [40] = "CIDisintegrateWithMaskTransition"
        [41] = "CIDissolveTransition"
        [42] = "CIDivideBlendMode"
        [43] = "CIDotScreen"
        [44] = "CIEightfoldReflectedTile"
        [45] = "CIExclusionBlendMode"
        [46] = "CIExposureAdjust"
        [47] = "CIFalseColor"
        [48] = "CIFlashTransition"
        [49] = "CIFourfoldReflectedTile"
        [50] = "CIFourfoldRotatedTile"
        [51] = "CIFourfoldTranslatedTile"
        [52] = "CIGammaAdjust"
        [53] = "CIGaussianBlur"
        [54] = "CIGaussianGradient"
        [55] = "CIGlassDistortion"
        [56] = "CIGlideReflectedTile"
        [57] = "CIGloom"
        [58] = "CIHardLightBlendMode"
        [59] = "CIHatchedScreen"
        [60] = "CIHighlightShadowAdjust"
        [61] = "CIHistogramDisplayFilter"
        [62] = "CIHoleDistortion"
        [63] = "CIHueAdjust"
        [64] = "CIHueBlendMode"
        [65] = "CILanczosScaleTransform"
        [66] = "CILightenBlendMode"
        [67] = "CILightTunnel"
        [68] = "CILinearBurnBlendMode"
        [69] = "CILinearDodgeBlendMode"
        [70] = "CILinearGradient"
        [71] = "CILinearToSRGBToneCurve"
        [72] = "CILineScreen"
        [73] = "CILuminosityBlendMode"
        [74] = "CIMaskToAlpha"
        [75] = "CIMaximumComponent"
        [76] = "CIMaximumCompositing"
        [77] = "CIMinimumComponent"
        [78] = "CIMinimumCompositing"
        [79] = "CIModTransition"
        [80] = "CIMultiplyBlendMode"
        [81] = "CIMultiplyCompositing"
        [82] = "CIOverlayBlendMode"
        [83] = "CIPerspectiveCorrection"
        [84] = "CIPhotoEffectChrome"//铬黄
        [85] = "CIPhotoEffectFade"//褪色
        [86] = "CIPhotoEffectInstant"//怀旧
        [87] = "CIPhotoEffectMono"
        [88] = "CIPhotoEffectNoir"//黑白
        [89] = "CIPhotoEffectProcess"//冲印
        [90] = "CIPhotoEffectTonal"//色调
        [91] = "CIPhotoEffectTransfer"
        [92] = "CIPinchDistortion"
        [93] = "CIPinLightBlendMode"
        [94] = "CIPixellate"
        [95] = "CIQRCodeGenerator"
        [96] = "CIRadialGradient"
        [97] = "CIRandomGenerator"
        [98] = "CISaturationBlendMode"
        [99] = "CIScreenBlendMode"
        [100] = "CISepiaTone"
        [101] = "CISharpenLuminance"
        [102] = "CISixfoldReflectedTile"
        [103] = "CISixfoldRotatedTile"
        [104] = "CISmoothLinearGradient"
        [105] = "CISoftLightBlendMode"
        [106] = "CISourceAtopCompositing"
        [107] = "CISourceInCompositing"
        [108] = "CISourceOutCompositing"
        [109] = "CISourceOverCompositing"
        [110] = "CISRGBToneCurveToLinear"
        [111] = "CIStarShineGenerator"
        [112] = "CIStraightenFilter"
        [113] = "CIStripesGenerator"
        [114] = "CISubtractBlendMode"
        [115] = "CISwipeTransition"
        [116] = "CITemperatureAndTint"
        [117] = "CIToneCurve"
        [118] = "CITriangleKaleidoscope"
        [119] = "CITwelvefoldReflectedTile"
        [120] = "CITwirlDistortion"
        [121] = "CIUnsharpMask"
        [122] = "CIVibrance"
        [123] = "CIVignette"
        [124] = "CIVignetteEffect"
        [125] = "CIVortexDistortion"
        [126] = "CIWhitePointAdjust"
    }*/
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.player setItemByAsset:self.recordSession.assetRepresentingSegments];
    [self.player play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player pause];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - configViews
//配置navi
- (void)configNavigationBar{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    button.selected = NO;
    [button setTitle:@"保存到本地" forState:UIControlStateNormal];
    [button setTitleColor:UIColorFromRGB(0xffffff, 1) forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectMake(0, 0, CGRectGetWidth(button.bounds), 40);
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
    [button addTarget:self action:@selector(navbarRightButtonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:button];
}

#pragma mark - Event
- (void)navbarRightButtonClickAction:(UIButton*)sender {
    [self saveToCameraRoll];
    return;
    
    NSURL *tempPath = [LZVideoTools filePathWithFileName:@"ConponVideo.m4v"];

//    4.导出
    WS(weakSelf);
    [LZVideoTools exportVideo:self.recordSession.assetRepresentingSegments videoComposition:nil filePath:tempPath timeRange:kCMTimeRangeZero completion:^(NSURL *savedPath) {
        if(savedPath) {
            DLog(@"导出视频路径：%@", savedPath);
            //保存到本地
            ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
            if ([assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:savedPath]) {
                [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:savedPath completionBlock:NULL];
            }
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }
        else {
            DLog(@"导出视频路径出错：%@", savedPath);
        }
    }];
}

- (IBAction)cutVideoButton:(UIButton *)sender {
    LZVideoEditClipVC * vc = [[LZVideoEditClipVC alloc] initWithNibName:@"LZVideoEditClipVC" bundle:nil];
    vc.recordSession = self.recordSession;
    [self.navigationController pushViewController:vc animated:YES];
}

//创建动态滤镜
- (SCFilter *)createAnimatedFilter {
    SCFilter *animatedFilter = [SCFilter emptyFilter];
    animatedFilter.name = @"Animated Filter";
    
    SCFilter *gaussian = [SCFilter filterWithCIFilterName:@"CIGaussianBlur"];
    SCFilter *blackAndWhite = [SCFilter filterWithCIFilterName:@"CIColorControls"];
    
    [animatedFilter addSubFilter:gaussian];
    [animatedFilter addSubFilter:blackAndWhite];
    
    double duration = 0.5;
    double currentTime = 0;
    BOOL isAscending = YES;
    
    Float64 assetDuration = CMTimeGetSeconds(_recordSession.assetRepresentingSegments.duration);
    
    while (currentTime < assetDuration) {
        if (isAscending) {
            [blackAndWhite addAnimationForParameterKey:kCIInputSaturationKey startValue:@1 endValue:@0 startTime:currentTime duration:duration];
            [gaussian addAnimationForParameterKey:kCIInputRadiusKey startValue:@0 endValue:@10 startTime:currentTime duration:duration];
        } else {
            [blackAndWhite addAnimationForParameterKey:kCIInputSaturationKey startValue:@0 endValue:@1 startTime:currentTime duration:duration];
            [gaussian addAnimationForParameterKey:kCIInputRadiusKey startValue:@10 endValue:@0 startTime:currentTime duration:duration];
        }
        
        currentTime += duration;
        isAscending = !isAscending;
    }
    
    return animatedFilter;
}

//保存到相机卷
- (void)saveToCameraRoll {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    SCFilter *currentFilter = [self.filterSwitcherView.selectedFilter copy];
    [_player pause];
    
    SCAssetExportSession *exportSession = [[SCAssetExportSession alloc] initWithAsset:self.recordSession.assetRepresentingSegments];
    exportSession.videoConfiguration.filter = currentFilter;
    exportSession.videoConfiguration.preset = SCPresetHighestQuality;
    exportSession.audioConfiguration.preset = SCPresetHighestQuality;
    exportSession.videoConfiguration.maxFrameRate = 35;
    exportSession.outputUrl = self.recordSession.outputUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;
//    exportSession.delegate = self;
    exportSession.contextType = SCContextTypeAuto;
    
//    exportView.hidden = NO;
//    exportView.alpha = 0;
    
    SCWatermarkOverlayView *overlay = [SCWatermarkOverlayView new];
    overlay.date = self.recordSession.date;
    exportSession.videoConfiguration.overlay = overlay;
    
    CFTimeInterval time = CACurrentMediaTime();
    __weak typeof(self) wSelf = self;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        __strong typeof(self) strongSelf = wSelf;
        
        if (!exportSession.cancelled) {
            NSLog(@"Completed compression in %fs", CACurrentMediaTime() - time);
        }
        
        if (strongSelf != nil) {
            [strongSelf.player play];
            strongSelf.navigationItem.rightBarButtonItem.enabled = YES;
            
//            [UIView animateWithDuration:0.3 animations:^{
//                strongSelf.exportView.alpha = 0;
//            }];
        }
        
        NSError *error = exportSession.error;
        if (exportSession.cancelled) {
            NSLog(@"Export was cancelled");
        } else if (error == nil) {
            [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
            [exportSession.outputUrl saveToCameraRollWithCompletion:^(NSString * _Nullable path, NSError * _Nullable error) {
                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
                
                if (error == nil) {
                    [[[UIAlertView alloc] initWithTitle:@"已保存到相机卷" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                    [self.navigationController popViewControllerAnimated:YES];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"保存失败" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
            }];
        } else {
            if (!exportSession.cancelled) {
                [[[UIAlertView alloc] initWithTitle:@"保存失败" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
        }
    }];
}

@end
