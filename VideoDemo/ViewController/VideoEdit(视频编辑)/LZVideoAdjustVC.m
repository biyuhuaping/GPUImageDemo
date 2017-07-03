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

@interface LZVideoAdjustVC ()<GPUImageMovieDelegate>{
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
    GPUImageVideoCamera *videoCamera;
    
    CMTime pausedTime;
    NSTimer *_timer;
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


@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) GPUImageMovie *movieFile;
@property (strong, nonatomic) GPUImagePicture *pic;
@property (strong, nonatomic) IBOutlet GPUImageView *gpuImageView;
@property (strong, nonatomic) GPUImageBrightnessFilter *brightnessFilter;//亮度滤镜


@property (strong, nonatomic) AVPlayerItem *playerItem;

@end

@implementation LZVideoAdjustVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.recordSegments = [NSMutableArray arrayWithArray:self.recordSession.segments];
    self.segment = self.recordSession.segments[self.currentSelected];
    
    [self configNavigationBar];
    [self configPlayerView];
    
    self.slider1.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider2.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider3.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider4.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider5.transform = CGAffineTransformMakeRotation(-M_PI_2);
    self.slider6.transform = CGAffineTransformMakeRotation(-M_PI_2);
//    [self brightness1];
//    [self brightness2];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)brightness1{
    //    在GPUImageBrightnessFilter中首先初始化该滤镜
    GPUImageBrightnessFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    _brightnessFilter = brightnessFilter;
    
    
    
    
    //    设置亮度调整范围为整张图像
    [brightnessFilter forceProcessingAtSize:CGSizeMake(kScreenWidth, kScreenWidth)];
    [brightnessFilter useNextFrameForImageCapture];
    
    //    获取数据源
    GPUImageMovie *movieFile = [[GPUImageMovie alloc] initWithAsset:self.segment.asset];
    _movieFile = movieFile;
    
    //    创建最终预览的view
    GPUImageView *gpuView = [[GPUImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view insertSubview:gpuView atIndex:0];
    
    //    设置GPUImage响应链，从数据源 => 滤镜 => 最终界面效果
    [movieFile addTarget:brightnessFilter]; //   ① 添加上滤镜
    [brightnessFilter addTarget:gpuView]; // ② 添加效果界面
    
    //    设置亮度值。
    brightnessFilter.brightness = self.slider1.value;
    //    数据源处理图像，开始渲染
//    [movieFile processMovieFrame:<#(CMSampleBufferRef)#>];
}

//添加水印
- (void)lzAddWatermark {
    CALayer *waterMark =  [CALayer layer];
    waterMark.backgroundColor = [UIColor greenColor].CGColor;
    waterMark.frame = CGRectMake(8, 8, 20, 20);
    [self.gpuImageView.layer addSublayer:waterMark];
}

- (void)brightness2{
    UIImage *image = [UIImage imageNamed:@"3"];
    
    //    在GPUImageBrightnessFilter中首先初始化该滤镜
    GPUImageBrightnessFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    _brightnessFilter = brightnessFilter;
    
    //    设置亮度调整范围为整张图像
    [brightnessFilter forceProcessingAtSize:image.size];
    [brightnessFilter useNextFrameForImageCapture];
    
    
    //    获取数据源
    GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:image smoothlyScaleOutput:YES];
    _pic = pic;
    
    
    //    设置GPUImage响应链，从数据源 => 滤镜 => 最终界面效果
    [pic addTarget:brightnessFilter]; //   ① 添加上滤镜
    [brightnessFilter addTarget:self.gpuImageView]; // ② 添加效果界面
    

    //    设置亮度值。
    brightnessFilter.brightness = self.slider1.value;
    //    数据源处理图像，开始渲染
    [pic processImage];
}

