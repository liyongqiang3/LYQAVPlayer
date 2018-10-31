//
//  TYVideoResourceLoader.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/14.
//

#import "TYVideoResourceLoader.h"
#import "TYVideoDiskCacheManger.h"
#import "TYVideoCachePlayTask.h"
#import "TYVideoPlayerDefines.h"
#import "TYVideoDiskCacheConfiguration.h"
#import "TYURLTransformer.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "TYVideoCacheRequestDelegate.h"

@interface  TYVideoResourceLoader() <TYVideoCacheRequestDelegate>

// request URL
@property (nonatomic, strong) NSURL *requestURL;

// request URL key
@property (nonatomic, copy) NSString *requestURLKey;

// AVAssetResourceLoaderDelegate的loadingRequest sent by AVPlayer
@property (nonatomic, strong) NSMutableArray<AVAssetResourceLoadingRequest *> *requestList;

// play request task
@property (nonatomic, strong) TYVideoCachePlayTask *playTask;

// TYVideoResourceLoader's queue
@property (nonatomic, strong) dispatch_queue_t taskQueue;

// stopped by player controller
@property (nonatomic, assign) BOOL stopped;

// internal delegate
@property (nonatomic, weak) id<TYVideoPlayerNetworkDelegate> internalDelegate;

@end


@implementation TYVideoResourceLoader


+ (instancetype)resourceLoaderWithURL:(NSURL *)URL
                                queue:(dispatch_queue_t)queue
                     internalDelegate:(id<TYVideoPlayerNetworkDelegate> _Nullable)internalDelegate
{
    TYVideoResourceLoader *instance = [[TYVideoResourceLoader alloc] initWithURL:URL queue:queue internalDelegate:internalDelegate];
    
//    TY_VIDEO_DEBUG(@"%@ new TYVideoResourceLoader: self = %p", instance.requestURLKey, instance);
    
    return instance;
}

- (instancetype)initWithURL:(NSURL *)URL
                      queue:(dispatch_queue_t)queue
           internalDelegate:(id<TYVideoPlayerNetworkDelegate> _Nullable)internalDelegate
{
    self = [super init];
    if (self) {
//        NSLog(@" TYVideoResourceLoader initWithURL url = %@ ",URL.absoluteString);
        self.requestList = [NSMutableArray array];
        self.requestURL = URL;
        self.requestURLKey = TYVideoURLStringToCacheKey(URL.absoluteString);
        self.taskQueue = queue;
        self.stopped = NO;
        self.internalDelegate = internalDelegate;
        //
        self.playTask = [TYVideoCachePlayTask taskWithURL:URL queue:queue internalDelegate:internalDelegate];
        self.playTask.delegate = self;
    }
    return self;
    
}

- (void)getCacheLengthWithCompletion:(void(^)(long long))completion
{
    dispatch_async(self.taskQueue, ^{
        long long length = self.playTask.cacheLength;
        if (completion) {
            completion(length);
        }
    });
}


- (void)stopLoading
{
//    TY_VIDEO_DEBUG(@"%@ stopLoading: self = %p", self.requestURLKey, self);
    self.stopped = YES;
    
    dispatch_async(self.taskQueue, ^{
        [self.playTask cancelNetworkRequest];
    });
}

- (NSString *)dataRequestDescription:(AVAssetResourceLoadingDataRequest *)dataRequest
{
    return [NSString stringWithFormat:@"{ url:%@, offset:%@, currentOffset:%@, length:%@ }",
            self.requestURLKey,
            @(dataRequest.requestedOffset),
            @(dataRequest.currentOffset),
            @(dataRequest.requestedLength)];
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    //    TY_VIDEO_INFO(@"%@ new loadingRequest: self = %p, stopped = %@, error = %@, cacheLength = %@, %@",
    //                   self.requestURLKey,
    //                   self,
    //                   @(self.stopped),
    //                   self.error,
    //                   @(self.playTask.cacheLength),
    //                   [self dataRequestDescription:loadingRequest.dataRequest]);
    
    if (self.error) {
        return NO;
    } else {
        [self addLoadingRequest:loadingRequest];
        return YES;
    }
}

- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self removeLoadingRequest:loadingRequest];
}

#pragma mark - TYVideoCacheRequestTaskDelegate

- (void)requestTask:(TYVideoCacheRequestTask *)task didReceiveData:(NSData *)data
{
    // process cached loading request whenever new data is received
    [self processRequestList];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(loader:cacheProgress:)]) {
        CGFloat cacheProgress = (CGFloat)self.playTask.cacheLength / self.playTask.fileLength;
        [self.delegate loader:self cacheProgress:cacheProgress];
    }
}

