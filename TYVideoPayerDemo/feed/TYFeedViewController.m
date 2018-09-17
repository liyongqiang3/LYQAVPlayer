//
//  TYFeedViewController.m
//  TYVideoPayerDemo
//
//  Created by yongqiang li on 2018/9/14.
//  Copyright © 2018 yongqiang. All rights reserved.
//

#import "TYFeedViewController.h"
#import "TYVideoConfiguration.h"
#import "TYfeedPlayCell.h"
#import <TYVideoPlayer/TYVideoPlayer.h>

#define FLOAT_ZERO                      0.00001f
#define FLOAT_EQUAL_ZERO(a)             (fabs(a) <= FLOAT_ZERO)
#define FLOAT_GREATER_THAN(a, b)        ((a) - (b) >= FLOAT_ZERO)
#define FLOAT_EQUAL_TO(a, b)            FLOAT_EQUAL_ZERO((a) - (b))
#define FLOAT_LESS_THAN(a, b)           ((a) - (b) <= -FLOAT_ZERO)

@interface TYFeedViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray <NSString *> *dataArray;

@end

@implementation TYFeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"feed";
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [self initDataArray];
    [self.tableView reloadData];
  
}

- (void)initDataArray
{
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    [TYVideoPrefetchTaskManager setEnablePrefetchWIFIOnly:NO];
    TYVideoConfiguration_Singleton.scalingMode = TYVideoScaleModeAspectFill;
    TYVideoConfiguration_Singleton.repeated = YES;
    TYVideoConfiguration_Singleton.useCache = YES;
    TYVideoConfiguration_Singleton.rotateType = TYVideoRotateTypeNone;
      self.dataArray = @[@"http://x.tangyishipin.com/3da4c5d1274f47f29dd2bef781385716/cb26a6554e5d0e22fa2f1044d00bada9-sd.mp4",@"http://x.tangyishipin.com/0e47a53401604f98928ee0ce2dc14526/fb9415213c16b42b7acf1e563a869189-sd.mp4",@"http://x.tangyishipin.com/e8314e356bd24c08a9938013f821f7b9/af276858b06ca0323f8f9c326c7ec2eb-sd.mp4",@"http://x.tangyishipin.com/2ca82d4e29f7488f9e5621c519e2d9f6/20602b1a2cc081d4fcf945627c7ad741-sd.mp4",@"http://x.tangyishipin.com/4b281533e14c42948e4532e4cab99d14/5244c866d57d01ff2da2c12523201240-sd.mp4",@"http://x.tangyishipin.com/32e17d80e9fe4b81ba2eaa7370a2ae09/fe23b1a686762f6fb494f7b417fc3666-sd.mp4",@"http://x.tangyishipin.com/df62e10f271041e3a4f725d2a87cc14e/eea50cc47f83489706a2f4d8528c3fc8-sd.mp4",@"http://x.tangyishipin.com/eef206145536491c8e12b6ae3e606699/5401529ab2591f1cef832653d49ddd0b-sd.mp4",@"http://x.tangyishipin.com/9e334dfc67cf46d49b2be9dfc57ebeb8/a294061e98da5e6ff85b260fb30fefeb-sd.mp4"];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.tableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame),  CGRectGetHeight(self.view.frame));
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.separatorColor = [UIColor clearColor];
        _tableView.scrollsToTop = NO;
        _tableView.pagingEnabled = YES;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _tableView;
}

#pragma  mark ---- UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TYfeedPlayCell *cell = [tableView dequeueReusableCellWithIdentifier:@"playCell"];
    if (!cell) {
        cell = [[TYfeedPlayCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"playCell"];
    }
    if (self.dataArray.count > indexPath.row) {
        NSString *videoUrl = self.dataArray[indexPath.row];
        [cell configWithVideoUrl:videoUrl size:CGSizeMake(CGRectGetWidth(self.tableView.frame),
                                                          CGRectGetHeight(self.tableView.frame))];
    }
    return cell;
    
}

#pragma  mark --- UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CGRectGetHeight(self.tableView.frame);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TYfeedPlayCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell isPlaying]) {
        [cell pause];
    } else {
        [cell play];
    }
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //    NSLog(@"willDisplayCell %@", @(indexPath.row));
    
    TYfeedPlayCell *feedCell = (TYfeedPlayCell *)cell;
    [feedCell prepareToPlay];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didEndDisplayingCell %@", @(indexPath.row));
    
    TYfeedPlayCell *feedCell = (TYfeedPlayCell *)cell;
    [feedCell prepareForReuse];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self _onScrollDidEnd];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self _onScrollDidEnd];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self _onScrollDidEnd];
    }
}

- (void)_onScrollDidEnd
{
    [self play];
    
    [self performSelector:@selector(_doVideoPrefetch) withObject:nil afterDelay:2];
}

#pragma mark - Play Control

- (void)play
{
    for (TYfeedPlayCell *cell in [self.tableView visibleCells]) {
        if (FLOAT_EQUAL_TO(cell.frame.origin.y, self.tableView.contentOffset.y)) {
            [cell play];
        }
    }
}

- (void)pause
{
    for (TYfeedPlayCell *cell in [self.tableView visibleCells]) {
        [cell pause];
    }
}

- (void)stop
{
    for (TYfeedPlayCell *cell in [self.tableView visibleCells]) {
        [cell stop];
    }
}

static NSString * const kPrefetchGroup = @"Feed";

- (void)_cancelVideoPrefetch
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_doVideoPrefetch) object:nil];
    //
    [TYVideoPrefetchTaskManager cancelForGroup:kPrefetchGroup];
}

- (void)_doVideoPrefetch
{
    static const NSUInteger prefetchSize = 1024 * 1024 * 2;
    
    NSInteger currentIndex = [self.tableView indexPathForCell:self.tableView.visibleCells.firstObject].row;
  
    NSInteger nextIndex = currentIndex + 1;
    if (nextIndex < self.dataArray.count) {
         NSString *videoURLString  = self.dataArray[nextIndex];
        //
        NSLog(@"VideoPrefetch=======nextIndex %@",@(nextIndex));
        [TYVideoPrefetchTaskManager prefetchWithURLString:videoURLString size:prefetchSize group:kPrefetchGroup];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self play];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];

    [self pause];
    
}


@end
