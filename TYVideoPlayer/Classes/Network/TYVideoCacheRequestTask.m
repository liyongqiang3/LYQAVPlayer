//
//  TYVideoCacheRequestTask.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import "TYVideoCacheRequestTask.h"
#import "TYVideoDiskCacheManger.h"
#import "TYVideoPlayerDefines.h"
#import "TYVideoDiskCacheDeleteManager.h"
#import "TYVideoDiskCacheConfiguration.h"

#define TYVideoCacheRequestTimeout         60.0

/// video cache request task state
typedef NS_ENUM(NSInteger, TYVideoCacheRequestTaskState)
{
    /// video cache request task state initialized
    TYVideoCacheRequestTaskStateInitialized = 0,
    /// video cache request task state running
    TYVideoCacheRequestTaskStateRunning,
    /// video cache request task state completed
    TYVideoCacheRequestTaskStateCompleted,
    /// video cache request task state canceled
    TYVideoCacheRequestTaskStateCanceled,
    /// video cache request task state error
    TYVideoCacheRequestTaskStateError,
};

@interface TYVideoCacheRequestTask () <NSURLConnectionDataDelegate, NSURLSessionDataDelegate>

// resource URL
@property (nonatomic, strong) NSURL *requestURL;

// request
@property (nonatomic, strong) NSURLRequest *videoRequest;

// request URL key
@property (nonatomic, copy) NSString *requestURLKey;

// the queue on which TYVideoCacheRequestTask is executed
@property (nonatomic, strong) dispatch_queue_t taskQueue;

// request data range
@property (nonatomic, assign) NSRange requestRange;

// request session
@property (nonatomic, strong) NSURLSession *session;

// running data network task
@property (nonatomic, strong) NSURLSessionDataTask *runningTask;

// state
@property (nonatomic, assign) TYVideoCacheRequestTaskState state;

// offset for mem
@property (nonatomic, assign) NSUInteger memCacheOffset;

// data cache for network data. avoid disk write frequently
@property (nonatomic, strong) NSMutableData *dataCache;

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

@implementation TYVideoCacheRequestTask

/*
 * video download speed profiler
 */

#define TY_REQ_TASK_CACHE_SIZE             100 * 1024
#define TY_REQ_TASK_NETWORK_PROFILER_SIZE  50 * 1024

// time counter
static NSTimeInterval s_dataReceiveStartTime = 0;
// size counter
static NSUInteger s_downloadSize = 0;
// video network request on the fly
static int s_requestCountOnTheFly = 0;

- (instancetype)initWithURL:(NSURL * _Nonnull)URL queue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self) {
        _requestURL = URL;
        _videoRequest = nil;
        self.requestURLKey = TYVideoURLStringToCacheKey(URL.absoluteString);
        self.taskQueue = queue ? : dispatch_get_main_queue();
        
        _session = nil;
        _runningTask = nil;
        _requestRange = NSMakeRange(0, 0);
        
        _fileLength = 0;
        _mimeType = nil;
        _cacheLength = 0;
        _memCacheOffset = 0;
        
        _state = TYVideoCacheRequestTaskStateInitialized;
        
        _dataCache = [NSMutableData dataWithCapacity:TY_REQ_TASK_CACHE_SIZE];
    }
    
    return self;
}

- (NSOperationQueue *)sessionQueue
{
    return [NSOperationQueue mainQueue];
}


#pragma mark - Public

