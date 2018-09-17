//
//  TYVideoPrefetchTaskManager.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import "TYVideoPrefetchTaskManager.h"
#import "TYVideoPlayerDefines.h"
#import "TYVideoPrefetchTask.h"
#import "TYVideoDiskCacheManger.h"

@interface NSMutableArray (TYVideoPrefetch_QueueAdditions)

- (id)dequeue;

- (void)enqueue:(id)obj;

@end

@implementation NSMutableArray (TYVideoPrefetch_QueueAdditions)

- (id)dequeue
{
    if (self.count == 0) {
        return nil;
    }
    
    id headObject = [self objectAtIndex:0];
    if (headObject != nil) {
        [self removeObjectAtIndex:0];
    }
    
    return headObject;
}

- (void)enqueue:(id)object
{
    if (!object) {
        return;
    }
    
    [self addObject:object];
}

@end

@interface TYVideoPrefetchTaskManager () <TYVideoPrefetchTaskDelegate>

// <group, prefetchTask>
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<TYVideoPrefetchTask *> *> *runningTaskDict;

// FIFO queue
@property (nonatomic, strong) NSMutableArray<TYVideoPrefetchTask *> *taskQueue;

#if OS_OBJECT_USE_OBJC
// execute queue for all tasks
@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

#else
@property (nonatomic, assign) dispatch_queue_t dispatchQueue;

#endif

// running prefetch task
@property (nonatomic, strong) TYVideoPrefetchTask *runningTask;

// prefetch option: default is YES
@property (nonatomic, assign) BOOL enablePrefetchWIFIOnly;

@end

@implementation TYVideoPrefetchTaskManager

+ (instancetype)sharedInstance
{
    static TYVideoPrefetchTaskManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TYVideoPrefetchTaskManager alloc] init];
    });
    
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        dispatch_queue_attr_t attr = NULL;
        if (@available(iOS 8.0, *)) {
            attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0);
        }
        self.dispatchQueue = dispatch_queue_create("com.TYVideoPlayer.TYVideoPrefetch", attr);
        _runningTaskDict = [NSMutableDictionary dictionary];
        _taskQueue = [NSMutableArray array];
        _enablePrefetchWIFIOnly = YES;
    }
    
    return self;
}

+ (void)clear
{
    dispatch_async([TYVideoPrefetchTaskManager sharedInstance].dispatchQueue, ^{
        [[TYVideoPrefetchTaskManager sharedInstance] _clear];
    });
}

- (void)_clear
{
    // cancel all running task
    for (NSMutableArray<TYVideoPrefetchTask *> * taskArray in [self.runningTaskDict allValues]) {
        [taskArray enumerateObjectsUsingBlock:^(TYVideoPrefetchTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj cancelPrefetch];
        }];
    }
    
    self.runningTaskDict = [NSMutableDictionary dictionary];
    self.taskQueue = [NSMutableArray array];
    self.runningTask = nil;
}

+ (void)prefetchWithURLString:(NSString *)urlString size:(NSUInteger)size
{
    [self prefetchWithURLString:urlString size:size group:nil];
}

+ (void)prefetchWithURLString:(NSString *)urlString group:(NSString *)group
{
    [self prefetchWithURLString:urlString size:NSUIntegerMax group:group];
}

+ (void)prefetchWithURLString:(NSString *)urlString
{
    [self prefetchWithURLString:urlString size:NSUIntegerMax group:nil];
}

+ (void)prefetchWithURLString:(NSString *)urlString size:(NSUInteger)size group:(NSString *)group
{
    if (TYVideo_isEmptyString(urlString)) {
        return;
    }
    
    group = group ? : @"default";
    [TYVideoDiskCacheManger hasCacheForURLString:urlString completion:^(BOOL hasCache) {
        if (!hasCache) {
            dispatch_async([TYVideoPrefetchTaskManager sharedInstance].dispatchQueue, ^{
                [[TYVideoPrefetchTaskManager sharedInstance] _prefetchWithURLString:urlString size:size group:group];
            });
        }
    }];
}

