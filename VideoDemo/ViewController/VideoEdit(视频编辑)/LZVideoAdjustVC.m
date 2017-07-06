//
//  LZVideoAdjustVC.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/6/28.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZVideoAdjustVC.h"
#import "LZPlayerView.h"
#import "LZVideoTools.h"

@interface LZVideoAdjustVC ()<GPUImageMovieDelegate,GPUImageMovieWriterDelegate>{
    GPUImageMovieWriter *movieWriter;
}

@property (strong, nonatomic) LZSessionSegment *segment;

@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) id timeObser;
@property (strong, nonatomic) NSMutableArray *recordSegments;

@property (strong, nonatomic) IBOutlet UISlider *slider1;
@property (strong, nonatomic) IBOutlet UISlider *slider2;
@property (strong, nonatomic) IBOutlet UISlider *slider3;
@property (strong, nonatomic) IBOutlet UISlider *slider4;
@property (strong, nonatomic) IBOutlet UISlider *slider5;
@property (strong, nonatomic) IBOutlet UISlider *slider6;


@property (strong, nonatomic) IBOutlet GPUImageView *gpuImageView;
@property (strong, nonatomic) GPUImageMovie *movieFile;
@property (strong, nonatomic) AVPlayer *player;


@property (strong, nonatomic) GPUImageFilterGroup *filterGroup;             //滤镜池
@property (strong, nonatomic) GPUImageExposureFilter *exposureFilter;       //曝光度
@property (strong, nonatomic) GPUImageContrastFilter *contrastFilter;       //对比度
@property (strong, nonatomic) GPUImageSaturationFilter *saturationFilter;   //饱和度
@property (strong, nonatomic) GPUImageSharpenFilter *sharpenFilter;         //锐度
@property (strong, nonatomic) GPUImageWhiteBalanceFilter *whiteBalanceFilter;//色温
@property (strong, nonatomic) GPUImageBrightnessFilter *brightnessFilter;   //暗度

@end

@implementation LZVideoAdjustVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.recordSegments = [NSMutableArray arrayWithArray:self.recordSession.segments];
    self.segment = self.recordSession.segments[self.currentSelected];
    
    [self configNavigationBar];
    
    self.slider1.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider2.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider3.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider4.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider5.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider6.transform = CGAffineTransformMakeRotation(-M_PI_2);
  
    
    self.filterGroup = [[GPUImageFilterGroup alloc]init];

    //曝光度
    _exposureFilter = [[GPUImageExposureFilter alloc]init];
    
    //对比度
    _contrastFilter = [[GPUImageContrastFilter alloc] init];
    
    //饱和度
    _saturationFilter = [[GPUImageSaturationFilter alloc] init];

    //锐度
    _sharpenFilter = [[GPUImageSharpenFilter alloc] init];

    //色温
    _whiteBalanceFilter = [[GPUImageWhiteBalanceFilter alloc] init];

    //暗度
    _brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    
    
    [self addGPUImageFilter:_exposureFilter];
    [self addGPUImageFilter:_contrastFilter];
    [self addGPUImageFilter:_saturationFilter];
    [self addGPUImageFilter:_sharpenFilter];
    [self addGPUImageFilter:_whiteBalanceFilter];
    [self addGPUImageFilter:_brightnessFilter];

    [self configPlayerView];
}