- (BOOL)startTaskWithRange:(NSRange)range priority:(float)priority
{
    if (self.state != TYVideoCacheRequestTaskStateInitialized) {
        return NO;
    }
    
    if (   range.location + range.length <= self.cacheLength
        || (range.length == NSUIntegerMax && self.cacheLength == self.fileLength && self.fileLength != 0)) {
        //        TY_VIDEO_INFO(@"%@ startTaskWithRange skipped: self = %p, requestedRange = ((%@, %@)) fileLength = %@, cacheLength = %@",
        //                       self.requestURLKey, self,
        //                       @(range.location), @(range.length),
        //                       @(self.fileLength), @(self.cacheLength));
        return NO;
    }
    
    self.memCacheOffset = self.cacheLength;
    
    // ensure @range is continuous
    if (range.length != NSUIntegerMax) {
        range.length = range.location + range.length - self.cacheLength;
    }
    range.location = self.cacheLength;
    
    self.requestRange = range;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:configuration
                                                 delegate:self
                                            delegateQueue:self.sessionQueue];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.requestURL
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:TYVideoCacheRequestTimeout];
    if (range.length != NSUIntegerMax) {
        [request addValue:[NSString stringWithFormat:@"bytes=%lu-%lu", (unsigned long)range.location, (unsigned long)(range.location + range.length - 1)] forHTTPHeaderField:@"Range"];
    } else {
        [request addValue:[NSString stringWithFormat:@"bytes=%lu-", (unsigned long)range.location] forHTTPHeaderField:@"Range"];
    }
    
    self.runningTask = [self.session dataTaskWithRequest:request];
    if (@available(iOS 8.0, *)) {
        self.runningTask.priority = priority;
    }
    
    [self.runningTask resume];
    
    dispatch_async(self.taskQueue, ^{
        if (TY_CDNRequestTrackDelegate) {
            [TY_CDNRequestTrackDelegate videoWillRequest:request isRedirectRequest:NO];
        }
        self.videoRequest = request;
    });
    
    self.state = TYVideoCacheRequestTaskStateRunning;
//
//    TY_VIDEO_INFO(@"%@ startTaskWithRange: self = %p, range = (%@, %@)",
//                   self.requestURLKey, self,
//                   @(self.requestRange.location), @(self.requestRange.length));
    
    return YES;
}

- (void)cancelNetworkRequest
{
    //    TY_VIDEO_DEBUG(@"%@ cancelNetworkRequest: self = %p", self.requestURLKey, self);
    
    if (self.state != TYVideoCacheRequestTaskStateRunning) {
        return;
    }
    //
    [self.runningTask cancel];
    self.runningTask = nil;
    //
    [self.session invalidateAndCancel];
    self.session = nil;
    
    self.state = TYVideoCacheRequestTaskStateCanceled;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    if (TY_VideoDownloadDelegate) {
        if (s_requestCountOnTheFly == 0) {
            s_dataReceiveStartTime = [[NSDate date] timeIntervalSince1970];
            s_downloadSize = 0;
        }
        ++s_requestCountOnTheFly;
    }
    
    dispatch_async(self.taskQueue, ^{
        [self __URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    });
}

- (void)__URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
//    TY_VIDEO_DEBUG(@"%@ response: self = %p, %@", self.requestURLKey, self, response);
    
    if (self.state != TYVideoCacheRequestTaskStateRunning) {
        return;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    dispatch_async(self.taskQueue, ^{
        if (TY_CDNRequestTrackDelegate) {
            [TY_CDNRequestTrackDelegate videoDidReceiveResponse:httpResponse forRequest:self.videoRequest];
        }
    });
    
    // network error
    if (httpResponse.statusCode < 200 || httpResponse.statusCode >= 400) {
        //        TY_VIDEO_ERROR(@"%@ bad response: self = %p, %@", self.requestURLKey, self, response);
        
        NSError *error = TYError(TYVideoPlayerErrorURLResponse,
                                  [NSString stringWithFormat:@"{status:%@, reason:%@}",
                                   @(httpResponse.statusCode),
                                   [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode]]
                                  );
        
        [self __URLSession:session task:dataTask didCompleteWithError:error];
        
        if (TY_Reporter) {
            NSString *extra = [NSString stringWithFormat:@"%@", error];
                        TY_Reporter(TYReporterLabel_ServerError, self.requestURL.absoluteString, extra);
        }
        
        completionHandler(NSURLSessionResponseCancel);
        
        return;
    }
    
    // inconsistent
    NSString *contentRange = httpResponse.allHeaderFields[@"Content-Range"];
    NSInteger contentRangeLength = [[[contentRange componentsSeparatedByString:@"/"] lastObject] integerValue];
    if (self.fileLength != 0 && self.fileLength != contentRangeLength) {
        //        TY_VIDEO_ERROR(@"%@ bad length: self = %p, prevFileLength=%@, incomingFileLength=%@",
        //                        self.requestURLKey, self,
        //                        @(self.fileLength), @(contentRangeLength));
        
        NSError *error = TYError(TYVideoPlayerErrorInconsistentPlaySource,
                                  [NSString stringWithFormat:@"{prevFileLength:%@, incomingFileLength:%@}",
                                   @(self.fileLength), @(contentRangeLength)]
                                  );
        [self __URLSession:session task:dataTask didCompleteWithError:error];
        
        if (TY_Reporter) {
            NSString *extra = [NSString stringWithFormat:@"prevFileLength=%@, incomingFileLength=%@",
                               @(self.fileLength),
                               @(contentRangeLength)];
                        TY_Reporter(TYReporterLabel_CacheDataCorrupted, self.requestURL.absoluteString, extra);
        }
        
        completionHandler(NSURLSessionResponseCancel);
        
        return;
    }
    
    self.fileLength = contentRangeLength;
    self.mimeType = response.MIMEType;
    
    completionHandler(NSURLSessionResponseAllow);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(requestTask:didReceiveResponse:)]) {
        [self.delegate requestTask:self didReceiveResponse:httpResponse];
    }
}

