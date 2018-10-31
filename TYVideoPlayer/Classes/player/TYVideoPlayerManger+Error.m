//
//  TYVideoPlayerManger+Error.m
//  TYVideoPlayer
//
//  Created by yongqiang li on 2018/9/17.
//

#import "TYVideoPlayerManger+Error.h"
#import "TYVideoPlayerManger+Public.h"
#import "TYVideoPlayerManger+Private.h"
#import "TYVideoDiskCacheManger.h"
#import "TYVideoPlayerDefines.h"
#import "TYVideoDiskCacheDeleteManager.h"
#import "TYVideoDiskCacheConfiguration.h"

@interface TYVideoPlayerManger ()

- (void)prepareToPlayWithCacheEnabled:(BOOL)useCache completion:(dispatch_block_t)completion;

@end

@implementation TYVideoPlayerManger (Error)

- (void)playbackDidFailWithError:(NSError *)error
{
    dispatch_async_on_main_queue(^{
        [self _playbackDidFailWithError:error];
    });
}

- (void)_playbackDidFailWithError:(NSError *)error
{
    NSError *updatedError = error;
    if (self.resourceLoader && self.resourceLoader.error) {
        updatedError = self.resourceLoader.error;
    }
    
    //    LXY_VIDEO_ERROR(@"%@ playbackDidFailWithError: state = %@, error = %@", self.currentItemKey, p_descForState(self.state), updatedError);
    
    if (   updatedError
        && self.contentURL
        && ![self.errorDict objectForKey:self.contentURL]) {
        [self.errorDict setObject:updatedError forKey:self.contentURL];
    }
    
    if (!self.currentUseCacheFlag
        && self.playDelegate
        && [self.playDelegate respondsToSelector:@selector(playbackDidFailForURL:error:)]) {
        [self.playDelegate playbackDidFailForURL:self.contentURL
                                       error:self.contentURL ? self.errorDict[self.contentURL] : nil];
    }
    
    if ([self retryPlayIfNeeded]) {
        return;
    }
    
    self.state = TYVideoPlayerStateError;
    self.playbackState = TYVideoPlaybackStateStopped;
    
    [TYVideoDiskCacheDeleteManager endUseCacheForKey:self.currentItemKey];
    
    {
        NSString *logURLString = nil;
        if (self.contentURLStringList) {
            logURLString = [self.contentURLStringList componentsJoinedByString:@", "];
        } else {
            logURLString = self.contentURL.absoluteString;
        }
        logURLString = logURLString ? : @"";
        //
//        TY_VIDEO_ERROR(@"Playback fail: %@, error: %@", logURLString, self.errorDict);
        
//        if (TY_Reporter) {
//            //            LXY_Reporter(LXYReporterLabel_PlaybackError, logURLString, [self.errorDict description]);
//        }
    }
    
    [self _resetPlayer];
    
    if (self.playDelegate && [self.playDelegate respondsToSelector:@selector(playbackDidFailWithErrorDict:)]) {
        [self.playDelegate playbackDidFailWithErrorDict:self.errorDict];
    }
}

#pragma mark - Play Retry

- (BOOL)retryPlayIfNeeded
{
    if (TYVideo_isEmptyArray(self.contentURLStringList)) {
        return NO;
    }
    
    if (self.currentURLIndex + 1 >= self.contentURLStringList.count
        && !self.currentUseCacheFlag) {
        return NO;
    }
    
    if (self.currentURLIndex + 1 < self.contentURLStringList.count) {
        ++self.currentURLIndex;
    } else {
        self.currentUseCacheFlag = YES;
        //
        self.currentURLIndex = 0;
    }
    
    [self _setContentURLString:self.contentURLStringList[self.currentURLIndex]];
    
    //    LXY_VIDEO_INFO(@"%@ _retryPlayIfNeeded: index = %@, useCache = %@", self.currentItemKey, @(self.currentURLIndex), @(self.currentUseCacheFlag));
    
    if (self.playbackState == TYVideoPlaybackStatePlaying) {
        self.playbackState = TYVideoPlaybackStateStalled;
    }
    
    TYVideoPlayerState originState = self.state;
    BOOL useCache = self.currentUseCacheFlag && [TYVideoDiskCacheManger hasEnoughFreeDiskSize];
    //
    __weak typeof(self) weakSelf = self;
    [self prepareToPlayWithCacheEnabled:useCache completion:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (originState == TYVideoPlayerStatePlay) {
            [strongSelf play];
        }
    }];
    
    return YES;
}

@end
