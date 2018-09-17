//
//  TYVideoPlayerView.m
//  Masonry
//
//  Created by yongqiang li on 2018/9/14.
//

#import "TYVideoPlayerView.h"
#import "TYVideoPlayerManger.h"

@implementation TYVideoPlayerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.initialized = NO;
    }
    
    return self;
}

- (void)dealloc
{
    [self resetPlayer];
}

#pragma mark - Public

- (void)setPlayer:(AVPlayer*)player
        scaleMode:(TYVideoScaleMode)scaleMode
       rotateType:(TYVideoRotateType)rotateType
{
    [self resetPlayer];
    
    if (!player) {
        return;
    }
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    self.playerLayer.frame = self.bounds;
    [self.layer insertSublayer:self.playerLayer atIndex:0];
    
    [self.playerLayer addObserver:self.playerManger
                       forKeyPath:@"readyForDisplay"
                          options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                          context:KVO_Context_TYVideoPlayerController];
    
    self.initialized = YES;
    
    self.rotateType = rotateType;
    self.scalingMode = scaleMode;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}

- (void)resetPlayer
{
    if (self.playerLayer) {
        TYVideo_RemoveKVOObserverSafely(self.playerLayer, self.playerManger, @"readyForDisplay");
        //
        [self.playerLayer removeFromSuperlayer];
        self.playerLayer = nil;
    }
    
    self.initialized = NO;
}

- (void)setRotateType:(TYVideoRotateType)rotateType
{
    if (self.initialized) {
        CGFloat angle = 0;
        switch (rotateType) {
            case TYVideoRotateType90:
                angle = M_PI_2;
                break;
            case TYVideoRotateType180:
                angle = M_PI;
                break;
            case TYVideoRotateType270:
                angle = M_PI_2 * 3;
                break;
                
            default:
                break;
        }
        
        self.playerLayer.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
        self.playerLayer.frame = self.bounds;
    }
}

- (void)setScalingMode:(TYVideoScaleMode)scalingMode
{
    if (self.initialized) {
        switch (scalingMode) {
            case TYVideoScaleModeAspectFit: {
                self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                
                break;
            }
                
            case TYVideoScaleModeAspectFill: {
                self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                
                break;
            }
                
            case TYVideoScaleModeFill: {
                self.playerLayer.videoGravity = AVLayerVideoGravityResize;
                
                break;
            }
                
            default: {
                self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                
                break;
            }
        }
    }
}

@end
