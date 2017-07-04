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

@interface LZVideoAdjustVC ()

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

//添加水印
- (void)lzAddWatermark {
    CALayer *waterMark =  [CALayer layer];
    waterMark.backgroundColor = [UIColor greenColor].CGColor;
    waterMark.frame = CGRectMake(8, 8, 20, 20);
    [self.gpuImageView.layer addSublayer:waterMark];
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
        sender.thumbTintColor = [UIColor blueColor];
    }else{
        sender.thumbTintColor = [UIColor greenColor];
    }
    DLog(@"%f",sender.value);
//    [self.player play];
//    [self.playButton setImage:nil forState:UIControlStateNormal];
}

- (void)dealloc{
    [self.player removeTimeObserver:self.timeObser];
    DLog(@"========= dealloc =========");
}

@end
