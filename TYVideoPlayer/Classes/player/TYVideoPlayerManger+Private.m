//
//  TYVideoPlayerManger+Private.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/14.
//

#import "TYVideoPlayerManger+Private.h"
#import "TYVideoDiskCacheDeleteManager.h"
#import "TYVideoResourceDeallocManager.h"
#import "TYVideoPlayerManger+Error.h"

#define GARBAGE_COLLECT(_obj_)          [[TYVideoResourceDeallocManager sharedInstance] addResourceObject:(_obj_)]


@implementation TYVideoPlayerManger (Private)

- (void)_resetInitialStates
{
    self.isPreparedToPlay = NO;
    self.isReadyForDisplay = NO;
    self.initialized = NO;
    self.duration = 0;
    self.state = TYVideoPlayerStateInitialized;
    self.playbackState = TYVideoPlaybackStateStopped;
    self.bufferingProgress = 0;
}

- (void)_resetPlayer
{
//    TY_VIDEO_DEBUG(@"%@ resetPlayer", self.currentItemKey);
    
    if (self.resourceLoader) {
        [self.resourceLoader stopLoading];
        self.resourceLoader = nil;
    }
    
    // KVO
    if (self.contentView.playerLayer) {
        TYVideo_RemoveKVOObserverSafely(self.contentView.playerLayer, self, @"readyForDisplay");
        //
        [self.contentView.playerLayer removeFromSuperlayer];
        self.contentView.playerLayer = nil;
    }
    
    if (self.currentItem) {
        [self removePlayerItemObservers:self.currentItem];
    }
    if (self.player) {
        [self removePlayerObservers:self.player];
    }
    
    // Player
    if (self.player) {
        [self.player pause];
        [self.player cancelPendingPrerolls];
        self.player = nil;
    }
    
    // Asset
    if (self.currentAsset) {
        [self.currentAsset cancelLoading];
        GARBAGE_COLLECT(self.currentAsset);
        self.currentAsset = nil;
    }
    
    // PlayerItem
    if (self.currentItem) {
        [self.currentItem cancelPendingSeeks];
        GARBAGE_COLLECT(self.currentItem);
        self.currentItem = nil;
    }
    
    self.contentView.playerLayer = nil;
    self.contentView.initialized = NO;
    
    self.initialized = NO;
}

- (void)_initializePlayer
{
    if (self.currentItem) {
        [self removePlayerItemObservers:self.currentItem];
    }
    self.currentItem = [AVPlayerItem playerItemWithAsset:self.currentAsset];
    [self addPlayerItemObservers:self.currentItem];
    
    if (self.player) {
        [self removePlayerObservers:self.player];
    }
    self.player = [AVPlayer playerWithPlayerItem:self.currentItem];
    [self addPlayerObservers:self.player];
    
    if (self.resourceLoader) {
        if (@available(iOS 10.0, *)) {
            self.player.automaticallyWaitsToMinimizeStalling = NO;
        }
    }
    
    self.player.muted = self.muted;
    
    if (self.repeated) {
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    }
    
    self.initialized = YES;
}

- (void)_continuePlayFromWaiting
{
    if (self.state == TYVideoPlayerStatePlay) {
        self.player.rate = self.playbackRate;
    }
}

- (void)_setContentURLString:(NSString *)urlString
{
    NSURL *url = nil;
    
    if (TYVideo_isEmptyString(urlString)) {
        self.contentURL = nil;
        return;
    }
    
    if ([urlString rangeOfString:@"/"].location == 0) {
        url = [NSURL fileURLWithPath:urlString];
    } else {
        url = [NSURL URLWithString:urlString];
    }
    
    self.contentURL = url;
}

- (void)_enumerateAllAudioPlayersWithBlock:(void(^)(AVAudioPlayer *audioPlayer, BOOL shouldPlayWhileVideoPlay))block
{
    [self.audioMixDict.allValues enumerateObjectsUsingBlock:^(NSArray * _Nonnull value, NSUInteger idx, BOOL * _Nonnull stop) {
        AVAudioPlayer *audioPlayer = value[0];
        if (audioPlayer && ![audioPlayer isEqual:[NSNull null]]) {
            block(audioPlayer, [value[1] boolValue]);
        }
    }];
}

#pragma mark - Player Observers

- (void)addPlayerObservers:(AVPlayer *)player
{
    [self.periodicTimeObserverDict.allKeys enumerateObjectsUsingBlock:^(NSArray * _Nonnull param, NSUInteger idx, BOOL * _Nonnull stop) {
        CMTime interval = ((NSValue *)param[0]).CMTimeValue;
        void (^block)(CMTime time,NSTimeInterval totalTime,NSInteger curIndex) = param[1];
        //
        NSTimeInterval totalTime = self.duration;
        NSInteger urlIndex = self.currentURLIndex;
        id observer =
        [player addPeriodicTimeObserverForInterval:interval queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            block(time,totalTime,urlIndex);
        }];
        //
        [self.periodicTimeObserverDict setObject:observer forKey:param];
    }];
    
    [self.boundaryTimeObserverDict.allKeys enumerateObjectsUsingBlock:^(NSArray * _Nonnull param, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<NSValue *> *times = param[0];
        void (^block)(void) = param[1];
        //
        id observer =
        [player addBoundaryTimeObserverForTimes:times queue:dispatch_get_main_queue() usingBlock:^{
            block();
        }];
        //
        [self.boundaryTimeObserverDict setObject:observer forKey:param];
    }];
}

