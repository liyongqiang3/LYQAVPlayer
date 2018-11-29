//
//  TYVideoPrefetchTask.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import <Foundation/Foundation.h>
#import "TYVideoCachePrefetchTask.h"
#import "TYVideoCacheRequestTask.h"

NS_ASSUME_NONNULL_BEGIN

@class TYVideoPrefetchTask;

@protocol TYVideoPrefetchTaskDelegate <NSObject>

/**
 * @brief receive a response from network
 *
 * @param task      the prefetch task
 */
- (void)requestTaskDidReceiveResponse:(TYVideoPrefetchTask *)task;

/**
 * @brief data has been received from network, and sync to disk
 *
 * @param task      the prefetch task
 */
- (void)requestTaskDidReceiveData:(TYVideoPrefetchTask *)task;

/**
 * @brief network request task has finished
 *
 * @param task      the prefetch task
 */
- (void)requestTaskDidFinishLoading:(TYVideoPrefetchTask *)task;

/**
 * @brief network request task has failed
 *
 * @param task      the prefetch task
 * @param error     fail error
 */
- (void)requestTask:(TYVideoPrefetchTask *)task didFailWithError:(NSError *)error;

@end

//////////////////////////////////////////////////////////////////////////////////////////////

/// prefetch task state
typedef NS_ENUM(NSInteger, TYVideoPrefetchTaskState)
{
    /// prefetch task state unknown
    TYVideoPrefetchTaskStateUnknown = 0,
    /// prefetch task state initialized
    TYVideoPrefetchTaskStateInitialized,
    /// prefetch task state running
    TYVideoPrefetchTaskStateRunning,
    /// prefetch task state finished
    TYVideoPrefetchTaskStateFinished,
    /// prefetch task state finished error
    TYVideoPrefetchTaskStateFinishedError,
    /// prefetch task state canceled
    TYVideoPrefetchTaskStateCanceled,
};

@interface TYVideoPrefetchTask : NSObject<TYVideoCacheRequestTaskDelegate>



/// data request task
@property (nonatomic, strong) TYVideoCachePrefetchTask *requestTask;

/// request URL
@property (nonatomic, strong) NSURL *videoURL;

/// request URL KEY
@property (nonatomic, copy) NSString *videoURLKey;

/// prefetch size
@property (nonatomic, assign) NSUInteger prefetchSize;

/// prefetch state
@property (nonatomic, assign) TYVideoPrefetchTaskState state;

/// TYVideoPrefetchTaskDelegate
@property (nonatomic, weak) id<TYVideoPrefetchTaskDelegate> delegate;

/// for performance monitoring
@property (nonatomic, assign) NSTimeInterval prefetchBeginTime;

/**
 * @brief create a video prefetch task
 *
 * @param urlString     request URL
 * @param size          request range：0 ~ size
 * @param queue         the queue on which TYVideoPrefetchTask is executed
 */
+ (instancetype)taskWithURLString:(NSString *)urlString size:(NSUInteger)size queue:(dispatch_queue_t)queue;

/**
 * @brief start prefetch
 */
- (BOOL)startPrefetch;

/**
 * @brief cancel prefetch
 */
- (void)cancelPrefetch;

@end
NS_ASSUME_NONNULL_END