- (void)requestTaskDidFinishLoading:(TYVideoCacheRequestTask *)task
{
    [TYVideoDiskCacheManger finishCacheForKey:self.requestURLKey originURLString:self.requestURL.absoluteString completion:^(NSError *error, NSString *extra) {
        if (error) {
            dispatch_async(self.taskQueue, ^{
                [self requestTask:task didFailWithError:error];
                //
                if (TY_Reporter) {
                    //                    TY_Reporter(TYReporterLabel_CacheDataCorrupted, self.requestURL.absoluteString, extra);
                }
            });
        } else {
            if (self.internalDelegate && [self.internalDelegate respondsToSelector:@selector(didFinishVideoDataDownloadForURL:)]) {
                dispatch_async_on_main_queue(^{
                    [self.internalDelegate didFinishVideoDataDownloadForURL:self.requestURL];
                });
            }
        }
    }];
}

- (void)requestTask:(TYVideoCacheRequestTask *)task didFailWithError:(NSError *)error
{
    self.error = error;
    
    if (!self.stopped) {
        [self.requestList enumerateObjectsUsingBlock:^(AVAssetResourceLoadingRequest * _Nonnull loadingRequest, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!loadingRequest.isFinished && !loadingRequest.isCancelled) {
                [loadingRequest finishLoadingWithError:error];
            }
        }];
    }
    
    self.requestList = [NSMutableArray array];
}

#pragma mark - 处理LoadingRequest

- (void)addLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    [self.requestList addObject:loadingRequest];
    
    if ([self requestedDataCached:loadingRequest]) {
        [self processRequestList];
    }
}

- (void)removeLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    if ([self.requestList containsObject:loadingRequest]) {
        [self.requestList removeObject:loadingRequest];
    }
}

- (BOOL)requestedDataCached:(AVAssetResourceLoadingRequest *)loadingRequest
{
    long long requestedOffset = loadingRequest.dataRequest.requestedOffset;
    long long requestedLength = loadingRequest.dataRequest.requestedLength;
    if (requestedOffset + requestedLength > self.playTask.cacheLength) {
        return NO;
    }
    
    return YES;
}

- (void)processRequestList
{
    if (self.stopped) {
        self.requestList = [NSMutableArray array];
        return;
    }
    
    // clear loading requests which are finished or cancelled
    NSMutableArray *finishedRequestList = [NSMutableArray array];
    [self.requestList enumerateObjectsUsingBlock:^(AVAssetResourceLoadingRequest * _Nonnull loadingRequest, NSUInteger idx, BOOL * _Nonnull stop) {
        if (loadingRequest.isFinished || loadingRequest.isCancelled) {
            [finishedRequestList addObject:loadingRequest];
        }
    }];
    [self.requestList removeObjectsInArray:finishedRequestList];
    
    [self.requestList enumerateObjectsUsingBlock:^(AVAssetResourceLoadingRequest * _Nonnull loadingRequest, NSUInteger idx, BOOL * _Nonnull stop) {
        [self finishLoadingWithLoadingRequest:loadingRequest];
    }];
}

- (void)finishLoadingWithLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{
    // information
    CFStringRef contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)(self.playTask.mimeType), NULL);
    loadingRequest.contentInformationRequest.contentType = CFBridgingRelease(contentType);
    loadingRequest.contentInformationRequest.byteRangeAccessSupported = YES;
    loadingRequest.contentInformationRequest.contentLength = self.playTask.fileLength;
    
    // data range
    long long requestedOffset = 0;
    long long requestedLength = 0;
    if (loadingRequest.dataRequest.currentOffset != 0) {
        requestedOffset = loadingRequest.dataRequest.currentOffset;
        requestedLength = loadingRequest.dataRequest.requestedLength + loadingRequest.dataRequest.requestedOffset - loadingRequest.dataRequest.currentOffset;
    } else {
        requestedOffset = loadingRequest.dataRequest.requestedOffset;
        requestedLength = loadingRequest.dataRequest.requestedLength;
    }
    
    // read cache，fill data
    BOOL haveValidData = requestedOffset + MIN(10240, requestedLength) <= self.playTask.cacheLength;
    if (haveValidData) {
        NSError *error = nil;
        NSData *subdata = [self.playTask subdataWithRange:NSMakeRange((NSUInteger)requestedOffset, (NSUInteger)requestedLength) error:&error];
        if (!subdata || subdata.length == 0 || error) {
            if (TY_Reporter) {
                //                TY_Reporter(TYReporterLabel_ReadFileFail, self.requestURL.absoluteString, [NSString stringWithFormat:@"%@", error]);
            }
            return;
        }
        //
        if (!self.stopped && !loadingRequest.isFinished && !loadingRequest.isCancelled) {
            [loadingRequest.dataRequest respondWithData:subdata];
        }
        
        long long requestOffsetNext = requestedOffset + subdata.length;
        long long requestOffsetEnd = loadingRequest.dataRequest.requestedOffset + loadingRequest.dataRequest.requestedLength;
        if (requestOffsetNext >= requestOffsetEnd) {
            //            TY_VIDEO_INFO(@"%@ loadingRequest finished: self = %p, %@",
            //                           self.requestURLKey,
            //                           self,
            //                           [self dataRequestDescription:loadingRequest.dataRequest]);
            //
            if (!self.stopped && !loadingRequest.isFinished && !loadingRequest.isCancelled) {
                [loadingRequest finishLoading];
            }
        }
    }
}

@end
