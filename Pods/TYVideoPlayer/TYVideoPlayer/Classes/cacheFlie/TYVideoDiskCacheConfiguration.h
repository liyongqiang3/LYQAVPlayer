//
//  TYVideoDiskCacheConfiguration.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/14.
//

#import <Foundation/Foundation.h>
#import "TYVideoNetWorkRequestDelegate.h"
#import "TYVideoLogger.h"

#define TY_Reporter                [TYVideoDiskCacheConfiguration sharedInstance].Reporter
#define TY_CDNRequestTrackDelegate        [TYVideoDiskCacheConfiguration sharedInstance].CDNRequestDelegate
#define TY_FileLogEnabled          [TYVideoDiskCacheConfiguration sharedInstance].fileLogEnabled
#define TY_VideoDownloadDelegate   [TYVideoDiskCacheConfiguration sharedInstance].videoDownloadDelegate
#define TY_Logger                  [TYVideoDiskCacheConfiguration sharedInstance].loggerDelegate

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * TYVideoURLStringToCacheKey(NSString *urlString);


@interface TYVideoDiskCacheConfiguration : NSObject

/// the size limit of the disk cache. MB
@property (nonatomic, assign) NSUInteger costLimit;

/// auto trim interval of disk cache. second
@property (nonatomic, assign) NSUInteger autoTrimInterval;

/// whether use file log or not
@property (nonatomic, assign) BOOL fileLogEnabled;

/// map urlString to cache key
/// Note: the cache key should be unique for the same video.
/// If two different urlStrings are mapped to ONE video, one can map them to the same cache key.
/// In this way, the cache hit rate and disk usage efficiency will be improved, and so do the video play performance.
@property (nonatomic, copy) NSString *(^URLStringToCacheKey)(NSString *urlString);

/// report the underlying status
@property (nonatomic, copy) void (^Reporter)(NSString *label, NSString *urlString,  NSString * _Nullable extra);

/// monitor CDN access
@property (nonatomic, weak) id<TYVideoCDNRequestDelegate> CDNRequestDelegate;

/// monitor video download activities
@property (nonatomic, weak) id<TYVideoDownloadDelegate> videoDownloadDelegate;

/// log extension
@property (nonatomic, weak) id<TYVideoPlayerLoggerDelegate> loggerDelegate;

/**
 * @brief singleton
 */
+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END