- (void)addGPUImageFilter:(GPUImageOutput<GPUImageInput> *)filter
{
    [_filterGroup addFilter:filter];
    GPUImageOutput<GPUImageInput> *newTerminalFilter = filter;
    
    NSInteger count = _filterGroup.filterCount;
    
    if (count == 1){
        _filterGroup.initialFilters = @[newTerminalFilter];
        _filterGroup.terminalFilter = newTerminalFilter;
    } else{
        GPUImageOutput<GPUImageInput> *terminalFilter    = _filterGroup.terminalFilter;
        NSArray *initialFilters                          = _filterGroup.initialFilters;
        
        [terminalFilter addTarget:newTerminalFilter];
        
        _filterGroup.initialFilters = @[initialFilters[0]];
        _filterGroup.terminalFilter = newTerminalFilter;
    }
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
    [button setTitle:LZLocalizedString(@"edit_done", @"") forState:UIControlStateNormal];
    [button setTitleColor:UIColorFromRGB(0xffffff, 1) forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectMake(0, 0, CGRectGetWidth(button.bounds), 40);
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
    [button addTarget:self action:@selector(navbarRightButtonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:button];
}

- (void)configPlayerView{
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithURL:self.segment.url];
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    
    self.movieFile = [[GPUImageMovie alloc] initWithPlayerItem:playerItem];
//    self.movieFile.delegate = self;
    self.movieFile.playAtActualSpeed = YES;
    
    [self.filterGroup addTarget:self.gpuImageView];
    [self.movieFile addTarget:self.filterGroup];
    [self.movieFile startProcessing];
    [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
    
    WS(weakSelf);
    self.timeObser = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        double current = CMTimeGetSeconds(time);
        double total = CMTimeGetSeconds(weakSelf.segment.asset.duration);
        if (current >= total) {
            CMTime time = CMTimeMakeWithSeconds(weakSelf.segment.startTime, weakSelf.segment.duration.timescale);
            [weakSelf.player seekToTime:time];
            [weakSelf.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
        }
    }];
}

- (void)ddd{
//    [self.filterGroup removeAllTargets];
//    self.movieFile = nil;
    
    // 播放
//    self.movieFile = [[GPUImageMovie alloc] initWithAsset:self.segment.asset];
//    self.movieFile.delegate = self;
//    self.movieFile.runBenchmark = YES;
//    self.movieFile.playAtActualSpeed = YES;
//    [self.movieFile addTarget:self.filterGroup];
    
    
    NSURL *movieURL = self.segment.url;
    NSString *filename = [LZVideoTools getFileName:[movieURL absoluteString]];
    movieURL = [LZVideoTools filePathWithFileName:[NSString stringWithFormat:@"%@.m4v", filename] isFilter:YES];
    
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 480.0)];
    movieWriter.delegate = self;
    movieWriter.shouldPassthroughAudio = YES;
    self.movieFile.audioEncodingTarget = movieWriter;
    [self.movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    // 显示到界面
//    [_filterGroup addTarget:self.gpuImageView];
    [self.filterGroup addTarget:movieWriter];
    
    [movieWriter startRecording];
//    [self.movieFile startProcessing];

    __weak typeof(self) weakSelf = self;
    [movieWriter setCompletionBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        [weakSelf.filterGroup removeTarget:strongSelf->movieWriter];
        [strongSelf->movieWriter finishRecording];
    }];
}

