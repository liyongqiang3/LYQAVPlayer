//
//  TYVideoConfiguration.h
//  TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/17.
//  Copyright © 2018 yongqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TYVideoPlayer/TYVideoPlayer.h>

#define TYVideoConfiguration_Singleton     [TYVideoConfiguration sharedInstance]

@interface TYVideoConfiguration : NSObject

+ (instancetype)sharedInstance;

/// whether use disk cache or not
@property (nonatomic, assign) BOOL useCache;

/// whether loop play or not
@property (nonatomic, assign) BOOL repeated;

/// whether truncate the tail when audio and video do not end at the same time
@property (nonatomic, assign) BOOL truncateTailWhenRepeated;

/// video scale mode
@property (nonatomic, assign) TYVideoScaleMode scalingMode;

/// rotate video video
@property (nonatomic, assign) TYVideoRotateType rotateType;

/// mute
@property (nonatomic, assign) BOOL muted;

/// the demanded playback rate. default to 1
@property (nonatomic, assign) float playbackRate;

/// ignore audio interruption. e.g. earphone plug
@property (nonatomic, assign) BOOL ignoreAudioInterruption;

///
@property (nonatomic, assign) BOOL mixAudio;

@end
