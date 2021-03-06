//
//  TYVideoPlayerManger+Public.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/14.
//

#import "TYVideoPlayerManger+Public.h"
#import "TYVideoPlayerDefines.h"
#import "TYVideoPlayerManger+Private.h"
#import "TYVideoDiskCacheManger.h"
#import "TYVideoResourceLoader.h"
#import "TYVideoDiskCacheDeleteManager.h"
#import "TYVideoPlayerManger+Error.h"

@implementation TYVideoPlayerManger (Public)

- (void)prepareToPlay
{
    dispatch_async_on_main_queue(^{
        [self _prepareToPlay];
    });
}

- (void)_prepareToPlay
{
    //    TY_VIDEO_INFO(@"%@ prepareToPlay: state = %@", self.currentItemKey, p_descForState(self.state));
    
    self.errorDict = [NSMutableDictionary dictionary];
    
    [self _setupResourceLoaderQueue];
    
    BOOL useCache = self.useCache && [TYVideoDiskCacheManger      hasEnoughFreeDiskSize];
    [self _prepareToPlayWithCacheEnabled:useCache completion:nil];
}

- (void)prepareToPlayWithCacheEnabled:(BOOL)useCache completion:(dispatch_block_t)completion
{
    dispatch_async_on_main_queue(^{
        [self _prepareToPlayWithCacheEnabled:useCache completion:completion];
    });
}

- (void)_prepareToPlayWithCacheEnabled:(BOOL)useCache completion:(dispatch_block_t)completion
{
    [self _resetPlayer];
    
    [self _resetInitialStates];
    self.state = TYVideoPlayerStatePrepared;
    
    //    TY_VIDEO_INFO(@"%@ prepareToPlayWithCacheEnabled: index = %@, useCache = %@", self.currentItemKey, @(self.currentURLIndex), @(useCache));
    
    self.currentUseCacheFlag = useCache;
    if (useCache && !self.contentURL.isFileURL)
    {
        self.resourceLoader = [TYVideoResourceLoader resourceLoaderWithURL:self.contentURL
                                                                      queue:self.resourceLoaderQueue
                                                           internalDelegate:self.networkDelegate];
        //
        AVURLAsset *currentAsset = [AVURLAsset URLAssetWithURL:self.cachePlayURL options:nil];
        [currentAsset.resourceLoader setDelegate:self.resourceLoader queue:self.resourceLoaderQueue];
        [self reinitializePlayerWithAsset:currentAsset completion:completion];
        //        NSLog(@"self.contentURL=== %@",self.contentURL);
        
    }
    else
    {
        //        NSLog(@"self.currentAsset.url=== %@",self.contentURL);
        
        AVURLAsset *currentAsset = [AVURLAsset URLAssetWithURL:self.contentURL options:nil];
        [self reinitializePlayerWithAsset:currentAsset completion:completion];
    }
    
    self.videoLoadBeginTime = [[NSDate date] timeIntervalSince1970];
}

- (void)reinitializePlayerWithAsset:(AVURLAsset *)asset completion:(dispatch_block_t)completion
{
    if (!asset) {
//        TY_VIDEO_ERROR(@"%@ reinitializePlayerWithAsset: asset is nil, contentURL = %@",
//                        self.currentItemKey,
//                        self.contentURL.absoluteString ? : @"");
        
        !completion ? : completion();
        [self playbackDidFailWithError:TYError(TYVideoPlayerErrorAssetNil, self.contentURL.absoluteString ? : @"")];
        
        return;
    }
    
    self.currentAsset = asset;
    
    static NSInteger g_playerItemOrderID = 0;
    ++g_playerItemOrderID;
    self.playerItemOrderID = g_playerItemOrderID;
    NSInteger orderID = g_playerItemOrderID;
    
//    TY_VIDEO_DEBUG(@"%@ loadValuesAsynchronously start", self.currentItemKey);
    
    __weak typeof(self) weakSelf = self;
    [self.currentAsset loadValuesAsynchronouslyForKeys:@[@"tracks", @"duration"] completionHandler:^{
        __weak typeof(weakSelf) strongSelf = weakSelf;
        
        NSError *error = nil;
        AVKeyValueStatus status;
        
        // duration
        status = [strongSelf.currentAsset statusOfValueForKey:@"duration" error:&error];
        switch (status) {
            case AVKeyValueStatusLoaded: {
                weakSelf.duration = CMTimeGetSeconds(weakSelf.currentAsset.duration);
                break;
            }
                
            case AVKeyValueStatusFailed:
            case AVKeyValueStatusCancelled:
            default: {
                // do nothing
                break;
            }
        }
        
        // tracks
        status = [strongSelf.currentAsset statusOfValueForKey:@"tracks" error:&error];
        switch (status) {
            case AVKeyValueStatusLoaded: {
                dispatch_async_on_main_queue
                (^{
                    __weak typeof(weakSelf) strongSelf = weakSelf;
                    
//                    TY_VIDEO_DEBUG(@"%@ loadValuesAsynchronously end", strongSelf.currentItemKey);
                    
                    if (!strongSelf) {
                        !completion ? : completion();
                        return;
                    }
                    
                    if (orderID != strongSelf.playerItemOrderID) {
                        //                        TY_VIDEO_TRACE(@"skip player item %@", @(orderID));
                        !completion ? : completion();
                        return;
                    }
                    
                    if (strongSelf.state == TYVideoPlayerStateStop) {
                        !completion ? : completion();
                        return;
                    }
                    
                    [strongSelf _initializePlayer];
                    
                    if (completion) {
                        completion();
                    }
                });
                
                break;
            }
                
            case AVKeyValueStatusFailed: {
                if (completion) {
                    completion();
                }
                
                //                TY_VIDEO_ERROR(@"%@ loadValuesAsynchronously @tracks failed: error = %@", self.currentItemKey, error);
                
                [weakSelf playbackDidFailWithError:error];
                
                break;
            }
                
            case AVKeyValueStatusCancelled:
            default: {
                // do nothing
                break;
            }
        }
    }];
    
    [self _setupAudioPlayers];
}