- (IBAction)processmMovie:(id)sender{
    /**
     *  在快手(或秒拍)下载的小视频，大小637KB，时长8s，尺寸480x640
     *
     *  http://tx2.a.yximgs.com/upic/2016/07/01/21/BMjAxNjA3MDEyMTM4MjhfNzIwMjExNF84NTc1MTQ1NjJfMl8z.mp4?tag=1-1467534669-w-0-25bdx25jov-5a63ad5ba6299f84
     */
    NSURL *sampleURL = [[NSBundle mainBundle]URLForResource:@"demo" withExtension:@"mp4" subdirectory:nil];
    
    /**
     *  初始化 movie
     */
    _movieFile = [[GPUImageMovie alloc] initWithAsset:self.segment.asset];

    /**
     *  是否重复播放
     */
    _movieFile.shouldRepeat = NO;
    
    /**
     *  控制GPUImageView预览视频时的速度是否要保持真实的速度。
     *  如果设为NO，则会将视频的所有帧无间隔渲染，导致速度非常快。
     *  设为YES，则会根据视频本身时长计算出每帧的时间间隔，然后每渲染一帧，就sleep一个时间间隔，从而达到正常的播放速度。
     */
    _movieFile.playAtActualSpeed = YES;
    
    /**
     *  设置代理 GPUImageMovieDelegate，只有一个方法 didCompletePlayingMovie
     */
    _movieFile.delegate = self;
    
    /**
     *  This enables the benchmarking mode, which logs out instantaneous and average frame times to the console
     *
     *  这使当前视频处于基准测试的模式，记录并输出瞬时和平均帧时间到控制台
     *
     *  每隔一段时间打印： Current frame time : 51.256001 ms，直到播放或加滤镜等操作完毕
     */
    _movieFile.runBenchmark = YES;
    
    /**
     *  添加卡通滤镜
     */
    GPUImageBrightnessFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    _brightnessFilter = brightnessFilter;
    [_movieFile addTarget:_brightnessFilter];
    
    /**
     *  添加显示视图
     */
    [_brightnessFilter addTarget:self.gpuImageView];
    
    /**
     *  视频处理后输出到 GPUImageView 预览时不支持播放声音，需要自行添加声音播放功能
     *
     *  开始处理并播放...
     */
    [_movieFile startProcessing];
}

