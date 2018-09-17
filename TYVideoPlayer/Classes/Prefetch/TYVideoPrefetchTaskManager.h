//
//  TYVideoPrefetchTaskManager.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import <Foundation/Foundation.h>

@interface TYVideoPrefetchTaskManager : NSObject

+ (void)prefetchWithURLString:(NSString *)urlString size:(NSUInteger)size group:(NSString * _Nullable)group;


+ (void)prefetchWithURLString:(NSString *)urlString size:(NSUInteger)size;

+ (void)prefetchWithURLString:(NSString *)urlString group:(NSString *)group;

+ (void)prefetchWithURLString:(NSString *)urlString;

/**
 * @brief cancel all pending tasks in @group
 *
 * @param group     task group
 */
+ (void)cancelForGroup:(NSString * _Nullable)group;

/**
 * @brief cancel task for @urlString
 *
 * @param urlString TYVideoPrefetchTask's urlString
 */
+ (void)cancelForURLString:(NSString *)urlString;

/**
 * @brief cancel all pending tasks in default group
 */
+ (void)cancel;

/**
 * @brief clear all pending tasks
 */
+ (void)clear;


/**
 @brief get prefetch option
 @return prefetch option
 */
+ (BOOL)enablePrefetchWIFIOnly;

/**
 @brief set prefetch option
 @param flag
 */
+ (void)setEnablePrefetchWIFIOnly:(BOOL)flag;

@end
