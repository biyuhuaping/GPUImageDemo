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

@interface LZVideoDetailsVC ()<SCPlayerDelegate,GPUImageMovieDelegate>
{
//    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
    GPUImageVideoCamera *videoCamera;
}
@property (strong, nonatomic) IBOutlet GPUImageView *videoPlayerView;
@property (strong, nonatomic) GPUImageMovie *movieFile;

@property (strong, nonatomic) SCPlayer *player;
@end

@implementation LZVideoDetailsVC
- (void)viewDidLoad {
    [super viewDidLoad];
    // 播放
    _movieFile = [[GPUImageMovie alloc] initWithAsset:self.recordSession.assetRepresentingSegments];
    _movieFile.delegate = self;
    _movieFile.runBenchmark = YES;
    _movieFile.playAtActualSpeed = YES;
    _movieFile.shouldRepeat = YES;
    
//    filter = [[GPUImageSketchFilter alloc] init];
    GPUImageToonFilter *filter = [[GPUImageToonFilter alloc] init];//胶片效果
    //    [(GPUImageDissolveBlendFilter *)filter setMix:0.5];
    [_movieFile addTarget:filter];

    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 480.0)];
    movieWriter.shouldPassthroughAudio = YES;
    _movieFile.audioEncodingTarget = movieWriter;
    [_movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    // 显示到界面
    [filter addTarget:self.videoPlayerView];
//    [filter addTarget:movieWriter];

//    [movieWriter startRecording];
    [_movieFile startProcessing];
    
//    __weak typeof(self) weakSelf = self;
//    [movieWriter setCompletionBlock:^{
//        __strong typeof(self) strongSelf = weakSelf;
//        [strongSelf->filter removeTarget:strongSelf->movieWriter];
//        [strongSelf->movieWriter finishRecording];
//    }];
}

- (void)didCompletePlayingMovie {
    NSLog(@"已完成播放");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self.player setItemByAsset:self.recordSession.assetRepresentingSegments];
//    [self.player play];
//    [self.videoPlayerView.player setItemByAsset:self.recordSession.assetRepresentingSegments];
//    [self.videoPlayerView.player play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    [self.player pause];
//    [self.videoPlayerView.player pause];
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
    _movieFile.runBenchmark = YES;
    _movieFile.playAtActualSpeed = YES;
    return;
    LZVideoEditClipVC * vc = [[LZVideoEditClipVC alloc] initWithNibName:@"LZVideoEditClipVC" bundle:nil];
    vc.recordSession = self.recordSession;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