- (void)ddd{
    /*/ 播放
    _movieFile = [[GPUImageMovie alloc] initWithAsset:self.recordSession.assetRepresentingSegments];
    _movieFile.delegate = self;
    _movieFile.runBenchmark = YES;
    _movieFile.playAtActualSpeed = YES;
    _movieFile.shouldRepeat = YES;
    
    //    filter = [[GPUImageSketchFilter alloc] init];
    GPUImageToonFilter *filter = [[GPUImageToonFilter alloc] init];//胶片效果
    //    [(GPUImageDissolveBlendFilter *)filter setMix:0.5];
    [_movieFile addTarget:filter];
    
    
    NSString *filename = [NSString stringWithFormat:@"LZVideoEdit-%ld.m4v", (long)_segments.count];
    NSURL *movieURL = [LZVideoTools filePathWithFileName:filename isFilter:NO];
    
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 480.0)];
    movieWriter.shouldPassthroughAudio = YES;
    _movieFile.audioEncodingTarget = movieWriter;
    [_movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    // 显示到界面
    [filter addTarget:self.filterView];
    //    [filter addTarget:movieWriter];
    
    //    [movieWriter startRecording];
    [_movieFile startProcessing];
    
    __weak typeof(self) weakSelf = self;
    [movieWriter setCompletionBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        [filter removeTarget:strongSelf->movieWriter];
        [strongSelf->movieWriter finishRecording];
    }];*/
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
    self.playerItem = [[AVPlayerItem alloc]initWithURL:self.segment.url];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    self.movieFile = [[GPUImageMovie alloc] initWithPlayerItem:self.playerItem];
    self.movieFile.delegate = self;
    self.movieFile.playAtActualSpeed = YES;
    
    _brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    [_brightnessFilter addTarget:self.gpuImageView];
    [self.movieFile addTarget:_brightnessFilter];
    [self.movieFile startProcessing];
    
//    dispatch_async(dispatch_get_main_queue(), ^{
        [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
//    });
    
    
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

#pragma mark - Event
- (void)navbarRightButtonClickAction:(UIButton*)sender {
    NSURL *tempPath = self.segment.url;
    NSString *filename = [LZVideoTools getFileName:[tempPath absoluteString]];
    tempPath = [LZVideoTools filePathWithFileName:[NSString stringWithFormat:@"%@.m4v", filename] isFilter:YES];
    
    [self.recordSession removeAllSegments:NO];
    
    CMTime start = CMTimeMakeWithSeconds(self.segment.startTime, self.segment.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(self.segment.endTime - self.segment.startTime, self.segment.duration.timescale);
    CMTimeRange range = CMTimeRangeMake(start, duration);
    
    [LZVideoTools exportVideo:self.segment.asset videoComposition:nil filePath:tempPath timeRange:range completion:^(NSURL *savedPath) {
        if(savedPath) {
            DLog(@"导出视频路径：%@", savedPath);
            LZSessionSegment * newSegment = [LZSessionSegment segmentWithURL:tempPath filter:self.segment.filter];
            [self.recordSegments removeObject:self.segment];
            [self.recordSegments insertObject:newSegment atIndex:self.currentSelected];
            
            for (int i = 0; i < self.recordSegments.count; i++) {
                LZSessionSegment * segment = self.recordSegments[i];
                NSAssert(segment.url != nil, @"segment url must be non-nil");
                if (segment.url != nil) {
                    [self.recordSession insertSegment:segment atIndex:i];
                }
            }
            
            [self.navigationController popViewControllerAnimated:YES];
        }
        else {
            DLog(@"导出视频路径出错：%@", savedPath);
        }
    }];
}

//播放或暂停
- (IBAction)filterClicked:(UIButton *)button{
    if (!(self.player.rate > 0)) {
        [self.player play];
        [self.playButton setImage:nil forState:UIControlStateNormal];
    }else{
        [self.player pause];
        [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
    }
}

- (IBAction)updateSliderValue:(UISlider *)sender{
    switch (sender.tag) {
        case 1: {//亮度
            _brightnessFilter.brightness = sender.value;
//            [_pic processImage];
        }
            break;
        case 2: {//对比度
            
        }
            break;
        case 3: {//饱和度
            
        }
            break;
        case 4: {//锐度
            
        }
            break;
        case 5: {//色温
            
        }
            break;
        case 6: {//暗度
            
        }
            break;
            
    }
    if (sender.value == sender.maximumValue/2) {
        sender.thumbTintColor = [UIColor blueColor];
    }else{
        sender.thumbTintColor = [UIColor greenColor];
    }
    DLog(@"%f",sender.value);
    [self.player play];
    [self.playButton setImage:nil forState:UIControlStateNormal];
    
    GPUImageFilterGroup *filters = [[GPUImageFilterGroup alloc]init];
}

- (void)dealloc{
    [self.player removeTimeObserver:self.timeObser];
    DLog(@"========= dealloc =========");
}

#pragma mark -
- (void)retrievingProgress {
    NSLog(@"Sample Complete:%f", self.movieFile.progress);
    if(self.movieFile.progress == 1) {
        [_timer invalidate];
        [_movieFile endProcessing];
        [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
    }
}

- (void)didCompletePlayingMovie{
    NSLog(@"已完成播放");
    [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
}





/* 获取视频缩略图 */
- (UIImage *)getThumbnailImageRequestAtTimeSecond:(CMTime)timeBySecond {
    //视频文件URL地址
    NSURL *url = [NSURL URLWithString:@"http://192.168.6.147/2.mp4"];
    //创建媒体信息对象AVURLAsset
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
    //创建视频缩略图生成器对象AVAssetImageGenerator
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.segment.asset];
    //创建视频缩略图的时间，第一个参数是视频第几秒，第二个参数是每秒帧数
    CMTime time = timeBySecond;//CMTimeMake(timeBySecond, 10);
    CMTime actualTime;//实际生成视频缩略图的时间
    NSError *error = nil;//错误信息
    //使用对象方法，生成视频缩略图，注意生成的是CGImageRef类型，如果要在UIImageView上显示，需要转为UIImage
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
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



    /*/ Set paused time. If player reaches end of the video, set pausedTime to 0.
    if (CMTimeCompare(pausedTime, self.player.currentItem.asset.duration)) {
        pausedTime = self.player.currentTime;
    } else {
        pausedTime = kCMTimeZero;
        self.player.rate = 0;
    }

    [_movieFile cancelProcessing];
    
    switch (button.tag){
        case 0:
            filter = nil;
            filter = [[GPUImageFilter alloc] init];
            break;
        case 1:
            filter = nil;
            filter = [[GPUImageColorInvertFilter alloc] init];
            break;
        case 2:
            filter = nil;
            filter = [[GPUImageEmbossFilter alloc] init];
            break;
        case 3:
            filter = nil;
            filter = [[GPUImageGrayscaleFilter alloc] init];
            break;
        default:
            filter = nil;
            filter = [[GPUImageFilter alloc] init];
            break;
    }
    
    [self filterVideo];
}

//当用户选择一个过滤器。
- (void)filterVideo {
    self.playerItem = [[AVPlayerItem alloc]initWithAsset:self.segment.asset];
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];

    self.movieFile = [[GPUImageMovie alloc] initWithPlayerItem:self.playerItem];
    self.movieFile.delegate = self;
    self.movieFile.playAtActualSpeed = YES;
    
    filter = [[GPUImageBrightnessFilter alloc] init];
    [self.movieFile addTarget:filter];
    [filter addTarget:self.gpuImageView];
    
    [self.movieFile startProcessing];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.playButton setImage:nil forState:UIControlStateNormal];
    });
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(retrievingProgress) userInfo:nil repeats:NO];

    self.player.rate = 1.0;
}*/


@end
