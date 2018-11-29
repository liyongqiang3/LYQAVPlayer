//
//  TYVideoPlayerEnum.h
//  Pods
//
//  Created by yongqiang li on 2018/9/14.
//

#ifndef TYVideoPlayerEnum_h
#define TYVideoPlayerEnum_h

/// video scale mode
typedef NS_ENUM(NSInteger, TYVideoScaleMode)
{
    /// video scale mode aspect fit
    TYVideoScaleModeAspectFit = 0,
    /// video scale mode aspect fill
    TYVideoScaleModeAspectFill,
    /// video scale mode fill
    TYVideoScaleModeFill,
};

/// video player state
typedef NS_ENUM(NSInteger, TYVideoPlayerState)
{
    /// video player state initialized
    TYVideoPlayerStateInitialized = 0,
    /// video player state prepared
    TYVideoPlayerStatePrepared,
    /// video player state play
    TYVideoPlayerStatePlay,
    /// video player state pause
    TYVideoPlayerStatePause,
    /// video player state stop
    TYVideoPlayerStateStop,
    /// video player state completed
    TYVideoPlayerStateCompleted,
    /// video player state error
    TYVideoPlayerStateError,
};

/// video playback state
typedef NS_ENUM(NSInteger, TYVideoPlaybackState)
{
    /// video playback state playing. not paused, stalled, stopped, error.
    TYVideoPlaybackStatePlaying = 0,
    /// video playback state stalled.
    TYVideoPlaybackStateStalled,
    /// video playback state stopped.
    TYVideoPlaybackStateStopped,
};

/// video frame rotate type
typedef NS_ENUM(NSInteger, TYVideoRotateType)
{
    /// video frame rotate none
    TYVideoRotateTypeNone = 0,
    /// video frame rotate clockwise 90 degrees
    TYVideoRotateType90,
    /// video frame rotate clockwise 180 degrees
    TYVideoRotateType180,
    /// video frame rotate clockwise 270 degrees
    TYVideoRotateType270,
};

#endif /* TYVideoPlayerEnum_h */
