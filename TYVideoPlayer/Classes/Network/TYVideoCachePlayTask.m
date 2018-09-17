//
//  TYVideoCachePlayTask.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import "TYVideoCachePlayTask.h"
#import "TYVideoCacheRequestTask.h"
#import "TYVideoPlayerNetworkDelegate.h"
#import "TYVideoDiskCacheManger.h"

@interface TYVideoCacheRequestTask ()


@end

@interface TYVideoCachePlayTask ()

@property (nonatomic, weak) id<TYVideoPlayerNetworkDelegate> internalDelegate;

@end

@implementation TYVideoCachePlayTask

+ (instancetype)taskWithURL:(NSURL *)URL
                      queue:(dispatch_queue_t)queue
           internalDelegate:(id<TYVideoPlayerNetworkDelegate> _Nullable)internalDelegate
{
    TYVideoCachePlayTask *task = [[TYVideoCachePlayTask alloc] initWithURL:URL queue:queue internalDelegate:internalDelegate];
//    TY_VIDEO_INFO(@"new TYVideoCachePlayTask: %p", task);
    return  task;
    
}

- (instancetype)initWithURL:(NSURL *)URL
                      queue:(dispatch_queue_t)queue
           internalDelegate:(id<TYVideoPlayerNetworkDelegate> _Nullable)internalDelegate
{
    self = [super initWithURL:URL queue:queue];
    if (self) {
        self.internalDelegate = internalDelegate;
        //
        [TYVideoDiskCacheManger metaDataForKey:self.requestURLKey completion:^(NSError * _Nullable error, NSString * _Nullable mimeType, NSUInteger fileLength, NSUInteger cacheLength) {
            if (!error) {
                self.mimeType = mimeType;
                self.fileLength = fileLength;
                self.cacheLength = cacheLength;
//                NSLog(@"url=%@  requestURLKey=%@",self.requestURL.absoluteString,self.requestURLKey);
                ////                TY_VIDEO_INFO(@"%@ metaDataForKey completion: mimeType = %@, fileLength = %@, cacheLength = %@",
                //                               self.requestURLKey,
                //                               mimeType,
                //                               @(fileLength),
                //                               @(cacheLength));
                
                if (self.internalDelegate && [self.internalDelegate respondsToSelector:@selector(didReceiveMetaForURL:mimeType:cacheSize:fileSize:)]) {
                    dispatch_async_on_main_queue(^{
                        [self.internalDelegate didReceiveMetaForURL:URL mimeType:mimeType cacheSize:cacheLength fileSize:fileLength];
                    });
                }
                
                dispatch_async(self.taskQueue, ^{
                    if (self.delegate && [self.delegate respondsToSelector:@selector(requestTask:didReceiveData:)]) {
                        [self.delegate requestTask:nil didReceiveData:nil];
                    }
                });
            } else {
                if (self.internalDelegate && [self.internalDelegate respondsToSelector:@selector(failToRetrieveMetaForURL:error:)]) {
                    dispatch_async_on_main_queue(^{
                        [self.internalDelegate failToRetrieveMetaForURL:URL error:error];
                    });
                }
            }
            
            dispatch_async(self.taskQueue, ^{
                float priority = 0.5;
                if (@available(iOS 8.0, *)) {
                    priority = NSURLSessionTaskPriorityDefault;
                }
                
                BOOL succeed = [self startTaskWithRange:NSMakeRange(0, NSUIntegerMax) priority:priority];
                if (   !succeed
                    && self.internalDelegate
                    && [self.internalDelegate respondsToSelector:@selector(noVideoDataToDownloadForURL:)]) {
                    dispatch_async_on_main_queue(^{
                        NSLog(@"url=startTaskWithRange=============");
                        
                        [self.internalDelegate noVideoDataToDownloadForURL:URL];
                    });
                }
                
//                [[TYVideoPrefetchHitRecorder sharedInstance] startPlayWithKey:URL.absoluteString];
            });
        }];
    }
    
    return self;
}


- (NSData *)subdataWithRange:(NSRange)range error:(NSError * __autoreleasing *)outError
{
    
    __block NSData *cacheData = nil;
    [TYVideoDiskCacheManger cacheDataForKeySync:self.requestURLKey offset:range.location length:range.length completion:^(NSError * _Nullable error, NSData * _Nullable data) {
        cacheData = data;
        if (outError) {
            *outError = error;
        }
    }];
    
    return cacheData;
}

@end