//- (void) applyFilterForVideo : (UIButton *) sender
//{
//    movieFile.delegate   = nil;
//    movieWriter.delegate = nil;
//    
//    [self cancelVideoProcessing];
//    [movieFile removeAllTargets];
//    [filterGroup removeTarget:movieWriter];
//    
//    [movieWriter cancelRecording];
//    
//    movieFile   = nil;
//    movieWriter = nil;
//    
//    [Crittercism leaveBreadcrumb:@"filterVideoItem - Filter"];
//    
//    btnPlayVideo.hidden          = YES;
//    btnPlayVideo.tag             = sender.tag;
//    btnLastFilterForVideo        = sender;
//    
//    __weak UIButton *weakbtnPlay = btnPlayVideo;
//    
//    isImageEdited = YES;
//    
//    currentFilterIndex = sender.tag;
//    
//    if (sender.tag == 0)
//    {
//        [self normalVideoFilter];
//        NSLog(@"select normal");
//        return;
//    }
//    
//    if (sender.tag < 22)
//    {
//        isFilterApplied = YES;
//        if (isOriginal)
//        {
//            originalVideoURL  = [NSURL fileURLWithPath:originalMoviePath];
//            unlink([filterMoviePath UTF8String]);
//            newFilterVideoURL = [NSURL fileURLWithPath:filterMoviePath];
//        }
//        else
//        {
//            originalVideoURL  = [NSURL fileURLWithPath:toolMoviePath];
//            unlink([finalMoviePath UTF8String]);
//            newFilterVideoURL = [NSURL fileURLWithPath:finalMoviePath];
//        }
//    }
//    else
//    {
//        isToolApplied = YES;
//        if (isOriginal)
//        {
//            originalVideoURL = [NSURL fileURLWithPath:originalMoviePath];
//            unlink([toolMoviePath UTF8String]);
//            newFilterVideoURL = [NSURL fileURLWithPath:toolMoviePath];
//        }
//        else
//        {
//            originalVideoURL = [NSURL fileURLWithPath:filterMoviePath];
//            unlink([finalMoviePath UTF8String]);
//            newFilterVideoURL = [NSURL fileURLWithPath:finalMoviePath];
//        }
//    }
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        
//        movieFile                   = [[GPUImageMovie alloc] initWithURL:originalVideoURL];
//        
//        movieFile.playAtActualSpeed = YES;
//        
//        NSLog(@"movieFile is %@",movieFile);
//        
//        AVAsset *anAsset = [[AVURLAsset alloc] initWithURL:originalVideoURL options:nil];
//        CGSize size      = [[[anAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
//        NSLog(@"width - %f,%f",size.width,size.height);
//        
//        @try
//        {
//            UIButton *button = (UIButton *)sender;
//            
//            currentFilterIndex = button.tag;
//            
//            if (sender.tag < 12 && sender.tag != 2)
//            {
//                filterGroup = [[GPUImageFilterGroup alloc] init];
//                [self setFilterOnImage:toolImage fromTool:NO isOriginal:isOriginal];
//            }
//            else if(sender.tag == 12) // Influencia - Highway
//            {
//                filterType  = GPUIMAGE_SOFTELEGANCE;
//                filterGroup = [[GPUImageSoftEleganceFilter alloc] init];
//            }
//            else if(sender.tag == 13) // Dark Side
//            {
//                [filterSettingsSlider setMinimumValue:0.0];
//                [filterSettingsSlider setMaximumValue:1.0];
//                
//                if(intLastSelFilterTag != sender.tag)
//                {
//                    [filterSettingsSlider setValue:0.50];
//                }
//                
//                filterType  = GPUIMAGE_SOBELEDGEDETECTION;
//                filterGroup = [[GPUImageSobelEdgeDetectionFilter alloc] init];
//            }
//            else if(sender.tag == 17) // Blue Velvet
//            {
//                filterType  = GPUIMAGE_AMATORKA;
//                filterGroup = [[GPUImageAmatorkaFilter alloc] init];
//            }
//            else if(sender.tag == 2) // Lost Memories
//            {
//                filterType  = GPUIMAGE_GRAYSCALE;
//                filterGroup = [[GPUImageGrayscaleFilter alloc] init];
//            }
//            else if(sender.tag == 20) // Miss etikate
//            {
//                filterType  = GPUIMAGE_MISSETIKATE;
//                filterGroup = [[GPUImageMissEtikateFilter alloc] init];
//            }
//            else if(sender.tag == 14) // Carousel
//            {
//                [filterSettingsSlider setMinimumValue:0.0];
//                [filterSettingsSlider setMaximumValue:360.0];
//                
//                if(intLastSelFilterTag != sender.tag)
//                {
//                    [filterSettingsSlider setValue:180.0];
//                }
//                
//                filterType  = GPUIMAGE_HUE;
//                filterGroup = [[GPUImageHueFilter alloc] init];
//            }
//            else if(sender.tag == 16) // Scatter
//            {
//                if(intLastSelFilterTag != sender.tag)
//                {
//                    [filterSettingsSlider setValue:0.15];
//                }
//                
//                [filterSettingsSlider setMinimumValue:0.0];
//                [filterSettingsSlider setMaximumValue:0.3];
//                
//                filterType  = GPUIMAGE_POLKADOT;
//                filterGroup = [[GPUImagePolkaDotFilter alloc] init];
//                
//                if ([filterGroup isKindOfClass:[GPUImagePolkaDotFilter class]])
//                {
//                    [(GPUImagePolkaDotFilter *)filterGroup setDotScaling:3.0];
//                }
//            }
//            else if(sender.tag == 19) // Comic Strip
//            {
//                [filterSettingsSlider setMinimumValue:0.0];
//                [filterSettingsSlider setMaximumValue:1.0];
//                
//                if(intLastSelFilterTag != sender.tag)
//                {
//                    [filterSettingsSlider setValue:0.5];
//                }
//                
//                filterType  = GPUIMAGE_SKETCH;
//                filterGroup = [[GPUImageSketchFilter alloc] init];
//            }
//            else if(sender.tag == 18) // Alien
//            {
//                filterType  = GPUIMAGE_COLORINVERT;
//                filterGroup = [[GPUImageColorInvertFilter alloc] init];
//            }
//            else if(sender.tag == 15) // New 11 - Mist and Shadow
//            {
//                filterGroup = [[GPUImageFilterGroup alloc] init];
//                
//                GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
//                [(GPUImageFilterGroup *)filterGroup addFilter:sepiaFilter];
//                
//                GPUImageVignetteFilter *VeFilter = [[GPUImageVignetteFilter alloc] init];
//                [(GPUImageFilterGroup *)filterGroup addFilter:VeFilter];
//                
//                [sepiaFilter addTarget:VeFilter];
//                [(GPUImageFilterGroup *)filterGroup setInitialFilters:[NSArray arrayWithObject:sepiaFilter]];
//                [(GPUImageFilterGroup *)filterGroup setTerminalFilter:VeFilter];
//            }
//            else if(sender.tag == 21) // New 13 - Superstition
//            {
//                filterGroup = [[GPUImageFilterGroup alloc] init];
//                
//                GPUImageMonochromeFilter *filter1 = [[GPUImageMonochromeFilter alloc] init];
//                [(GPUImageMonochromeFilter *)filter1 setColor:(GPUVector4){0.0f, 0.0f, 1.0f, 1.f}];
//                [(GPUImageFilterGroup *)filterGroup addFilter:filter1];
//                
//                GPUImageAmatorkaFilter *filter2 = [[GPUImageAmatorkaFilter alloc] init];
//                [(GPUImageFilterGroup *)filterGroup addFilter:filter2];
//                
//                GPUImageBrightnessFilter *filter3 = [[GPUImageBrightnessFilter alloc] init];
//                [(GPUImageBrightnessFilter *)filter3 setBrightness:0.3];
//                [(GPUImageFilterGroup *)filterGroup addFilter:filter3];
//                
//                [filter2 addTarget:filter1];
//                [filter1 addTarget:filter3];
//                [(GPUImageFilterGroup *)filterGroup setInitialFilters:[NSArray arrayWithObject:filter2]];
//                [(GPUImageFilterGroup *)filterGroup setTerminalFilter:filter3];
//            }
//            else
//            {
//                if (sender.tag >= 22 && sender.tag <= 27)
//                {
//                    filterGroup = [[GPUImageFilterGroup alloc] init];
//                    [self setFilterOnImage:toolImage
//                                  fromTool:YES
//                                isOriginal:isOriginal];
//                }
//            }
//            
//            NSLog(@"The frame is %@",NSStringFromCGRect(imageView.frame));
//            NSLog(@"Aspect Ratio is %f",size.width/size.height);
//            
//            float aspectRatio = (size.width/size.height);
//            
//            if (0) // Fill with the screen bounds.
//            {
//                imageView.frame = CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y, ScreenWidth, ScreenWidth);
//                
//                if (aspectRatio > 1.0)
//                {
//                    imageView.frame = CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y, imageView.frame.size.width * aspectRatio, imageView.frame.size.height);
//                }
//                else
//                {
//                    imageView.frame = CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y, imageView.frame.size.width, imageView.frame.size.height/aspectRatio);
//                }
//            }
//            
//            //imageView.frame = CGRectMake(imageView.frame.origin.x,imageView.frame.origin.y, 320, imageView.frame.size.width / aspectRatio);
//            
//            float countedWidth  = ScreenWidth;
//            float countedHeight = 0.0f;
//            
//            countedHeight = (countedWidth/aspectRatio);
//            
//            NSLog(@"Counted Width is %f and Height is %f",countedWidth,countedHeight);
//            
//            movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:newFilterVideoURL
//                                                                   size:CGSizeMake(ScreenWidth, ScreenWidth)];//
//            
//            
//            if ([self.strFilterSelMedia isEqualToString:kVideo] &&
//                APP_DELEGATE.isVideoFromPhotoLibrary)
//            {
//                [filterGroup setInputRotation:kGPUImageRotateRight atIndex:0];
//            }
//            
//            //[movieWriter setInputRotation:kGPUImageRotateRight atIndex:0];
//            /* also try this
//             processedImage = [UIImage imageWithCGImage:[processedImage CGImage] scale:1.0 orientation:originalImage.imageOrientation];
//             */
//            
//            NSLog(@"1 - %s",__PRETTY_FUNCTION__);
//            
//            // Configure this for video from the movie file, where we want to preserve all video frames and audio samples
//            //Pankaj audio support change
//            movieWriter.shouldPassthroughAudio = YES;
//            movieWriter.encodingLiveVideo      = NO;
//            movieFile.audioEncodingTarget      = movieWriter;
//            
//            __weak GPUImageMovieWriter *weakMoviWriter = movieWriter;
//            
//            //set any resolution you want
//            //[filterGroup forceProcessingAtSize:CGSizeMake(320.0f, 320.0f)];
//            [filterGroup forceProcessingAtSizeRespectingAspectRatio:CGSizeMake(ScreenWidth, ScreenWidth)];
//            [movieFile addTarget:filterGroup];
//            [filterGroup addTarget:imageView];
//            [filterGroup addTarget:movieWriter];
//            
//            movieFile.runBenchmark      = YES;
//            
//            [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
//            
//            [movieWriter startRecording];
//            [movieFile startProcessing];
//            
//            __weak GPUImageOutput<GPUImageInput> *weakGPUImageFilter = filterGroup;
//            //[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
//            
//            isPlayAgain                    = FALSE;
//            urlLastToPlay                  = newFilterVideoURL;
//            APP_DELEGATE.urlProcessedVideo = newFilterVideoURL;
//            
//            isPlayAudioInBackground = YES;
//            
//            __block NSURL *thelastURL             = urlLastToPlay;
//            __block AVPlayer *theMoviePlayer      = moviePlayer;
//            //__block UIView *theView            = viewContainer;
//            __block GPUImageView *theImageView    = imageView;
//            __block NSString *typeOfMedia         = self.strFilterSelMedia;
//            
//            imageView.fillMode = kGPUImageFillModePreserveAspectRatio;
//            
//            NSLog(@"ImageView.size is %@",NSStringFromCGSize(imageView.frame.size));
//            
//            if (isAudioSelected)
//            {
//                // NOTE : 0.05 delay to remove gap between sound and video.
//                
//                [self performSelector:@selector(playAudio:)
//                           withObject:nil
//                           afterDelay:0.05f];
//            }
//            else
//            {
//                [self playMovie];
//            }
//            
//            //[viewContainer bringSubviewToFront:imageView];
//            
//            [movieWriter setCompletionBlock:^{
//                
//                [weakGPUImageFilter removeTarget:weakMoviWriter];
//                [weakMoviWriter finishRecording];
//                
//                NSLog(@"Finish movieWriterSoftElegance");
//                
//                dispatch_async(dispatch_get_main_queue(),
//                               ^{
//                                   AVURLAsset *asset        = [AVURLAsset URLAssetWithURL:thelastURL options:nil];
//                                   
//                                   AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
//                                   
//                                   float currentDuration = CMTimeGetSeconds(theMoviePlayer.currentTime);
//                                   
//                                   [theMoviePlayer replaceCurrentItemWithPlayerItem:playerItem];
//                                   
//                                   [theMoviePlayer seekToTime:kCMTimeZero];
//                                   
//                                   
//                                   //[theView sendSubviewToBack:theImageView];
//                                   float timeToDispatch = (CMTimeGetSeconds(asset.duration) - currentDuration);
//                                   
//                                   if ([typeOfMedia isEqualToString:kVideo])
//                                   {
//                                       timeToDispatch = 0.0f;
//                                   }
//                                   
//                                   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToDispatch * NSEC_PER_SEC)), dispatch_get_main_queue(),
//                                                  ^{
//                                                      [theImageView setHidden:YES];
//                                                      [theMoviePlayer pause];
//                                                      
//                                                      if ([audioPlayer isPlaying])
//                                                      {
//                                                          [audioPlayer stop];
//                                                          [timer invalidate];
//                                                          timer = nil;
//                                                      }
//                                                      
//                                                      [theMoviePlayer seekToTime:kCMTimeZero
//                                                               completionHandler:^(BOOL finished)
//                                                       {
//                                                       }];
//                                                  });
//                                   
//                               });
//                
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        //[[UIApplication sharedApplication] endIgnoringInteractionEvents];
//                        weakbtnPlay.hidden = NO;
//                    });
//                });
//            }];
//            
//            //        isPlayAgain                    = FALSE;
//            //        urlLastToPlay                  = newFilterVideoURL;
//            //        APP_DELEGATE.urlProcessedVideo = newFilterVideoURL;
//        }
//        @catch (NSException *exception)
//        {
//            NSLog(@"%@",exception);
//        }
//    });
//}

