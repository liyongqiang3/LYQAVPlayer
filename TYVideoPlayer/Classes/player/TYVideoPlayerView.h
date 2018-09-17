//
//  TYVideoPlayerView.h
//  Masonry
//
//  Created by yongqiang li on 2018/9/14.
//

#import <UIKit/UIKit.h>
#import "TYVideoPlayerDefines.h"
#import <AVFoundation/AVFoundation.h>
#import "TYVideoPlayerEnum.h"

@class TYVideoPlayerManger;


@interface TYVideoPlayerView : UIView
/// player layer
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@property (nonatomic, assign) BOOL initialized;

@property (nonatomic, weak) TYVideoPlayerManger *playerManger;

/**
 * @brief associate the player with player layer
 *
 * @param player        the player to associate
 * @param scaleMode     video scale mode
 * @param rotateType    video rotate type
 */
- (void)setPlayer:(AVPlayer*)player
        scaleMode:(TYVideoScaleMode)scaleMode
       rotateType:(TYVideoRotateType)rotateType;

/**
 * @brief set view rotate type
 *
 * @param rotateType    rotateType
 */
- (void)setRotateType:(TYVideoRotateType)rotateType;

/**
 * @brief set view scale mode
 *
 * @param scalingMode   scalingMode
 */
- (void)setScalingMode:(TYVideoScaleMode)scalingMode;
@end
