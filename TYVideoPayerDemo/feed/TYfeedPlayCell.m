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

@interface TYfeedPlayCell () <TYVideoPlayerManageDelegate,TYVideoPlayerNetworkDelegate>

@property (nonatomic) TYVideoPlayerManger *playerManger;

@end

@implementation TYfeedPlayCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self resetPlayer];
    }
    return self;
}

- (void)configWithVideoUrl:(NSString *)videoUrl size:(CGSize)size
{
    [self.playerManger setContentURLStringList:@[videoUrl]];
    self.playerManger.playerView.frame = CGRectMake(0, 0, size.width, size.height);
    //
    [self updateSetting];
}

- (void)awakeFromNib {
    [super awakeFromNib];
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
    self.playerManger.delegate = self;
    [self.contentView addSubview:self.playerManger.playerView];
}

#pragma  mark --- TYVideoPlayerNetworkDelegate
- (void)didReceiveMetaForURL:(NSURL *)URL mimeType:(NSString *)mimeType cacheSize:(NSUInteger)cacheSize fileSize:(NSUInteger)fileSize
{
    NSLog(@" ULR =%@ mimeType=%@ cacheSize=%@ fileSize=%@",URL.absoluteString,mimeType,@(cacheSize),@(fileSize));

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
