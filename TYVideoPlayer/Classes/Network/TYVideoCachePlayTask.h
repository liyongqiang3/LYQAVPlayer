//
//  TYVideoCachePlayTask.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import <Foundation/Foundation.h>
#import "TYVideoPlayerNetworkDelegate.h"
#import "TYVideoCacheRequestTask.h"
#import "TYVideoDiskCacheConfiguration.h"
#import "TYVideoPlayerDefines.h"


NS_ASSUME_NONNULL_BEGIN

@interface TYVideoCachePlayTask : TYVideoCacheRequestTask

+ (instancetype)taskWithURL:(NSURL *)URL
                      queue:(dispatch_queue_t)queue
           internalDelegate:(id<TYVideoPlayerNetworkDelegate> _Nullable)internalDelegate;

/**
 * @brief read cache data from disk
 * Attention：@subdataWithRange: should be run on @taskQueue
 *
 * @param range     data range
 * @param error     error if any
 */
- (NSData * _Nullable)subdataWithRange:(NSRange)range error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
