//
//  TYVideoDiskCacheDeleteManager.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//
#import "TYVideoDiskCacheManger.h"
#import "NSTimer+BlocksKit.h"
#import "TYVideoDiskCacheDeleteManager.h"
#import "TYVideoPlayerDefines.h"

@interface TYVideoDiskCacheDeleteManager ()

@property (nonatomic, strong) NSMutableSet<NSString *> *shouldDeleteCacheSet;

@property (nonatomic, strong) NSMutableSet<NSString *> *usingCacheSet;

@property (nonatomic, strong) NSTimer *deleteTimer;

@end

@implementation TYVideoDiskCacheDeleteManager

+ (instancetype)sharedInstance
{
    static TYVideoDiskCacheDeleteManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [TYVideoDiskCacheDeleteManager new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.shouldDeleteCacheSet = [NSMutableSet set];
        self.usingCacheSet = [NSMutableSet set];
        //
//        self.deleteTimer = [NSTimer TY_video_scheduledTimerWithTimeInterval:5 repeats:YES block:^(NSTimer *timer) {
//            [TYVideoDiskCacheDeleteManager _deleteCachesSafely];
//        }];
        self.deleteTimer = [NSTimer  bk_timerWithTimeInterval:5 block:^(NSTimer *timer) {
            [TYVideoDiskCacheDeleteManager _deleteCachesSafely];
        } repeats:YES];
    }
    
    return self;
}

- (void)dealloc
{
    if (self.deleteTimer) {
        [self.deleteTimer invalidate];
        self.deleteTimer = nil;
    }
}

#pragma mark - Public

+ (void)startUseCacheForKey:(NSString *)key
{
    if (TYVideo_isEmptyString(key)) {
        return;
    }
    
    TYVideoDiskCacheDeleteManager *instance = [TYVideoDiskCacheDeleteManager sharedInstance];
    @synchronized(instance)
    {
        [instance.usingCacheSet addObject:key];
    }
}

+ (void)endUseCacheForKey:(NSString *)key
{
    if (TYVideo_isEmptyString(key)) {
        return;
    }
    
    TYVideoDiskCacheDeleteManager *instance = [TYVideoDiskCacheDeleteManager sharedInstance];
    @synchronized(instance)
    {
        [instance.usingCacheSet removeObject:key];
    }
}

+ (void)shouldDeleteCacheForKey:(NSString *)key
{
    if (TYVideo_isEmptyString(key)) {
        return;
    }
    
    TYVideoDiskCacheDeleteManager *instance = [TYVideoDiskCacheDeleteManager sharedInstance];
    @synchronized(instance)
    {
        [instance.shouldDeleteCacheSet addObject:key];
    }
}

+ (NSArray<NSString *> *)usingCacheItems
{
    TYVideoDiskCacheDeleteManager *instance = [TYVideoDiskCacheDeleteManager sharedInstance];
    @synchronized(instance)
    {
        return [instance.usingCacheSet allObjects];
    }
}

#pragma mark - Private

+ (void)_deleteCachesSafely
{
    TYVideoDiskCacheDeleteManager *instance = [TYVideoDiskCacheDeleteManager sharedInstance];
    @synchronized(instance)
    {
        if (instance.shouldDeleteCacheSet.count == 0) {
            return;
        }
        
        NSMutableSet<NSString *> *shouldDeleteCacheSet = [instance.shouldDeleteCacheSet mutableCopy];
        [shouldDeleteCacheSet minusSet:instance.usingCacheSet];
        //
        [TYVideoDiskCacheManger clearForKeys:[shouldDeleteCacheSet allObjects]];
        //
        [instance.shouldDeleteCacheSet minusSet:shouldDeleteCacheSet];
    }
}

@end