- (void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task willPerformHTTPRedirection:(nonnull NSHTTPURLResponse *)response newRequest:(nonnull NSURLRequest *)request completionHandler:(nonnull void (^)(NSURLRequest * _Nullable))completionHandler
{
    if (TY_VideoDownloadDelegate) {
        if (s_requestCountOnTheFly == 1) {
            s_dataReceiveStartTime = [[NSDate date] timeIntervalSince1970];
            s_downloadSize = 0;
        }
    }
    
    dispatch_async(self.taskQueue, ^{
        if (TY_CDNRequestTrackDelegate) {
            [TY_CDNRequestTrackDelegate videoDidReceiveResponse:response forRequest:self.videoRequest];
            [TY_CDNRequestTrackDelegate videoWillRequest:request isRedirectRequest:YES];
        }
        self.videoRequest = request;
    });
    
    !completionHandler ?: completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if (TY_VideoDownloadDelegate) {
        s_downloadSize += data.length;
        if (s_downloadSize >= TY_REQ_TASK_NETWORK_PROFILER_SIZE) {
            [self _doVideoDownloadDelegate];
        }
    }
    
    dispatch_async(self.taskQueue, ^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(requestTask:didReceiveWiredData:)]) {
            [self.delegate requestTask:self didReceiveWiredData:data];
        }
        
        [self __URLSession:session dataTask:dataTask didReceiveData:data];
    });
}


- (void)__URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    //    TY_VIDEO_TRACE(@"%@ data: self = %p, %@", self.requestURLKey, self, @(data.length));
    
    if (self.state != TYVideoCacheRequestTaskStateRunning) {
        return;
    }
    
    [self.dataCache appendData:data];
    
    if (self.dataCache.length >= TY_REQ_TASK_CACHE_SIZE) {
        [self syncDataWithURLSession:session dataTask:dataTask completion:nil];
    }
    
}

