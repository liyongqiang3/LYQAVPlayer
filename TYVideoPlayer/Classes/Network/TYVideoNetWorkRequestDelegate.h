//
//  TYVideoNetWorkRequestDelegate.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import <Foundation/Foundation.h>

/**
 * CDN access monitoring
 */
@protocol TYVideoCDNRequestDelegate <NSObject>

/**
 * @brief a CDN request is made
 *
 * @param req                   the network request
 * @param isRedirectRequest     whether it is a 302 request or not
 */
- (void)videoWillRequest:(NSURLRequest *)req isRedirectRequest:(BOOL)isRedirectRequest;

/**
 * @brief receive CDN response
 *
 * @param req                   the network request
 * @param res                   the network response
 */
- (void)videoDidReceiveResponse:(NSHTTPURLResponse *)res forRequest:(NSURLRequest *)req;

@end

/**
 * video data download monitoring
 */
@protocol TYVideoDownloadDelegate <NSObject>

/**
 * @brief has received @length amount of data during @interval seconds.
 *
 * @param length    download size. Byte
 * @param interval  time. second
 */
- (void)videoDidDownloadDataLength:(NSUInteger)length interval:(NSTimeInterval)interval;

@end
