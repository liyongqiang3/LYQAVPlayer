//
//  TYVideoCacheRequestTask.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import <Foundation/Foundation.h>

@class TYVideoCacheRequestTask;


@protocol TYVideoCacheRequestTaskDelegate <NSObject>

@required

/**
 * @brief data has been received from network, and sync to disk
 */
- (void)requestTask:(TYVideoCacheRequestTask * _Nullable)task didReceiveData:(NSData * _Nullable)data;

@optional

/**
 * @brief data has been received from network, and NOT sync to disk yet
 */
- (void)requestTask:(TYVideoCacheRequestTask *)task didReceiveWiredData:(NSData *)data;

/**
 * @brief receive a response from network
 */
- (void)requestTask:(TYVideoCacheRequestTask *)task didReceiveResponse:(NSHTTPURLResponse *)response;

/**
 * @brief network request task has finished
 */
- (void)requestTaskDidFinishLoading:(TYVideoCacheRequestTask *)task;

/**
 * @brief network request task has failed
 */
- (void)requestTask:(TYVideoCacheRequestTask *)task didFailWithError:(NSError *)error;


@end


@interface TYVideoCacheRequestTask : NSObject

/// resource URL
@property (nonatomic, strong, readonly) NSURL *requestURL;

/// TYVideoCacheRequestTaskDelegate
@property (nonatomic, weak) id<TYVideoCacheRequestTaskDelegate> delegate;

/// resource length
@property (nonatomic, assign) NSUInteger fileLength;

/// resource mimeType
@property (nonatomic, copy) NSString *mimeType;

/// cached length (into disk) of the resource
@property (nonatomic, assign) NSUInteger cacheLength;

//#if OS_OBJECT_USE_OBJC

@property (nonatomic, readonly) dispatch_queue_t taskQueue;

//#else
//@property (nonatomic, assign) dispatch_queue_t taskQueue;

//#endif




- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/**
 * @brief cancel network requext
 *
 * Attention：should be run on @taskQueue
 */
- (void)cancelNetworkRequest;



// request URL key
@property (nonatomic, copy,readonly) NSString *requestURLKey;

/**
 * @brief initializer
 * Attention: should be run on @queue (taskQueue)
 *
 * @param URL           task URL
 * @param queue         task queue
 */
- (instancetype)initWithURL:(NSURL *)URL queue:(dispatch_queue_t)queue;

/**
 * @brief request data from network at @range.
 *        ONLY the un-cached part will be requested. if all the @range has been cached already, no network request will be made.
 * Attention: should be run on @taskQueue
 *
 * @param range         data range of the request task
 * @param priority      task priority
 */
- (BOOL)startTaskWithRange:(NSRange)range priority:(float)priority;

@end
