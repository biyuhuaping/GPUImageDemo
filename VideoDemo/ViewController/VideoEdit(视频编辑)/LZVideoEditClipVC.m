//
//  LZVideoEditClipVC.m
//  laziz_Merchant
//
//  Created by biyuhuaping on 2017/4/24.
//  Copyright © 2017年 XBN. All rights reserved.
//  视频编辑页面

#import "LZVideoEditClipVC.h"
#import "LewReorderableLayout.h"            //拖动排序
#import "LZVideoEditCollectionViewCell.h"

#import "ProgressBar.h"
#import "HKMediaOperationTools.h"           //视频倒播

#import "LZVideoEditAuxiliary.h"
#import "LZVideoTools.h"

#import "GPUImage.h"
#import "GPUImageVideoCamera.h"
#import "GPUImageMovieWriter.h"
#import <AssetsLibrary/ALAssetsLibrary.h>

#import "LZPlayerView.h"

#import "LZVideoTailoringVC.h"//剪裁VC
#import "LZVideoSplitVC.h"//分割VC
#import "LZVideoSpeedVC.h"//速度VC
#import "LZVideoAdjustVC.h"//调节VC


@interface LZVideoEditClipVC ()<LewReorderableLayoutDelegate, LewReorderableLayoutDataSource, SAVideoRangeSliderDelegate>
@property (strong, nonatomic) IBOutlet GPUImageView *filterView;
@property (strong, nonatomic) GPUImageOutput<GPUImageInput> *filter;
@property (strong, nonatomic) GPUImageVideoCamera *videoCamera;

@property (strong, nonatomic) IBOutlet LZPlayerView *playerView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;//计时显示

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet UIButton *lzCopyButton;              //复制按钮
@property (strong, nonatomic) IBOutlet UIButton *lzVoiceButton;             //声音按钮
@property (strong, nonatomic) IBOutlet UIButton *lzDeleteButton;            //删除按钮
@property (strong, nonatomic) IBOutlet UILabel *hintLabel;                  //提示信息
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;        //处理倒放视频进度

@property (strong, nonatomic) LZVideoEditAuxiliary *videoEditAuxiliary;
@property (assign, nonatomic) NSInteger currentSelected;
@property (strong, nonatomic) NSMutableArray *recordSegments;
@property (nonatomic, assign) __block BOOL isReverseCancel;   //取消翻转

@property (strong, nonatomic) id timeObser;

@end

@implementation LZVideoEditClipVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = LZLocalizedString(@"edit_video", nil);
    _hintLabel.text = LZLocalizedString(@"all_video_delete", nil);
    self.currentSelected = 0;
    self.videoEditAuxiliary = [[LZVideoEditAuxiliary alloc]init];

    self.timeLabel.layer.masksToBounds = YES;
    self.timeLabel.layer.cornerRadius = 10;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(lzPlayOrPause)];
    [self.playerView addGestureRecognizer:tap];
    
    [self configNavigationBar];
    [self configCollectionView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.recordSegments = [NSMutableArray arrayWithArray:self.recordSession.segments];
    [self configPlayVideo:self.currentSelected];
    [self configTimeLabel];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.playerView.player pause];
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

//配置collectionView
- (void)configCollectionView{
    LewReorderableLayout *layout = [LewReorderableLayout new];
    layout.itemSize                 = CGSizeMake(60, 60);
    layout.minimumInteritemSpacing  = 10;
    layout.minimumLineSpacing       = 10;
    layout.sectionInset             = UIEdgeInsetsMake(10, 10, 10, 10);
    layout.scrollDirection          = UICollectionViewScrollDirectionHorizontal;
    layout.delegate                 = self;
    layout.dataSource               = self;
    self.collectionView.collectionViewLayout = layout;
    [self.collectionView registerClass:[LZVideoEditCollectionViewCell class] forCellWithReuseIdentifier:@"VideoEditCollectionCell"];
}

//配置timeLabel
- (void)configTimeLabel{
    //显示总时间
    CGFloat durationSeconds = CMTimeGetSeconds(self.recordSession.assetRepresentingSegments.duration);
    int seconds = lround(durationSeconds) % 60;
    int minutes = (lround(durationSeconds) / 60) % 60;
    self.timeLabel.text = [NSString stringWithFormat:@" %02d:%02d ", minutes, seconds];
}