- (void)play
{
    dispatch_async_on_main_queue(^{
        [self _play];
    });
}

- (void)_play
{
    //    TY_VIDEO_INFO(@"%@ play: state = %@", self.currentItemKey, p_descForState(self.state));
    
    if (self.state != TYVideoPlayerStatePause
        && self.state != TYVideoPlayerStatePrepared) {
        return;
    }
    self.state = TYVideoPlayerStatePlay;
    
    self.player.rate = self.playbackRate;
    
    [TYVideoDiskCacheDeleteManager startUseCacheForKey:self.currentItemKey];
}

- (void)pause
{
    dispatch_async_on_main_queue(^{
        [self _pause];
    });
}

- (void)_pause
{
    //    TY_VIDEO_INFO(@"%@ pause: state = %@", self.currentItemKey, p_descForState(self.state));
    
    if (self.state != TYVideoPlayerStatePlay) {
        return;
    }
    self.state = TYVideoPlayerStatePause;
    
    [self.player pause];
    
    [self _enumerateAllAudioPlayersWithBlock:^(AVAudioPlayer * _Nonnull audioPlayer, BOOL shouldPlayWhileVideoPlay) {
        if ([audioPlayer isPlaying]) {
            [audioPlayer pause];
        }
    }];
}

- (void)stop
{
    dispatch_async_on_main_queue(^{
        [self _stop];
    });
}

- (void)_stop
{
    //    TY_VIDEO_INFO(@"%@ stop: state = %@", self.currentItemKey, p_descForState(self.state));
    
    if (   self.state != TYVideoPlayerStatePrepared
        && self.state != TYVideoPlayerStatePlay
        && self.state != TYVideoPlayerStatePause) {
        return;
    }
    self.state = TYVideoPlayerStateStop;
    self.playbackState = TYVideoPlaybackStateStopped;
    
    [self.player pause];
    [self _enumerateAllAudioPlayersWithBlock:^(AVAudioPlayer * _Nonnull audioPlayer, BOOL shouldPlayWhileVideoPlay) {
        [audioPlayer stop];
    }];
    
    [TYVideoDiskCacheDeleteManager endUseCacheForKey:self.currentItemKey];
    
    [self _resetPlayer];
}

#pragma mark - Private

- (void)_setupResourceLoaderQueue
{
    static unsigned long order = 0;
    NSString *queueName = [NSString stringWithFormat:@"com.TYVideoPlayer.TYVideoResourceLoader.%lu", ++order];
    self.resourceLoaderQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
}

- (void)_setupAudioPlayers
{
    [self.audioMixDict.allKeys enumerateObjectsUsingBlock:^(NSURL * _Nonnull audioURL, NSUInteger idx, BOOL * _Nonnull stop) {
        AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:NULL];
        if (audioPlayer) {
            audioPlayer.delegate = self;
            audioPlayer.enableRate = YES;
            audioPlayer.rate = self.playbackRate;
            audioPlayer.volume = self.muted ? 0.0f : 1.0f;
            //
            [audioPlayer prepareToPlay];
            
            [self.audioMixDict setObject:@[audioPlayer, @(NO)] forKey:audioURL];
        }
    }];
}

@end