- (void)removePlayerObservers:(AVPlayer *)player
{
    [self.periodicTimeObserverDict.allKeys enumerateObjectsUsingBlock:^(NSArray * _Nonnull param, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.periodicTimeObserverDict[param] != [NSNull null]) {
            [player removeTimeObserver:self.periodicTimeObserverDict[param]];
            //
            [self.periodicTimeObserverDict setObject:[NSNull null] forKey:param];
        }
    }];
    
    [self.boundaryTimeObserverDict.allKeys enumerateObjectsUsingBlock:^(NSArray * _Nonnull param, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.boundaryTimeObserverDict[param] != [NSNull null]) {
            [player removeTimeObserver:self.boundaryTimeObserverDict[param]];
            //
            [self.boundaryTimeObserverDict setObject:[NSNull null] forKey:param];
        }
    }];
}

#pragma mark - PlayerItem Observers

- (void)addPlayerItemObservers:(AVPlayerItem *)playerItem
{
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(status))
                    options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                    context:KVO_Context_TYVideoPlayerController];
    
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(isPlaybackLikelyToKeepUp))
                    options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                    context:KVO_Context_TYVideoPlayerController];
    
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(isPlaybackBufferFull))
                    options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                    context:KVO_Context_TYVideoPlayerController];
    
    [playerItem addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(loadedTimeRanges))
                    options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                    context:KVO_Context_TYVideoPlayerController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemFailedToPlayToEndTime:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification
                                               object:playerItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemPlaybackStalled:)
                                                 name:AVPlayerItemPlaybackStalledNotification
                                               object:playerItem];
}

- (void)removePlayerItemObservers:(AVPlayerItem *)currentItem
{
    TYVideo_RemoveKVOObserverSafely(currentItem, self, NSStringFromSelector(@selector(status)));
    TYVideo_RemoveKVOObserverSafely(currentItem, self, NSStringFromSelector(@selector(isPlaybackLikelyToKeepUp)));
    TYVideo_RemoveKVOObserverSafely(currentItem, self, NSStringFromSelector(@selector(isPlaybackBufferFull)));
    TYVideo_RemoveKVOObserverSafely(currentItem, self, NSStringFromSelector(@selector(loadedTimeRanges)));
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:nil
                                                  object:currentItem];
}

#pragma mark - Notifications

- (void)playerItemFailedToPlayToEndTime:(NSNotification *)notification
{
    NSError *error = [notification.userInfo objectForKey:AVPlayerItemFailedToPlayToEndTimeErrorKey];
    if (!error) {
        error = TYError(TYVideoPlayerErrorPlayerItemFailedToPlayToEndTime, nil);
    }
    
//    TY_VIDEO_DEBUG(@"%@ playerItemFailedToPlayToEndTime: error = %@", self.currentItemKey, error);
    
    [self playbackDidFailWithError:error];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
//    TY_VIDEO_DEBUG(@"%@ playerItemDidReachEnd", self.currentItemKey);
    //[self retryPlayIfNeeded] == YES)
    dispatch_async_on_main_queue(^{
        if (self.playDelegate && [self.playDelegate respondsToSelector:@selector(playbackDidFinishForVideoDuration:URL:)]) {
            [self.playDelegate playbackDidFinishForVideoDuration:self.duration URL:self.contentURL];
        }
    });
    if ((self.repeated&&self.contentURLStringList.count == 1) || (self.repeated &&[self retryPlayIfNeeded])){
        [self _seekToTime:kCMTimeZero shouldPlay:YES];
        dispatch_async_on_main_queue(^{
            if (self.playDelegate && [self.playDelegate respondsToSelector:@selector(playbackDidStartForVideoDuration:URL:)]) {
                [self.playDelegate playbackDidStartForVideoDuration:self.duration URL:self.contentURL];
            }
        });
    } else {
        self.state = TYVideoPlayerStateCompleted;
        self.playbackState = TYVideoPlaybackStateStopped;
        
        [TYVideoDiskCacheDeleteManager endUseCacheForKey:self.currentItemKey];
    }
    
  
}

- (void)playerItemPlaybackStalled:(NSNotification *)notification
{
    self.playbackState = TYVideoPlaybackStateStalled;
}

- (void)_seekToTime:(CMTime)time shouldPlay:(BOOL)shouldPlay
{
    @try {
        [self.player seekToTime:time completionHandler:^(BOOL finished) {
            if (finished && shouldPlay) {
                [self _continuePlayFromWaiting];
            }
        }];
        
    } @catch (NSException *exception) {
        // do nothing
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    __block NSURL *targetURL = nil;
    [self.audioMixDict enumerateKeysAndObjectsUsingBlock:^(NSURL * _Nonnull key, NSArray * _Nonnull value, BOOL * _Nonnull stop) {
        if (player == value[0]) {
            targetURL = key;
            *stop = YES;
        }
    }];
    
    [self.audioMixDict setObject:@[player, @(NO)] forKey:targetURL];
}


@end