//选中视频
- (void)configPlayVideo:(NSInteger)idx {
    if (idx < 0) {
        idx = 0;
    }
    
    if (idx < self.recordSegments.count) {
        [self.playerView.player removeTimeObserver:self.timeObser];
        self.imageView.hidden = NO;
        LZSessionSegment *segment = self.recordSegments[idx];
        NSAssert(segment != nil, @"segment must be non-nil");
        
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:segment.asset];
        self.playerView.player = [AVPlayer playerWithPlayerItem:item];
        
        WS(weakSelf);
        self.timeObser = [self.playerView.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            float current = CMTimeGetSeconds(time);
            float total = CMTimeGetSeconds(segment.asset.duration);
            DLog(@"当前已经播放%.2fs.",current);
            if (current >= total) {
                DLog(@"播放完毕");
                CMTime time = CMTimeMakeWithSeconds(segment.startTime, segment.duration.timescale);
                [weakSelf.playerView.player seekToTime:time];
                weakSelf.imageView.hidden = NO;
            }
        }];
    }
    
    //这里遍历声音设置情况
    for (int i = 0; i < self.recordSegments.count; i++) {
        LZSessionSegment * segment = self.recordSegments[i];
        NSAssert(segment != nil, @"segment must be non-nil");
        
        if (self.currentSelected == i) {
            segment.isSelect = YES;//设置选中
            [self setVoice:i];//设置声音
        }
        else {
            segment.isSelect = NO;
        }
    }
    
    [self.collectionView reloadData];
}

//设置声音
- (void)setVoice:(NSInteger)idx {
    LZSessionSegment * segment = self.recordSegments[idx];
    //判断当前片段的声音设置
    if (segment.isVoice) {
        if (segment.isVoice == YES) {
            self.playerView.player.volume = 1;
            [self.lzVoiceButton setImage:[UIImage imageNamed:@"lz_videoedit_voice_on"] forState:UIControlStateNormal];
        }
        else {
            self.playerView.player.volume = 0;
            [self.lzVoiceButton setImage:[UIImage imageNamed:@"lz_videoedit_voice_off"] forState:UIControlStateNormal];
        }
    }
    else { //没有设置过音频
        self.playerView.player.volume = 1;
        [self.lzVoiceButton setImage:[UIImage imageNamed:@"lz_videoedit_voice_on"] forState:UIControlStateNormal];
    }
}

#pragma mark - Event
//保存
- (void)navbarRightButtonClickAction:(UIButton*)sender {
    [self.recordSession removeAllSegments:NO];
    
    WS(weakSelf);
    dispatch_group_t serviceGroup = dispatch_group_create();
    for (int i = 0; i < weakSelf.recordSegments.count; i++) {
        DLog(@"执行剪切：%d", i);
        LZSessionSegment * segment = weakSelf.recordSegments[i];
        NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:segment.asset];
        if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {

            NSString *filename = [NSString stringWithFormat:@"SCVideoEditCut-%ld.m4v", (long)i];
            NSURL *tempPath = [LZVideoTools filePathWithFileName:filename];
            
            CMTime start = CMTimeMakeWithSeconds(segment.startTime, segment.duration.timescale);
            CMTime duration = CMTimeMakeWithSeconds(segment.endTime - segment.startTime, segment.asset.duration.timescale);
            CMTimeRange range = CMTimeRangeMake(start, duration);
            
            dispatch_group_enter(serviceGroup);
            [LZVideoTools exportVideo:segment.asset videoComposition:nil filePath:tempPath timeRange:range completion:^(NSURL *savedPath) {
                LZSessionSegment * newSegment = [[LZSessionSegment alloc] initWithURL:tempPath filter:nil];
                DLog(@"剪切url:%@", [tempPath path]);
                [weakSelf.recordSegments removeObject:segment];
                [weakSelf.recordSegments insertObject:newSegment atIndex:i];
                dispatch_group_leave(serviceGroup);
            }];
        }
    }
    
    dispatch_group_notify(serviceGroup, dispatch_get_main_queue(),^{
        DLog(@"保存到recordSession");
        for (int i = 0; i < weakSelf.recordSegments.count; i++) {
            LZSessionSegment * segment = weakSelf.recordSegments[i];
            NSAssert(segment.url != nil, @"segment url must be non-nil");
            if (segment.url != nil) {
                [weakSelf.recordSession insertSegment:segment atIndex:i];
            }
        }
        [weakSelf.navigationController popViewControllerAnimated:YES];
    });
}

//播放或暂停
- (void)lzPlayOrPause{
    if (!(self.playerView.player.rate > 0)) {
        [self.playerView.player play];
        _imageView.hidden = YES;
    }else{
        [self.playerView.player pause];
        _imageView.hidden = NO;
    }
}

//剪裁
- (IBAction)lzTailoringButtonAction:(id)sender {
    LZVideoTailoringVC *tailoringView = [[LZVideoTailoringVC alloc]initWithNibName:@"LZVideoTailoringVC" bundle:nil];
    tailoringView.recordSession = self.recordSession;
    tailoringView.currentSelected = self.currentSelected;
    [self.navigationController pushViewController:tailoringView animated:YES];
}