- (void)_prefetchWithURLString:(NSString * _Nonnull)urlString size:(NSUInteger)size group:(NSString *)group
{
    TYVideoPrefetchTask *task = [TYVideoPrefetchTask taskWithURLString:urlString size:size queue:self.dispatchQueue];
    task.delegate = self;
    
    [self.taskQueue enqueue:task];
    //
    if (!self.runningTaskDict[group]) {
        self.runningTaskDict[group] = [NSMutableArray array];
    }
    [self.runningTaskDict[group] addObject:task];
    
    // 触发prefetch
    [self startPrefetchIfNeeded];
}

+ (void)cancel
{
    [self cancelForGroup:nil];
}

+ (void)cancelForGroup:(NSString *)group
{
    group = group ? : @"default";
    
    dispatch_async([TYVideoPrefetchTaskManager sharedInstance].dispatchQueue, ^{
        [[TYVideoPrefetchTaskManager sharedInstance] _cancelForGroup:group];
    });
}

- (void)_cancelForGroup:(NSString *)group
{
    NSMutableArray<TYVideoPrefetchTask *> *taskArray = self.runningTaskDict[group];
    [taskArray enumerateObjectsUsingBlock:^(TYVideoPrefetchTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cancelPrefetch];
        if (obj == self.runningTask) {
            self.runningTask = nil;
        }
    }];
    
    self.runningTaskDict[group] = [NSMutableArray array];
    
    // trigger prefetch next
    [self startPrefetchIfNeeded];
}

+ (void)cancelForURLString:(NSString *)urlString
{
    dispatch_async([TYVideoPrefetchTaskManager sharedInstance].dispatchQueue, ^{
        [[TYVideoPrefetchTaskManager sharedInstance] _cancelForURLString:urlString];
    });
}

- (void)_cancelForURLString:(NSString *)urlString
{
    [self.taskQueue enumerateObjectsUsingBlock:^(TYVideoPrefetchTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.videoURL.absoluteString isEqualToString:urlString]) {
            [obj cancelPrefetch];
            if (obj == self.runningTask) {
                self.runningTask = nil;
            }
        }
    }];
    
    // trigger prefetch next
    [self startPrefetchIfNeeded];
}

- (void)startPrefetchIfNeeded
{
    dispatch_async(self.dispatchQueue, ^{
        [self _startPrefetchIfNeeded];
    });
}

- (void)_startPrefetchIfNeeded
{
    if (self.runningTask) {
        return;
    }
    
    TYVideoPrefetchTask *task = [self.taskQueue dequeue];
    while (task) {
        if ([task startPrefetch]) {
            self.runningTask = task;
            break;
        }
        
        task =[self.taskQueue dequeue];
    };
}

+ (BOOL)enablePrefetchWIFIOnly
{
    return [TYVideoPrefetchTaskManager sharedInstance].enablePrefetchWIFIOnly;
}

+ (void)setEnablePrefetchWIFIOnly:(BOOL)flag
{
    [TYVideoPrefetchTaskManager sharedInstance].enablePrefetchWIFIOnly = flag;
}

#pragma mark - TYVideoPrefetchTaskDelegate

- (void)requestTaskDidReceiveResponse:(TYVideoPrefetchTask *)task
{
    // do nothing
}

- (void)requestTaskDidReceiveData:(TYVideoPrefetchTask *)task
{
    // do nothing
}

- (void)requestTaskDidFinishLoading:(TYVideoPrefetchTask *)task
{
    dispatch_async(self.dispatchQueue, ^{
        self.runningTask = nil;
        [self freeTask:task];
        
        [self _startPrefetchIfNeeded];
    });
}

- (void)requestTask:(TYVideoPrefetchTask *)task didFailWithError:(NSError *)error
{
    dispatch_async(self.dispatchQueue, ^{
        self.runningTask = nil;
        [self freeTask:task];
        
        [self _startPrefetchIfNeeded];
    });
    
}

- (void)freeTask:(TYVideoPrefetchTask *)task
{
    [self.runningTaskDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<TYVideoPrefetchTask *> * _Nonnull obj, BOOL * _Nonnull stop) {
        NSMutableArray<TYVideoPrefetchTask *> *taskArray = obj;
        [taskArray enumerateObjectsUsingBlock:^(TYVideoPrefetchTask * _Nonnull taskIn, NSUInteger idx, BOOL * _Nonnull stopIn) {
            if (task == taskIn) {
                [taskArray removeObjectAtIndex:idx];
                *stopIn = YES;
                *stop = YES;
            }
        }];
    }];
}


@end