- (void)didCompletePlayingMovie{
    NSLog(@"finished,PlayingMovie");
}
- (void)movieRecordingCompleted{
    NSLog(@"finished");
}

#pragma mark - Event
- (void)navbarRightButtonClickAction:(UIButton*)sender {
    [self ddd];
    return;
    
    NSURL *tempPath = self.segment.url;
    NSString *filename = [LZVideoTools getFileName:[tempPath absoluteString]];
    tempPath = [LZVideoTools filePathWithFileName:[NSString stringWithFormat:@"%@.m4v", filename] isFilter:YES];
    
    [self.recordSession removeAllSegments:NO];
    
    
    
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 480.0)];
    movieWriter.shouldPassthroughAudio = YES;
    _movieFile.audioEncodingTarget = movieWriter;
    [_movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    [_filterGroup addTarget:movieWriter];
    [movieWriter startRecording];
    [_movieFile startProcessing];
    
    __weak typeof(self) weakSelf = self;
    [movieWriter setCompletionBlock:^{
        // very slow finished.
        NSLog(@"finished");
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.filterGroup removeTarget:strongSelf->movieWriter];
        [strongSelf->movieWriter finishRecording];
    }];
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
//    self.segment.startTime = 0.00;
//    self.segment.endTime = CMTimeGetSeconds(self.segment.duration);
//    
//    CMTime start = CMTimeMakeWithSeconds(self.segment.startTime, self.segment.duration.timescale);
//    CMTime duration = CMTimeMakeWithSeconds(self.segment.endTime - self.segment.startTime, self.segment.duration.timescale);
//    CMTimeRange range = CMTimeRangeMake(start, duration);
//    
//    [LZVideoTools exportVideo:self.segment.asset videoComposition:nil filePath:tempPath timeRange:range completion:^(NSURL *savedPath) {
//        if(savedPath) {
//            DLog(@"导出视频路径：%@", savedPath);
//            LZSessionSegment * newSegment = [LZSessionSegment segmentWithURL:tempPath filter:self.segment.filter];
//            [self.recordSegments removeObject:self.segment];
//            [self.recordSegments insertObject:newSegment atIndex:self.currentSelected];
//            
//            for (int i = 0; i < self.recordSegments.count; i++) {
//                LZSessionSegment * segment = self.recordSegments[i];
//                NSAssert(segment.url != nil, @"segment url must be non-nil");
//                if (segment.url != nil) {
//                    [self.recordSession insertSegment:segment atIndex:i];
//                }
//            }
//            
//            [self.navigationController popViewControllerAnimated:YES];
//        }
//        else {
//            DLog(@"导出视频路径出错：%@", savedPath);
//        }
//    }];
}

