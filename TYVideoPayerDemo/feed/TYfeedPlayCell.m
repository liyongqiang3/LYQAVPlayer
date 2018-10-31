//
//  TYfeedPlayCell.m
//  TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/17.
//  Copyright © 2018 yongqiang. All rights reserved.
//

#import "TYfeedPlayCell.h"
#import <TYVideoPlayer/TYVideoPlayer.h>
#import "TYVideoConfiguration.h"
#import <Masonry/Masonry.h>
#import "UIView+Gesture.h"

@interface TYfeedPlayCell () <TYVideoPlayerManageDelegate,TYVideoPlayerNetworkDelegate>

@property (nonatomic) TYVideoPlayerManger *playerManger;
@property (nonatomic,copy) NSString *videoUrl;
@property (nonatomic, strong) UIButton *playButton;


@end

@implementation TYfeedPlayCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.playButton];
        self.playButton.hidden = YES;
        [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.contentView);
            make.height.equalTo(@50);
            make.width.equalTo(@50);
        }];
        [self resetPlayer];
        [self.contentView addTapAction:@selector(onClickPause) target:self];
     
    }
    return self;
}

- (void)configWithVideoUrl:(NSString *)videoUrl size:(CGSize)size
{
//    self.videoUrl = videoUrl;
    [self.playerManger setContentURLStringList:@[videoUrl]];
    self.playerManger.playerView.frame = CGRectMake(0, 0, size.width, size.height);
    //
    [self updateSetting];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.playButton.hidden = YES;
    [self stop];
    [self resetPlayer];
   
}

- (void)didEndDisplay
{
    [self stop];
    [self resetPlayer];
}

- (void)updateSetting
{
    self.playerManger.useCache = TYVideoConfiguration_Singleton.useCache;
    self.playerManger.repeated = TYVideoConfiguration_Singleton.repeated;
    self.playerManger.scalingMode = TYVideoConfiguration_Singleton.scalingMode;
    self.playerManger.rotateType = TYVideoConfiguration_Singleton.rotateType;
    self.playerManger.playbackRate = TYVideoConfiguration_Singleton.playbackRate;
}

- (void)prepareToPlay
{
    [self.playerManger prepareToPlay];
}

- (void)play
{
    [self.playerManger play];
}

- (BOOL)isPlaying
{
    return [self.playerManger isPlaying];
}

- (void)pause
{
    [self.playerManger pause];
}

- (void)stop
{
    [self.playerManger stop];
}

- (void)resetPlayer
{
    if(self.playerManger && self.playerManger.playerView){
        [self.playerManger.playerView removeFromSuperview];
    }
    self.playerManger = [[TYVideoPlayerManger alloc] init];
    self.playerManger.truncateTailWhenRepeated = YES;
    self.playerManger.networkDelegate = self;
    self.playerManger.playDelegate = self;
    [self.contentView addSubview:self.playerManger.playerView];
    if (self.playButton.superview) {
        [self.contentView bringSubviewToFront:self.playButton];
    }
}

- (UIButton *)playButton
{
    if (!_playButton) {
        _playButton = [[UIButton alloc]initWithFrame:CGRectZero];
        [_playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(onClickPlaying) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}

- (void)onClickPlaying
{
    if (!self.isPlaying) {
        [self play];
        self.playButton.hidden = YES;
    }
}

- (void)onClickPause
{
    if ([self isPlaying]) {
        [self pause];
        self.playButton.hidden = NO;
    } else {
        [self play];
        self.playButton.hidden = YES;
    }
}


#pragma  mark --- TYVideoPlayerNetworkDelegate
- (void)didReceiveMetaForURL:(NSURL *)URL mimeType:(NSString *)mimeType cacheSize:(NSUInteger)cacheSize fileSize:(NSUInteger)fileSize
{
//    NSLog(@" ULR =%@ mimeType=%@ cacheSize=%@ fileSize=%@",URL.absoluteString,mimeType,@(cacheSize),@(fileSize));

}

- (void)failToRetrieveMetaForURL:(NSURL *)URL error:(NSError *)error
{
    // do nothing
}

#pragma  mark --- TYVideoPlayerManageDelegate

- (void)playbackStateDidChangeForURL:(NSURL *)URL oldState:(TYVideoPlaybackState)oldState newState:(TYVideoPlaybackState)newState
{
  
}

- (void)preparedToPlayForURL:(NSURL *)URL
{
//    [LXYToast show:@"preparedToPlay"];
}

- (void)readyForDisplayForURL:(NSURL *)URL
{
//    [LXYToast show:@"readyForDisplay"];
}


@end
