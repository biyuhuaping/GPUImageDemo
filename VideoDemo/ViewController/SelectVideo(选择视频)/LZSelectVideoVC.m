//
//  LZSelectVideoVC.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/7/17.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZSelectVideoVC.h"
#import "LZTrimCropVC.h"
#import "LZSelectVideoCollectionViewCell.h"
#import "LZVideoEditAuxiliary.h"

@interface LZSelectVideoVC ()

@property (strong, nonatomic) IBOutlet UIView *subView;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) id timeObser;
@property (assign, nonatomic) NSInteger currentSelected;

@property (strong, nonatomic) LZVideoEditAuxiliary *videoEditAuxiliary;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation LZSelectVideoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LZLocalizedString(@"select_video", nil);

    self.currentSelected = 0;
    [self configCollectionView];
    [self showVideo:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//配置collectionView
- (void)configCollectionView{
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.itemSize                 = CGSizeMake(100, 100);
    layout.minimumInteritemSpacing  = 10;
    layout.minimumLineSpacing       = 10;
    layout.sectionInset             = UIEdgeInsetsMake(10, 10, 10, 10);
    layout.scrollDirection          = UICollectionViewScrollDirectionHorizontal;
    self.collectionView.collectionViewLayout = layout;
    [self.collectionView registerClass:[LZSelectVideoCollectionViewCell class] forCellWithReuseIdentifier:@"SelectVideoCollectionCell"];
}

- (void)showVideo:(BOOL)isFirstTime{
    LZSessionSegment *segment = self.videoListSegmentArrays[self.currentSelected];
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithURL:segment.url];
    if (isFirstTime) {
        self.player = [AVPlayer playerWithPlayerItem:playerItem];
        AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        layer.frame = CGRectMake(0, 0, kScreenWidth, kScreenWidth);
        [self.subView.layer addSublayer:layer];
    }else{
        [self.player removeTimeObserver:self.timeObser];
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
    }
    [self.playButton setImage:nil forState:UIControlStateNormal];
    [self.player play];

    WS(weakSelf);
    self.timeObser = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        double current = CMTimeGetSeconds(time);
        double total = CMTimeGetSeconds(segment.asset.duration);
        if (current >= total) {
            CMTime time = CMTimeMakeWithSeconds(segment.startTime, segment.duration.timescale);
            [weakSelf.player seekToTime:time];
            [weakSelf.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
        }
    }];
    [self didSelectPlayerItem];
}

//选中视频
- (void)didSelectPlayerItem {
    //这里遍历声音设置情况
    for (int i = 0; i < self.videoListSegmentArrays.count; i++) {
        LZSessionSegment * segment = self.videoListSegmentArrays[i];
        NSAssert(segment != nil, @"segment must be non-nil");
        
        if (self.currentSelected == i) {
            segment.isSelect = YES;//设置选中
            //设置声音
            if (segment.isMute) {
                self.player.volume = 0;
            } else {
                self.player.volume = 1;
            }
        }
        else {
            segment.isSelect = NO;
        }
    }
    
    [self.collectionView reloadData];
}

#pragma mark - Event
- (IBAction)nextButtonAction:(UIButton *)sender {
    CGFloat duration = [self.videoEditAuxiliary getAllVideoTimesRecordSegments:self.recordSession.segments];
    if (duration >= 15) {//如果已录制的视频 >=15秒，就止步于此，不能进入视频剪裁页。
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:LZLocalizedString(@"edit_message", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"ok", nil];
        [alert show];
        return;
    }
    else if (self.currentSelected >= 0) {
        LZTrimCropVC * vc = [[LZTrimCropVC alloc] initWithNibName:@"LZTrimCropVC" bundle:nil];
        vc.recordSession = self.recordSession;
        vc.segment = self.videoListSegmentArrays[self.currentSelected];
        [self.navigationController pushViewController:vc animated:YES];
        
        NSMutableArray *vcArrays = [[NSMutableArray alloc]initWithArray:self.navigationController.viewControllers];
        [vcArrays removeObject:self];
        self.navigationController.viewControllers = vcArrays;
    }
    else {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"选择视频" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}

//播放或暂停
- (IBAction)lzPlayOrPause:(UIButton *)button{
    if (!(self.player.rate > 0)) {
        [self.player play];
        [self.playButton setImage:nil forState:UIControlStateNormal];
    }else{
        [self.player pause];
        [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.videoListSegmentArrays.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identify = @"SelectVideoCollectionCell";
    LZSelectVideoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identify forIndexPath:indexPath];
    LZSessionSegment * segment = self.videoListSegmentArrays[indexPath.row];
    NSAssert(segment.url != nil, @"segment must be non-nil");
    if (segment) {
        cell.imageView.image = segment.thumbnail;
        cell.timeLabel.text = [NSString stringWithFormat:@" %.2f ", CMTimeGetSeconds(segment.duration)];
        if (segment.isSelect) {
            cell.imageView.layer.borderWidth = 2;
            cell.imageView.layer.borderColor = UIColorFromRGB(0xffffff, 1).CGColor;
        } else {
            cell.imageView.layer.borderWidth = 0;
            cell.imageView.layer.borderColor = [UIColor clearColor].CGColor;
        }
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.currentSelected == indexPath.row) {
        return;
    }
    self.currentSelected = indexPath.row;
    [self showVideo:NO];
}

@end
