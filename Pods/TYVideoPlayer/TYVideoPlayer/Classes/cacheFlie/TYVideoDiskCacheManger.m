//
//  TYVideoDiskCacheManger.m
//  Masonry
//
//  Created by yongqiang li on 2018/9/14.
//

#import "TYVideoDiskCacheManger.h"

#import "TYVideoDiskCacheFileHandle.h"
#import "NSTimer+BlocksKit.h"
#import "TYVideoDiskCacheDeleteManager.h"
#import "TYVideoCacheRequestDelegate.h"
#import "TYVideoDiskCacheProtocol.h"
#import "TYVideoPlayerDefines.h"
#import "TYVideoDiskCacheConfiguration.h"

@interface TYVideoDiskCacheManger () <TYVideoDiskCacheProtocol>

// the implementation
@property (nonatomic, strong) Class<TYVideoDiskCacheProtocol> cacheClass;

// timer for clear disk cache periodically
@property (nonatomic, strong) NSTimer * _Nullable timer;

/**
 * @brief singleton
 */
+ (instancetype)sharedInstance;

@end

@implementation TYVideoDiskCacheManger

#pragma mark - Life Cycle

+ (instancetype)sharedInstance
{
    static TYVideoDiskCacheManger *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [TYVideoDiskCacheManger new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cacheClass = [TYVideoDiskCacheFileHandle class];
        //
        [self setupTrimTimer];
        //
        [self _addNotificationObservers];
    }
    
    return self;
}

- (void)setupTrimTimer
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    TYVideoDiskCacheConfiguration *config = [TYVideoDiskCacheConfiguration sharedInstance];

    self.timer = [NSTimer bk_timerWithTimeInterval:config.autoTrimInterval block:^(NSTimer *timer) {
         [TYVideoDiskCacheManger trimDiskCacheToQuota];
    } repeats:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

-(void)_addNotificationObservers
{
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [TYVideoDiskCacheManger trimDiskCacheToQuota];
    }];
}

#pragma mark - Public

+ (NSString *)cachePath
{
    static NSString *cachePath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        cachePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"TYVideoCache"];
    });
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    return cachePath;
}

+ (long long )sizeAtFilePath:(NSString *)filePath
{
    long long size = 0;
    BOOL isDirectory = NO;
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (fileExist && !isDirectory) {
        size = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL] fileSize];
    }
    
    return size;
}