- (void)syncDataWithURLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask completion:(void(^)(NSError *))completion
{
    NSUInteger dataLength = self.dataCache.length;
    
    NSData *dataCache = self.dataCache;
    [TYVideoDiskCacheManger appendCacheData:self.dataCache
                                offset:self.memCacheOffset
                                forKey:self.requestURLKey
                              mimeType:self.mimeType
                            fileLength:self.fileLength
                            completion:^(NSError *error) {
                                dispatch_async(self.taskQueue, ^{
                                    if (!error) {
                                        self.cacheLength += dataLength;
                                        //
                                        if (self.delegate && [self.delegate respondsToSelector:@selector(requestTask:didReceiveData:)]) {
                                            [self.delegate requestTask:self didReceiveData:dataCache];
                                        }
                                    } else {
                                        [self URLSession:session task:dataTask didCompleteWithError:error];
                                        //
                                        if (TY_Reporter) {
                                            ////                                            TY_Reporter(TYReporterLabel_WriteFileFail,
                                            //                                                         self.requestURL.absoluteString,
                                            //                                                         [NSString stringWithFormat:@"%@", error]);
                                        }
                                    }
                                    
                                    !completion ? : completion(error);
                                });
                            }];
    
    self.memCacheOffset += dataLength;
    //
    self.dataCache = [NSMutableData dataWithCapacity:TY_REQ_TASK_CACHE_SIZE];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (TY_VideoDownloadDelegate) {
        --s_requestCountOnTheFly;
        if (s_requestCountOnTheFly == 0 && s_downloadSize != 0 && !error) {
            [self _doVideoDownloadDelegate];
        }
    }
    
    dispatch_async(self.taskQueue, ^{
        [self __URLSession:session task:task didCompleteWithError:error];
    });
}

- (void)__URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    @onExit{
        self.runningTask = nil;
        //
        [self.session invalidateAndCancel];
        self.session = nil;
    };
    
    if (self.state != TYVideoCacheRequestTaskStateRunning) {
        return;
    }
    
    if (error) {
        // ignore network cancel case
        if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
            return;
        }
        
        //        TY_VIDEO_INFO(@"%@ didCompleteWithError: self = %p, error = %@",
        //                       self.requestURLKey, self,
        //                       error);
        
        [TYVideoDiskCacheDeleteManager shouldDeleteCacheForKey:self.requestURLKey];
        
        // delegate
        dispatch_async([TYVideoDiskCacheManger cacheQueue], ^{
            dispatch_async(self.taskQueue, ^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(requestTask:didFailWithError:)]) {
                    [self.delegate requestTask:self didFailWithError:error];
                }
            });
        });
        
        
        self.state = TYVideoCacheRequestTaskStateError;
        
    } else {
        //        TY_VIDEO_INFO(@"%@ didComplete: self = %p", self.requestURLKey, self);
        
        if (self.dataCache.length > 0) {
            [self syncDataWithURLSession:session dataTask:(NSURLSessionDataTask *)task completion:^(NSError *error) {
                if (!error) {
                    //                    TY_VIDEO_INFO(@"%@ didCompleteToDisk: self = %p, cacheLength = %@, fileLength = %@",
                    //                                   self.requestURLKey, self,
                    //                                   @(self.cacheLength), @(self.fileLength));
                }
            }];
        }
        
        // delegate
        dispatch_async([TYVideoDiskCacheManger cacheQueue], ^{
            dispatch_async(self.taskQueue, ^{
                if(self.delegate && [self.delegate respondsToSelector:@selector(requestTaskDidFinishLoading:)]) {
                    [self.delegate requestTaskDidFinishLoading:self];
                }
            });
        });
        
        self.state = TYVideoCacheRequestTaskStateCompleted;
    }
}

static const double kTYVideoNetworkSpeedMax = 102400;   // 100MB/s
static const double kTYVideoNetworkSpeedMin = 10;       // 10 KB/s

- (void)_doVideoDownloadDelegate
{
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    //
    NSTimeInterval duration = currentTime - s_dataReceiveStartTime;
    NSUInteger length = s_downloadSize;
    
    double speed = length / duration / 1024;
    if (kTYVideoNetworkSpeedMin <= speed && speed <= kTYVideoNetworkSpeedMax ) {
        dispatch_async(self.taskQueue, ^{
            [TY_VideoDownloadDelegate videoDidDownloadDataLength:length interval:duration];
        });
    }
    //
    s_dataReceiveStartTime = currentTime;
    s_downloadSize = 0;
}


@end