//分割
- (IBAction)lzSplitButtonAction:(id)sender {
    //至少1秒，才能分割
    LZSessionSegment *segment = self.recordSession.segments[self.currentSelected];
    if (CMTimeGetSeconds(segment.duration) < 1) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:LZLocalizedString(@"edit_message", nil) message:@"至少1秒，才能分割!zhoubo" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"ok", nil];
        [alert show];
        return;
    }
    LZVideoSplitVC *splitView = [[LZVideoSplitVC alloc]initWithNibName:@"LZVideoSplitVC" bundle:nil];
    splitView.recordSession = self.recordSession;
    splitView.currentSelected = self.currentSelected;
    [self.navigationController pushViewController:splitView animated:YES];
}

//复制
- (IBAction)lzCopyButtonAction:(UIButton *)sender {
    if (self.recordSegments.count == 0) {
        return;
    }
    
    LZSessionSegment * segment = [self.videoEditAuxiliary getCurrentSegment:self.recordSegments index:self.currentSelected];
    NSAssert(segment.url != nil, @"segment must be non-nil");
    
    if (CMTimeGetSeconds(segment.duration)+[self.videoEditAuxiliary getAllVideoTimesRecordSegments:self.recordSegments] > 15) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:LZLocalizedString(@"edit_message", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"ok", nil];
        [alert show];
        return;
    }
    
    LZSessionSegment * newSegment = [LZSessionSegment segmentWithURL:segment.url filter:nil];
    NSAssert(newSegment.url != nil, @"segment must be non-nil");    
    [self.recordSegments addObject:newSegment];
    
    //更新片段view
    [self.collectionView reloadData];
}

//变速
- (IBAction)lzVariableSpeedAction:(id)sender {
    LZVideoSpeedVC *viewC = [[LZVideoSpeedVC alloc]initWithNibName:@"LZVideoSpeedVC" bundle:nil];
    viewC.recordSession = self.recordSession;
    viewC.currentSelected = self.currentSelected;
    [self.navigationController pushViewController:viewC animated:YES];
}

//调节
- (IBAction)lzAdjustButtonAction:(id)sender {
    LZVideoAdjustVC *viewC = [[LZVideoAdjustVC alloc]initWithNibName:@"LZVideoAdjustVC" bundle:nil];
    viewC.recordSession = self.recordSession;
    viewC.currentSelected = self.currentSelected;
    [self.navigationController pushViewController:viewC animated:YES];
}

//声音
- (IBAction)lzVoiceButtonAction:(UIButton *)sender {
    /*LZSessionSegment * segment1 = [self.videoEditAuxiliary getCurrentSegment:self.recordSegments index:self.currentSelected];
//  AVPlayerItem *item = [LZVideoTools audioFadeOut:segment1];
    AVPlayerItem *item = [LZVideoTools videoFadeOut:segment1];
    
    [self lzAddWatermark];
    [self.playerView.player setItem:item];
    [self.playerView.player play];
    return;
     */
    
    
    if (self.recordSegments.count == 0) {
        return;
    }
    
    LZSessionSegment * segment = [self.videoEditAuxiliary getCurrentSegment:self.recordSegments index:self.currentSelected];
    NSAssert(segment.url != nil, @"segment must be non-nil");
    if (segment.isVoice) {
        segment.isVoice = NO;
        [self.lzVoiceButton setImage:[UIImage imageNamed:@"lz_videoedit_voice_off"] forState:UIControlStateNormal];
        self.playerView.player.volume = 0;
    }
    else {
        segment.isVoice = YES;
        [self.lzVoiceButton setImage:[UIImage imageNamed:@"lz_videoedit_voice_on"] forState:UIControlStateNormal];
        self.playerView.player.volume = 1;
    }
}