+ (dispatch_queue_t)cacheQueue
{
    static dispatch_queue_t cacheQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cacheQueue = dispatch_queue_create("com.TYVideoPlayer.TYVideoDiskCache", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return cacheQueue;
}

#define CACHE_CLASS     [TYVideoDiskCacheManger sharedInstance].cacheClass

+ (void)hasCacheForURLString:(NSString * _Nonnull)urlString
                  completion:(void(^ _Nonnull)(BOOL))block
{
    [CACHE_CLASS hasCacheForKey:TYVideoURLStringToCacheKey(urlString)
                     completion:block];
}

+ (void)getCacheInfoForURLString:(NSString *)urlString
                      completion:(void(^)(BOOL hasCache, BOOL isComplete, NSString *cachePath, NSInteger fileSize))block
{
    [CACHE_CLASS getCacheInfoForKey:TYVideoURLStringToCacheKey(urlString)
                         completion:block];
}

+ (void)clearForURLString:(NSString * _Nonnull)urlString
{
    [TYVideoDiskCacheDeleteManager shouldDeleteCacheForKey:TYVideoURLStringToCacheKey(urlString)];
}

+ (void)trimDiskCacheToQuota
{
    [self trimDiskCacheToSize:[TYVideoDiskCacheConfiguration sharedInstance].costLimit * 1024 * 1024];
}

+ (BOOL)hasEnoughFreeDiskSize
{
    BOOL enough = [self freeFileSystemSize] > 20;
    if (!enough) {
        [self clear];
    }
    
    return enough;
}

+ (BOOL)hasEnoughCacheForURLString:(NSString *)urlString
                     videoDuration:(CGFloat)duration
                      networkSpeed:(CGFloat)networkSpeed
{
    __block BOOL result = NO;
    
    NSString *key = TYVideoURLStringToCacheKey(urlString);
    [self metaDataForKeySync:key completion:^(NSError * _Nullable error, NSString * _Nullable mimeType, NSUInteger fileLength, NSUInteger cacheLength) {
        if (!error) {
            NSUInteger speed = networkSpeed * 1024;
            if (speed == 0 || fileLength == 0 || cacheLength == 0) {
                return;
            }
            // ms
            NSUInteger downloadTime = (fileLength - cacheLength) * 1000 / (speed * 0.75);
            NSUInteger canPlayTime = cacheLength * duration * 1000 / fileLength;
            
            result = downloadTime <= canPlayTime;
        }
    }];
    
    return result;
}

+ (uint64_t)freeFileSystemSize
{
    NSDictionary *dict = [[NSFileManager defaultManager]
                          attributesOfFileSystemForPath:[self cachePath]
                          error:NULL];
    if (dict) {
        NSNumber *freeFileSystemSizeInBytes = [dict objectForKey:NSFileSystemFreeSize];
        return [freeFileSystemSizeInBytes unsignedLongLongValue] / 1024 / 1024;
    }
    
    return 0;
}

#pragma mark - Public - TYVideoDiskCacheProtocol

+ (void)appendCacheData:(NSData *)data
                 offset:(NSUInteger)offset
                 forKey:(NSString *)key
               mimeType:(NSString *)mimeType
             fileLength:(NSUInteger)fileLength
             completion:(void(^)(NSError *error))block
{
    [CACHE_CLASS appendCacheData:data
                          offset:(NSUInteger)offset
                          forKey:key
                        mimeType:mimeType
                      fileLength:fileLength
                      completion:block];
}

+ (void)finishCacheForKey:(NSString *)key
          originURLString:(NSString *)urlString
               completion:(void(^)(NSError *error, NSString *extra))block
{
    [CACHE_CLASS finishCacheForKey:key
                   originURLString:urlString
                        completion:block];
}

+ (void)cacheDataForKey:(NSString *)key
                 offset:(NSUInteger)offset
                 length:(NSUInteger)length
             completion:(void(^)(NSError *error, NSData* data))block
{
    [CACHE_CLASS cacheDataForKey:key
                          offset:offset
                          length:length
                      completion:block];
}

+ (void)cacheDataForKeySync:(NSString *)key
                     offset:(NSUInteger)offset
                     length:(NSUInteger)length
                 completion:(void(^)(NSError * _Nullable error, NSData* _Nullable data))block
{
    [CACHE_CLASS cacheDataForKeySync:key
                              offset:offset
                              length:length
                          completion:block];
}

+ (void)metaDataForKey:(NSString *)key
            completion:(void(^)(NSError * _Nullable error, NSString * _Nullable mimeType, NSUInteger fileLength, NSUInteger cacheLength))block
{
    [CACHE_CLASS metaDataForKey:key
                     completion:block];
}

+ (void)metaDataForKeySync:(NSString *)key
                completion:(void(^)(NSError * _Nullable error, NSString * _Nullable mimeType, NSUInteger fileLength, NSUInteger cacheLength))block
{
    [CACHE_CLASS metaDataForKeySync:key
                         completion:block];
}

+ (void)hasCacheForKey:(NSString *)key
            completion:(void(^)(BOOL))block
{
    [CACHE_CLASS hasCacheForKey:key
                     completion:block];
}

+ (void)getCacheInfoForKey:(NSString *)key
                completion:(void(^)(BOOL hasCache, BOOL isComplete, NSString *cachePath, NSInteger fileSize))block
{
    [CACHE_CLASS getCacheInfoForKey:key
                         completion:block];
}

+ (void)sizeWithCompletion:(void(^ _Nonnull)(NSInteger))block
{
    [CACHE_CLASS sizeWithCompletion:block];
}

+ (void)clear
{
    [CACHE_CLASS clear];
}

+ (void)clearForKeys:(NSArray<NSString *> *)keys
{
    [CACHE_CLASS clearForKeys:keys];
}

+ (void)trimDiskCacheToSize:(NSUInteger)size
{
    [CACHE_CLASS trimDiskCacheToSize:size];
}

@end
