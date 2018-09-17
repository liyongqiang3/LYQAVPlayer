//
//  YYVideoCachePrefetchTask.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import <Foundation/Foundation.h>
#import "TYVideoCacheRequestTask.h"

@interface TYVideoCachePrefetchTask : TYVideoCacheRequestTask

/**
 * @param URL   URL for loading data. one TYVideoCachePrefetchTask is created for one URL.
 * @param queue the serial queue on which TYVideoCachePrefetchTask is executed.
 */
+ (instancetype)taskWithURL:(NSURL *)URL queue:(dispatch_queue_t)queue;

/**
 * @brief start to prefetch
 *
 * @param size  prefetch range：0 ~ size
 */
- (BOOL)startWithSize:(NSUInteger)size;

@end
