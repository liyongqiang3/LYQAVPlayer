//
//  TYVideoPrefetchHitRecorder.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import "TYVideoPrefetchHitRecorder.h"
#import "TYVideoObjectPool.h"
#import "TYVideoPlayerDefines.h"

@interface TYVideoPrefetchHitStatus : NSObject

@property (nonatomic, assign) NSUInteger size;
// cache life time
@property (nonatomic, assign) NSUInteger lifeTime;

@end

@implementation TYVideoPrefetchHitStatus

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.size = 0;
        self.lifeTime = 0;
    }
    
    return self;
}

@end

@interface TYVideoPrefetchHitRecorder ()

// statuc dict
@property (nonatomic, strong) NSMutableDictionary<NSString *, TYVideoPrefetchHitStatus *> *statusDict;

// status pool
@property (nonatomic, strong) TYVideoObjectPool<TYVideoPrefetchHitStatus *> *statusPool;

- (void)startPrefetchWithKey:(NSString *)key;

- (void)prefetchingWithKey:(NSString *)key size:(NSUInteger)size;

- (void)startPlayWithKey:(NSString *)key;

@end


@implementation TYVideoPrefetchHitRecorder

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.lifeTimeMax = 5;
        //
        self.statusDict = [NSMutableDictionary dictionary];
        self.statusPool = [[TYVideoObjectPool alloc] initWithClass:[TYVideoPrefetchHitStatus class] maxCount:100];
    }
    
    return self;
}

+ (instancetype)sharedInstance
{
    static TYVideoPrefetchHitRecorder *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [TYVideoPrefetchHitRecorder new];
    });
    
    return instance;
}

#pragma mark - Record

- (void)startPrefetchWithKey:(NSString *)key
{
    if (TYVideo_isEmptyString(key) || !self.delegate) {
        return;
    }
    
    @synchronized(self)
    {
        TYVideoPrefetchHitStatus *status = nil;
        
        if ([self.statusDict objectForKey:key]) {
            status = [self.statusDict objectForKey:key];
        } else {
            status = [self.statusPool getObject];
            [self.statusDict setObject:status forKey:key];
        }
        
        status.size = 0;
        status.lifeTime = 0;
    }
}

- (void)prefetchingWithKey:(NSString *)key size:(NSUInteger)size
{
    if (TYVideo_isEmptyString(key) || !self.delegate) {
        return;
    }
    
    @synchronized(self)
    {
        if ([self.statusDict objectForKey:key]) {
            TYVideoPrefetchHitStatus *status = [self.statusDict objectForKey:key];
            //
            status.size += size;
        }
    }
}

- (void)startPlayWithKey:(NSString *)playKey
{
    if (TYVideo_isEmptyString(playKey) || !self.delegate) {
        return;
    }
    
    @synchronized(self)
    {
        NSMutableArray<NSString *> *deleteKeyArray = [NSMutableArray array];
        //
        [self.statusDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, TYVideoPrefetchHitStatus * _Nonnull obj, BOOL * _Nonnull stop) {
            if ([playKey isEqualToString:key]) {
                [self.delegate videoPrefetch:key didHitWithSize:obj.size];
                [deleteKeyArray addObject:key];
                //
//                TY_VIDEO_INFO(@"prefetch did hit, size=%@", @(obj.size));
            } else {
                if (obj.lifeTime < self.lifeTimeMax) {
                    ++obj.lifeTime;
                } else {
                    [self.delegate videoPrefetch:key didMissWithSize:obj.size];
                    [deleteKeyArray addObject:key];
                    //
                    //                    TY_VIDEO_INFO(@"prefetch did miss, size=%@", @(obj.size));
                }
            }
        }];
        
        [deleteKeyArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.statusPool returnObject:self.statusDict[obj]];
        }];
        
        [self.statusDict removeObjectsForKeys:deleteKeyArray];
    }
}

@end
