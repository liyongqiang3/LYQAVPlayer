//
//  TYVideoPlayerManageDelegate.h
//  Pods
//
//  Created by yongqiang li on 2018/9/14.
//
#import "TYVideoPlayerEnum.h"
#import <Foundation/Foundation.h>

@protocol TYVideoPlayerManageDelegate <NSObject>

@optional

/**
 * @brief received AVPlayerItemDidPlayToEndTimeNotification for @URL.
 *
 * @param URL       video URL
 */
- (void)playbackDidFinishForVideoDuration:(NSTimeInterval )duration URL:(NSURL *)URL;

/**
 * @brief received _seekToTime:kCMTimeZero for @URL.
 *
 * @param URL       video URL
 */
- (void)playbackDidStartForVideoDuration:(NSTimeInterval )duration URL:(NSURL *)URL;


/**
 * @brief the playback state for @URL changed from @oldState to @newState.
 *
 * TYVideoPlaybackStateStopped -> TYVideoPlaybackStatePlaying : start to play
 * TYVideoPlaybackStatePlaying -> TYVideoPlaybackStateStalled : video play stalled
 * TYVideoPlaybackStateStalled -> TYVideoPlaybackStatePlaying : resume play
 *
 * @param URL           video URL
 * @param oldState      the previous playback state
 * @param newState      the current playback state
 */
- (void)playbackStateDidChangeForURL:(NSURL *)URL oldState:(TYVideoPlaybackState)oldDurationState newState:(TYVideoPlaybackState)newState;

/**
 * @brief AVPlayerItemStatus changed to AVPlayerItemStatusReadyToPlay
 *
 * @param URL       video URL
 */
- (void)preparedToPlayForVideoDuration:(NSTimeInterval)duration URL:(NSURL *)URL;

/**
 * @brief AVPlayerLayer's readyForDisplay changed to YES
 *
 * @param URL       video URL
 */
- (void)readyForDisplayForURL:(NSURL *)URL;

/**
 * @brief Play for @URL failed, with error @error.
 *
 * @param URL       video URL
 * @param error     fail error
 */
- (void)playbackDidFailForURL:(NSURL *)URL error:(NSError *)error;

/**
 * @brief Play for all URLs in @contentURLStringList failed, with error dict @errorDict.
 *
 * @param errorDict     error dict for the URL list
 */
- (void)playbackDidFailWithErrorDict:(NSDictionary<NSURL *, NSError *> *)errorDict;

@end


