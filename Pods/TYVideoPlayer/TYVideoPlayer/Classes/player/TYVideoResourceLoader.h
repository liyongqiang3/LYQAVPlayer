//
//  TYVideoResourceLoader.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/14.
//

#import <Foundation/Foundation.h>
#import "TYVideoPlayerManageDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "TYVideoPlayerNetworkDelegate.h"

@class TYVideoResourceLoader;

@protocol TYVideoResourceLoaderDelegate <NSObject>

@optional

/**
 * @brief update network cache progress
 *
 * @param loader    the TYVideoResourceLoader instance
 * @param progress  the loading progress
 */
- (void)loader:(TYVideoResourceLoader *)loader cacheProgress:(CGFloat)progress;

@end


NS_ASSUME_NONNULL_BEGIN

@interface TYVideoResourceLoader : NSObject<AVAssetResourceLoaderDelegate>

/// TYVideoResourceLoaderDelegate
@property (nonatomic, weak) id<TYVideoResourceLoaderDelegate> delegate;

/// error
@property (nonatomic, strong) NSError *error;

/**
 * @brief create an instance.
 *
 * @param URL               URL for loading data. one TYVideoResourceLoader is created for one URL.
 * @param queue             the serial queue on which TYVideoResourceLoader is executed.
 * @param internalDelegate  report internal events
 */
+ (instancetype)resourceLoaderWithURL:(NSURL *)URL
                                queue:(dispatch_queue_t)queue
                     internalDelegate:(id<TYVideoPlayerNetworkDelegate> _Nullable)internalDelegate;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
 * @brief get cache length asynchronously
 *
 * @param completion        block to execute with cache size
 */
- (void)getCacheLengthWithCompletion:(void(^)(long long))completion;

/**
 * @brief stop loading
 */
- (void)stopLoading;

@end
NS_ASSUME_NONNULL_END
