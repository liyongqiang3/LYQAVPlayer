//
//  TYVideoResourceDeallocManager.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import "TYVideoResourceDeallocManager.h"
#import "NSTimer+BlocksKit.h"
#import "TYVideoPlayerDefines.h"

@implementation TYVideoResourceDeallocManager

+ (instancetype)sharedInstance
{
    static TYVideoResourceDeallocManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TYVideoResourceDeallocManager alloc] init];
    });
    
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.resourcesToDealloc = [NSMutableArray arrayWithCapacity:100];
        self.shouldStartTrimmer = NO;
        
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define TY_RESOURCE_CACHE_COUNT    15
//        BOOL shouldCleanUpTimely = SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0");
//        if (shouldCleanUpTimely) {
//            __weak typeof(self) weakSelf = self;
//            self.timer = [NSTimer TY_video_scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer *timer) {
//                dispatch_async_on_main_queue(^{
//                    __strong typeof(weakSelf) strongSelf = weakSelf;
//                    if (strongSelf.resourcesToDealloc.count > TY_RESOURCE_CACHE_COUNT) {
//                        strongSelf.shouldStartTrimmer = YES;
//                    }
//                    if (strongSelf.shouldStartTrimmer && strongSelf.resourcesToDealloc.count > 0) {
//                        [strongSelf.resourcesToDealloc removeLastObject];
//                        //                        TY_VIDEO_TRACE(@"deallocated a resource, remaining %@", @(strongSelf.resourcesToDealloc.count));
//
//                        if (strongSelf.resourcesToDealloc.count == 0) {
//                            strongSelf.shouldStartTrimmer = NO;
//                        }
//                    }
//                });
//            }];
//        }
    }
    
    return self;
}

- (void)dealloc
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)addResourceObject:(id)obj
{
    dispatch_async_on_main_queue(^{
        if (obj) {
            [self.resourcesToDealloc addObject:obj];
            //            TY_VIDEO_TRACE(@"enqueue a resource, remaining %@", @(self.resourcesToDealloc.count));
        }
    });
}

@end
