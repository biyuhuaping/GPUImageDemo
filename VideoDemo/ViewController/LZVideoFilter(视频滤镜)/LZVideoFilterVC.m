//
//  LZVideoFilterVC.m
//  VideoDemo
//
//  Created by biyuhuaping on 2017/7/7.
//  Copyright © 2017年 biyuhuaping. All rights reserved.
//

#import "LZVideoFilterVC.h"
#import "LZCameraFilterCollectionView.h"
#import "LZVideoEditCollectionViewCell.h"
#import "LewReorderableLayout.h"

@interface LZVideoFilterVC ()<LZCameraFilterViewDelegate,LewReorderableLayoutDelegate, LewReorderableLayoutDataSource>{
    GPUImageMovieWriter *movieWriter;
}

@property (strong, nonatomic) IBOutlet GPUImageView *gpuImageView;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) GPUImageMovie *movieFile;
@property (strong, nonatomic) LZSessionSegment *segment;
@property (strong, nonatomic) GPUImageOutput<GPUImageInput> *filter;

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) id timeObser;

@property (strong, nonatomic) IBOutlet LZCameraFilterCollectionView *cameraFilterView;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *recordSegments;

@property (assign, nonatomic) NSInteger currentSelected;

@end

@implementation LZVideoFilterVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"滤镜";
    
    self.currentSelected = 0;
    self.segment = self.recordSession.segments[self.currentSelected];
    self.recordSegments = [NSMutableArray arrayWithArray:self.recordSession.segments];

    self.filter = [[GPUImageExposureFilter alloc]init];
    [self configNavigationBar];
    [self configPlayerView:YES];
    [self configCameraFilterView];
    [self configCollectionView];
    [self didSelectPlayerItem];
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
    [button setTitle:LZLocalizedString(@"edit_done", @"") forState:UIControlStateNormal];
    [button setTitleColor:UIColorFromRGB(0xffffff, 1) forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectMake(0, 0, CGRectGetWidth(button.bounds), 40);
    button.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
    [button addTarget:self action:@selector(navbarRightButtonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:button];
}

- (void)configPlayerView:(BOOL)isFirstTime{
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithURL:self.segment.url];
    if (isFirstTime) {
        self.player = [AVPlayer playerWithPlayerItem:playerItem];
        [self.playButton setImage:[UIImage imageNamed:@"播放"] forState:UIControlStateNormal];
    }else{
        [self.player replaceCurrentItemWithPlayerItem:playerItem];
        [self.player removeTimeObserver:self.timeObser];
        [self.player play];
        [self.playButton setImage:nil forState:UIControlStateNormal];
    }
    
    self.movieFile = [[GPUImageMovie alloc] initWithPlayerItem:playerItem];
    self.movieFile.playAtActualSpeed = YES;
    
    [self.filter addTarget:self.gpuImageView];
    [self.movieFile addTarget:self.filter];
    [self.movieFile startProcessing];
    
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

#pragma mark - Event
- (void)navbarRightButtonClickAction:(UIButton*)sender{
    
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
    self.segment = self.recordSession.segments[self.currentSelected];

    //显示当前片段
    [self configPlayerView:NO];
    [self didSelectPlayerItem];
}

#pragma mark - cameraFilterView delegate
- (void)switchCameraFilter:(NSInteger)index {
    [self.movieFile removeAllTargets];
    [self.filter removeAllTargets];
    self.movieFile = nil;
    
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
    
    [self configPlayerView:NO];
}

//选中视频
- (void)didSelectPlayerItem {
    //这里遍历声音设置情况
    for (int i = 0; i < self.recordSegments.count; i++) {
        LZSessionSegment * segment = self.recordSegments[i];
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

- (void)dealloc{
    [self.player removeTimeObserver:self.timeObser];
    DLog(@"========= dealloc =========");
}

@end
