//
//  TYVideoPrefetchTask.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import "TYVideoPrefetchTask.h"
#import "TYVideoPrefetchTaskManager.h"
#import "TYVideoDiskCacheDeleteManager.h"
#import "TYVideoDiskCacheManger.h"
#import "TYVideoPlayerDefines.h"
#import "TYVideoPrefetchHitRecorder.h"
#import "TYVideoDiskCacheConfiguration.h"

#import <pthread.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface TYVideoPrefetchHitRecorder ()

- (void)startPrefetchWithKey:(NSString *)key;

- (void)prefetchingWithKey:(NSString *)key size:(NSUInteger)size;

- (void)startPlayWithKey:(NSString *)key;

@end


/// network reachability status
typedef NS_ENUM(NSInteger, TYReachabilityStatus) {
    /// network reachability status unknown
    TYReachabilityStatusUnknown          = -1,
    /// network reachability status Not Reachable
    TYReachabilityStatusNotReachable     = 0,
    /// network reachability status WWAN
    TYReachabilityStatusReachableViaWWAN = 1,
    /// network reachability status WIFI
    TYReachabilityStatusReachableViaWiFi = 2,
};

static TYReachabilityStatus s_reachabilityStatusForFlags(SCNetworkReachabilityFlags flags)
{
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));
    
    TYReachabilityStatus status = TYReachabilityStatusUnknown;
    if (isNetworkReachable == NO) {
        status = TYReachabilityStatusNotReachable;
    }
#if    TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = TYReachabilityStatusReachableViaWWAN;
    }
#endif
    else {
        status = TYReachabilityStatusReachableViaWiFi;
    }
    
    return status;
}

static BOOL s_isNetworkWifiConnected()
{
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    
    BOOL isWifiConnected = NO;
    if (SCNetworkReachabilityGetFlags(reachability, &flags)) {
        isWifiConnected = s_reachabilityStatusForFlags(flags) == TYReachabilityStatusReachableViaWiFi;
    }
    CFRelease(reachability);
    return isWifiConnected;
}


@implementation TYVideoPrefetchTask

- (instancetype)init
{
    self = [super init];
    if (self) {
        _prefetchSize = NSUIntegerMax;
        _state = TYVideoPrefetchTaskStateUnknown;
    }
    
    return self;
}


+ (instancetype)taskWithURLString:(NSString *)urlString size:(NSUInteger)size queue:(dispatch_queue_t)queue
{
    TYVideoPrefetchTask *prefetchTask = [[TYVideoPrefetchTask alloc] init];
    [prefetchTask taskWithURLString:urlString size:size queue:queue];
    
    return prefetchTask;
}

- (instancetype)taskWithURLString:(NSString *)urlString size:(NSUInteger)size queue:(dispatch_queue_t)queue
{
    self.prefetchSize = size;
    self.videoURL = [NSURL URLWithString:urlString];
    self.videoURLKey = TYVideoURLStringToCacheKey(urlString);
    
    self.requestTask = [TYVideoCachePrefetchTask taskWithURL:self.videoURL queue:queue];
    self.requestTask.delegate = self;
    
    self.state = TYVideoPrefetchTaskStateInitialized;
    
    return self;
}

- (BOOL)startPrefetch
{
    if (self.state != TYVideoPrefetchTaskStateInitialized) {
        return NO;
    }
    
    if ( (!s_isNetworkWifiConnected() && [TYVideoPrefetchTaskManager enablePrefetchWIFIOnly] == YES) || !self.videoURL || ![TYVideoDiskCacheManger hasEnoughFreeDiskSize]) {
        return NO;
    }
    
    //    TY_VIDEO_INFO(@"%@ startPrefetch", self.videoURLKey);
    BOOL succeed = [self.requestTask startWithSize:self.prefetchSize];
    if (!succeed) {
        return NO;
    }
    
    self.state = TYVideoPrefetchTaskStateRunning;
    
    [TYVideoDiskCacheDeleteManager startUseCacheForKey:self.videoURLKey];
    
    self.prefetchBeginTime = [[NSDate date] timeIntervalSince1970];
    
    return YES;
}

- (void)cancelPrefetch
{
    if (self.state == TYVideoPrefetchTaskStateRunning) {
        //        TY_VIDEO_INFO(@"%@ cancelPrefetch", self.videoURLKey);
        [self.requestTask cancelNetworkRequest];
    }
    
    if (   self.state != TYVideoPrefetchTaskStateFinished
        && self.state != TYVideoPrefetchTaskStateFinishedError) {
        self.state = TYVideoPrefetchTaskStateCanceled;
    }
    
    [TYVideoDiskCacheDeleteManager endUseCacheForKey:self.videoURLKey];
}

#pragma mark - TYVideoCacheRequestTaskDelegate

- (void)requestTask:(TYVideoCacheRequestTask *)task didReceiveData:(NSData *)data
{
    if (self.delegate) {
        [self.delegate requestTaskDidReceiveData:self];
    }
}

- (void)requestTask:(TYVideoCacheRequestTask *)task didReceiveWiredData:(NSData *)data
{
    [[TYVideoPrefetchHitRecorder sharedInstance] prefetchingWithKey:task.requestURL.absoluteString size:data.length];
}

- (void)requestTask:(TYVideoCacheRequestTask *)task didReceiveResponse:(NSHTTPURLResponse *)response
{
    if (self.delegate) {
        [self.delegate requestTaskDidReceiveResponse:self];
    }
    
    [[TYVideoPrefetchHitRecorder sharedInstance] startPrefetchWithKey:task.requestURL.absoluteString];
}

- (void)requestTaskDidFinishLoading:(TYVideoCacheRequestTask *)task
{
//    TY_VIDEO_INFO(@"%@ finishPrefetch: %@ byte, %.0f ms",
//                   self.videoURLKey,
//                   @(self.requestTask.cacheLength),
//                   ([[NSDate date] timeIntervalSince1970] - self.prefetchBeginTime) * 1000);
    
    self.state = TYVideoPrefetchTaskStateFinished;
    
    [TYVideoDiskCacheDeleteManager endUseCacheForKey:self.videoURLKey];
    
    if (self.delegate) {
        [self.delegate requestTaskDidFinishLoading:self];
    }
}

- (void)requestTask:(TYVideoCacheRequestTask *)task didFailWithError:(NSError *)error
{
    //    TY_VIDEO_ERROR(@"%@ finishErrorPrefetch: error = %@", self.videoURLKey, error);
    
    self.state = TYVideoPrefetchTaskStateFinishedError;
    
    [TYVideoDiskCacheDeleteManager endUseCacheForKey:self.videoURLKey];
    
    if (self.delegate) {
        [self.delegate requestTask:self didFailWithError:error];
    }
}


@end
