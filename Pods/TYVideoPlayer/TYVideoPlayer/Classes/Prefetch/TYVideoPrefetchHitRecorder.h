//
//  TYVideoPrefetchHitRecorder.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import <Foundation/Foundation.h>

@protocol TYVideoPrefetchHitDelegate

/**
 * @brief prefetch did hit for video play
 *
 * @param urlString     video url string
 * @param size          prefetch size
 */
- (void)videoPrefetch:(NSString *)urlString didHitWithSize:(NSUInteger)size;

/**
 * @brief prefetch did miss for video play
 *
 * @param urlString     video url string
 * @param size          prefetch size
 */
- (void)videoPrefetch:(NSString *)urlString didMissWithSize:(NSUInteger)size;

@end


@interface TYVideoPrefetchHitRecorder : NSObject

@property (nonatomic, weak) id<TYVideoPrefetchHitDelegate> delegate;

/// the max life time for prefetched video
@property (nonatomic, assign) NSUInteger lifeTimeMax;

/**
 * @brief singleton
 */
+ (instancetype)sharedInstance;

@end