//倒放
- (IBAction)lzBackwardsButtonAction:(UIButton *)sender {
    if (self.recordSegments.count == 0) {
        return;
    }
    
    self.progressView.hidden = NO;
    self.isReverseCancel = NO;
    [self.playerView.player pause];
    [self.progressView setProgress:0];
    
    __block LZSessionSegment *segment = [self.videoEditAuxiliary getCurrentSegment:self.recordSegments index:self.currentSelected];
    __block LZSessionSegment *newSegment = nil;
    
    NSURL *tempPath = [LZVideoTools filePathWithFileName:@"ConponVideo.m4v" isFilter:YES];
    
    if (segment.isReverse == YES && segment.assetSourcePath != nil) {
        newSegment = [LZSessionSegment segmentWithURL:segment.assetSourcePath filter:segment.filter];
        NSAssert(newSegment.url != nil, @"segment must be non-nil");
        if(newSegment) {
            newSegment.isReverse = NO;
            newSegment.assetSourcePath = segment.assetSourcePath;
            newSegment.assetTargetPath = segment.assetTargetPath;
            
            [self.recordSegments removeObject:segment];
            [self.recordSegments insertObject:newSegment atIndex:self.currentSelected];
            
            [self configPlayVideo:self.currentSelected];
            self.progressView.hidden = YES;
        }
    }
    else {
        WS(weakSelf);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [HKMediaOperationTools assetByReversingAsset:segment.asset videoComposition:nil duration:segment.duration outputURL:tempPath progressHandle:^(CGFloat progress) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    DLog(@"%0.2f %%", progress*100);
                    [self.progressView setProgress:progress animated:YES];
                    
                    if (progress == 1.00) {
                        [self.progressView setProgress:1 animated:YES];
                        newSegment = [LZSessionSegment segmentWithURL:tempPath filter:segment.filter];
                        newSegment.startTime = segment.startTime;
                        newSegment.endTime = segment.endTime;
                        newSegment.isSelect = segment.isSelect;
                        newSegment.isVoice = segment.isVoice;
                        
                        NSAssert(newSegment.url != nil, @"segment must be non-nil");
                        if(newSegment) {
                            [newSegment setIsReverse:[NSNumber numberWithBool:YES]];
                            [newSegment setAssetSourcePath:segment.url];
                            [newSegment setAssetTargetPath:[tempPath path]];
                            
                            //更新session
                            [weakSelf.recordSegments removeObject:segment];
                            [weakSelf.recordSegments insertObject:newSegment atIndex:weakSelf.currentSelected];
                            
                            [weakSelf configPlayVideo:weakSelf.currentSelected];
                            
                            weakSelf.progressView.hidden = YES;
                        }
                    }
                });
            } cancle:&_isReverseCancel];
        });
    }
}

//添加水印
- (void)lzAddWatermark {
    CALayer *waterMark =  [CALayer layer];
    waterMark.backgroundColor = [UIColor greenColor].CGColor;
    waterMark.frame = CGRectMake(8, 8, 20, 20);
    [self.playerView.layer addSublayer:waterMark];
}

//删除
- (IBAction)lzDeleteButtonAction:(UIButton *)sender {
    if (self.recordSegments.count == 0) {
        return;
    }
    
    if(self.recordSegments.count > 0) {
        [self.recordSegments removeObject:[self.videoEditAuxiliary getCurrentSegment:self.recordSegments index:self.currentSelected]];
        if (self.currentSelected >= self.recordSegments.count) {
            self.currentSelected = self.recordSegments.count-1;
        }
        [self configPlayVideo:self.currentSelected];
    }
    
    //这里不能用 else if ，因为当删掉最后一个元素后，self.recordSegments.count 就等于0，需要进入方法内执行。
    if (self.recordSegments.count == 0) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        [self.playerView.player pause];
        
        self.playerView.hidden = YES;
        self.collectionView.hidden  = YES;
        
        self.lzCopyButton.hidden    = YES;
        self.lzVoiceButton.hidden   = YES;
        self.lzDeleteButton.hidden  = YES;
        
        self.hintLabel.hidden = NO;
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.recordSegments.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identify = @"VideoEditCollectionCell";
    LZVideoEditCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identify forIndexPath:indexPath];
    LZSessionSegment * segment = self.recordSegments[indexPath.row];
    NSAssert(segment.url != nil, @"segment must be non-nil");
    if (segment) {
        cell.imageView.image = segment.thumbnail;
        if (segment.isSelect == YES) {
            cell.markView.hidden = YES;
            cell.imageView.layer.borderWidth = 1;
            cell.imageView.layer.borderColor = [UIColor greenColor].CGColor;
        }
        else {
            cell.markView.hidden = NO;
            cell.imageView.layer.borderWidth = 0;
            cell.imageView.layer.borderColor = [UIColor clearColor].CGColor;
        }
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath didMoveToIndexPath:(NSIndexPath *)toIndexPath {
    LZSessionSegment * segment = self.recordSegments[fromIndexPath.row];
    NSAssert(segment.url != nil, @"segment must be non-nil");
    [self.recordSegments removeObject:segment];
    [self.recordSegments insertObject:segment atIndex:toIndexPath.row];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.currentSelected == indexPath.row) {
        return;
    }
    self.currentSelected = indexPath.row;
    
    //显示当前片段
    [self configPlayVideo:self.currentSelected];
}

- (void)dealloc{
    [self.playerView.player removeTimeObserver:self.timeObser];
    DLog(@"========= dealloc =========");
}

@end