//播放或暂停
- (IBAction)filterClicked:(UIButton *)button{
    if (!(self.player.rate > 0)) {
        [self.player play];
        self.player.rate = 1;
        [self.playButton setImage:nil forState:UIControlStateNormal];
    }else{
        [self.player pause];
        [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
    }
}

- (IBAction)updateSliderValue:(UISlider *)sender{
    switch (sender.tag) {
        case 1: {//亮度
            _exposureFilter.exposure = sender.value;
        }
            break;
        case 2: {//对比度
            _contrastFilter.contrast = sender.value;
        }
            break;
        case 3: {//饱和度
            _saturationFilter.saturation = sender.value;
        }
            break;
        case 4: {//锐度
            _sharpenFilter.sharpness = sender.value;
        }
            break;
        case 5: {//色温
            _whiteBalanceFilter.temperature = sender.value;
//            _whiteBalanceFilter.tint = 0;
        }
            break;
        case 6: {//暗度
            _brightnessFilter.brightness = sender.value;
        }
            break;
            
    }
    
    if (sender.value == sender.maximumValue/2) {
        sender.thumbTintColor = [UIColor whiteColor];
    }else{
        sender.thumbTintColor = [UIColor greenColor];
    }
    if (!(self.player.rate > 0)) {
        self.player.rate = 0.1;
    }
    DLog(@"%f",sender.value);
//    [self.player play];
//    [self.playButton setImage:nil forState:UIControlStateNormal];
}

/* 获取视频缩略图 */
- (UIImage *)getThumbailImageRequestAtTimeSecond:(CGFloat)timeBySecond {
    //视频文件URL地址
    NSURL *url = [NSURL URLWithString:@"http://192.168.6.147/2.mp4"];
    //创建媒体信息对象AVURLAsset
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
    //创建视频缩略图生成器对象AVAssetImageGenerator
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlAsset];
    //创建视频缩略图的时间，第一个参数是视频第几秒，第二个参数是每秒帧数
    CMTime time = CMTimeMake(timeBySecond, 10);
    CMTime actualTime;//实际生成视频缩略图的时间
    NSError *error = nil;//错误信息
    //使用对象方法，生成视频缩略图，注意生成的是CGImageRef类型，如果要在UIImageView上显示，需要转为UIImage
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time
                                                actualTime:&actualTime
                                                     error:&error];
    if (error) {
        NSLog(@"截取视频缩略图发生错误，错误信息：%@",error.localizedDescription);
        return nil;
    }
    //CGImageRef转UIImage对象
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    //记得释放CGImageRef
    CGImageRelease(cgImage);
    return image;
}

- (void)dealloc{
    [self.player removeTimeObserver:self.timeObser];
    DLog(@"========= dealloc =========");
}

@end
