//
//  TYVideoDiskCacheFileHandle.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/14.
//

#import "TYVideoDiskCacheFileHandle.h"
#import "TYVideoDiskCacheManger.h"
#import "TYVideoPlayerDefines.h"
#import "TYVideoDiskCacheDeleteManager.h"

@interface TYVideoCacheMetaData : NSObject <NSCoding>

// videl file length
@property (nonatomic, assign) NSUInteger fileLength;

// video mimeType
@property (nonatomic, copy) NSString *mimeType;

@end

@implementation TYVideoCacheMetaData

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fileLength = 0;
        _mimeType = nil;
    }
    
    return self;
}

#pragma mark - NSCoding Delegate

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeInteger:self.fileLength forKey:@"fileLength"];
    [encoder encodeObject:self.mimeType forKey:@"mimeType"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.fileLength = [decoder decodeIntegerForKey:@"fileLength"];
        self.mimeType = [decoder decodeObjectForKey:@"mimeType"];
    }
    
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"fileLength = %@, mimeType = %@", @(self.fileLength), self.mimeType];
}

@end

#define FILE_MANAGER [NSFileManager defaultManager]

@interface TYVideoDiskCacheFileHandle ()

// meta data for all disk cache
@property (nonatomic, strong) NSMutableDictionary<NSString *, TYVideoCacheMetaData *> *metaData;

@end


@implementation TYVideoDiskCacheFileHandle

#pragma mark - Life Cycle

+ (instancetype)sharedInstance
{
    static TYVideoDiskCacheFileHandle *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [TYVideoDiskCacheFileHandle new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _metaData = [NSMutableDictionary dictionary];
        
        [self _initializeMetaData];
    }
    
    return self;
}

- (void)_initializeMetaData
{
    BOOL isDirectory = NO;
    BOOL fileExist = [FILE_MANAGER fileExistsAtPath:[TYVideoDiskCacheFileHandle metaPath] isDirectory:&isDirectory];
    if (fileExist && isDirectory) {
        //        TY_VIDEO_ERROR(@"initializeMetaData error: is directory");
     
        [self _clearCacheOnceForAll];
    } else if (fileExist) {
        NSDictionary *dict = nil;
        @try {
            dict = [NSKeyedUnarchiver unarchiveObjectWithFile:[TYVideoDiskCacheFileHandle metaPath]];
        } @catch (NSException *exception) {
            //            TY_VIDEO_ERROR(@"initializeMetaData error: %@", exception);
//            if (TY_Reporter) {
                //                TY_Reporter(TYReporterLabel_MetaDataCorrupted, [NSString stringWithFormat:@"%@", exception], nil);
//            }
            [self _clearCacheOnceForAll];
        } @finally {
            if (dict && [dict isKindOfClass:NSDictionary.class]) {
                _metaData = [dict mutableCopy];
            }
        }
    } else {
        // do nothing
    }
}

#pragma mark - TYVideoDiskCacheProtocol

#define SINGLETON   [TYVideoDiskCacheFile sharedInstance]

+ (void)appendCacheData:(NSData *)data
                 offset:(NSUInteger)offset
                 forKey:(NSString *)key
               mimeType:(NSString *)mimeType
             fileLength:(NSUInteger)fileLength
             completion:(void(^)(NSError *error))block
{
    dispatch_barrier_async([TYVideoDiskCacheManger cacheQueue], ^{
        [[TYVideoDiskCacheFileHandle sharedInstance] _appendCacheData:data
                             offset:offset
                             forKey:key
                           mimeType:mimeType
                         fileLength:fileLength
                         completion:block];
    });
}

- (void)_appendCacheData:(NSData *)data
                  offset:(NSUInteger)offset
                  forKey:(NSString *)key
                mimeType:(NSString *)mimeType
              fileLength:(NSUInteger)fileLength
              completion:(void(^)(NSError *error))block
{
    if (!block) {
        return;
    }
    
    if (TYVideo_isEmptyString(key)) {
        //        TY_VIDEO_ERROR(@"%@ appendCacheData error: Append cache data with empty key", key);
        block(TYError(TYVideoCacheErrorEmptyKey, @"Append cache data with empty key"));
        return;
    }
    
    if (!(self.metaData[key])) {
        TYVideoCacheMetaData *metaData = [TYVideoCacheMetaData new];
        metaData.fileLength = fileLength;
        metaData.mimeType = mimeType;
        self.metaData[key] = metaData;
        //
        [self _syncMetaData];
    }
    
    NSString *filePath = [TYVideoDiskCacheFileHandle dataPathWithKey:key];
    if (![FILE_MANAGER fileExistsAtPath:filePath]) {
        if (![FILE_MANAGER createFileAtPath:filePath contents:nil attributes:nil]) {
            //            TY_VIDEO_ERROR(@"%@ appendCacheData error: Create new file failed", key);
            block(TYError(TYVideoCacheErrorCreateFileFailed, @"Create new file failed"));
            return;
        } else {
            //            TY_VIDEO_DEBUG(@"%@: create file succeed", key);
        }
    }
    
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!handle) {
        //        TY_VIDEO_ERROR(@"%@ appendCacheData error: Write fileHandle nil", key);
        block(TYError(TYVideoCacheErrorWriteFileHandleNil, @"Write fileHandle nil"));
        return;
    }
    
    @try {
        [handle seekToFileOffset:offset];
        [handle writeData:data];
    } @catch (NSException *exception) {
        //        TY_VIDEO_ERROR(@"%@ appendCacheData error: %@", key, exception);
        block(TYError(TYVideoCacheErrorWriteFileFailed, [NSString stringWithFormat:@"%@", exception]));
        return;
    }
    
    block(nil);
}

+ (void)finishCacheForKey:(NSString *)key
          originURLString:(NSString *)urlString
               completion:(void(^)(NSError *error, NSString *extra))block
{
    dispatch_barrier_async([TYVideoDiskCacheManger cacheQueue], ^{
        [[TYVideoDiskCacheFileHandle sharedInstance] _finishCacheForKey:key originURLString:urlString completion:block];
    });
}

- (void)_finishCacheForKey:(NSString *)key
           originURLString:(NSString *)urlString
                completion:(void(^)(NSError *error, NSString *extra))block
{
    if (!block) {
        return;
    }
    
    if (TYVideo_isEmptyString(key)) {
        //        TY_VIDEO_ERROR(@"%@ finishCache error: Finish cache data with empty key", key);
        block(TYError(TYVideoCacheErrorEmptyKey, @"Finish cache data with empty key"), @"empty key");
        return;
    }
    
    // the consistency check of file size
    NSString *filePath = [TYVideoDiskCacheFileHandle dataPathWithKey:key];
    long long cacheLength = [self _fileSizeAtPath:filePath];
    TYVideoCacheMetaData *metaData = self.metaData[key];
    if (cacheLength == 0 || metaData.fileLength == 0 || metaData.fileLength != cacheLength) {
        //        TY_VIDEO_ERROR(@"%@ finishCache error: File size not consistent", key);
        [TYVideoDiskCacheDeleteManager shouldDeleteCacheForKey:key];
        //
        block(TYError(TYVideoCacheErrorCheckFailed, @"File size not consistent"), @"finish check fail");
    } else {
        block(nil, nil);
    }
}

+ (void)cacheDataForKey:(NSString *)key
                 offset:(NSUInteger)offset
                 length:(NSUInteger)length
             completion:(void(^)(NSError * _Nullable error, NSData* _Nullable data))block
{
    dispatch_async([TYVideoDiskCacheManger cacheQueue], ^{
        [[TYVideoDiskCacheFileHandle sharedInstance] _cacheDataForKey:key offset:offset length:length completion:block];
    });
}

- (void)_cacheDataForKey:(NSString *)key
                  offset:(NSUInteger)offset
                  length:(NSUInteger)length
              completion:(void(^)(NSError * _Nullable error, NSData* _Nullable data))block
{
    if (!block) {
        return;
    }
    
    if (TYVideo_isEmptyString(key)) {
        //        TY_VIDEO_ERROR(@"%@ getCacheData error: Retrieve cache data with empty key", key);
        block(TYError(TYVideoCacheErrorEmptyKey, @"Retrieve cache data with empty key"), nil);
        return;
    }
    
    NSString *filePath = [TYVideoDiskCacheFileHandle dataPathWithKey:key];
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (!handle) {
        //        TY_VIDEO_ERROR(@"%@ getCacheData error: Read fileHandle nil", key);
        block(TYError(TYVideoCacheErrorReadFileHandleNil, @"Read fileHandle nil"), nil);
        return;
    }
    
    NSData *data = nil;
    @try {
        [handle seekToFileOffset:offset];
        data = [handle readDataOfLength:length];
    } @catch (NSException *exception) {
        //        TY_VIDEO_ERROR(@"%@ getCacheData error: %@", key, exception);
        block(TYError(TYVideoCacheErrorReadFileFailed, [NSString stringWithFormat:@"%@", exception]), nil);
        return;
    }
    
    if (block) {
        block(nil, data);
    }
}

+ (void)cacheDataForKeySync:(NSString *)key
                     offset:(NSUInteger)offset
                     length:(NSUInteger)length
                 completion:(void(^)(NSError * _Nullable error, NSData* _Nullable data))block
{
    [[TYVideoDiskCacheFileHandle sharedInstance] _cacheDataForKey:key offset:offset length:length completion:block];
}

+ (void)metaDataForKey:(NSString *)key
            completion:(void(^)(NSError * _Nullable error, NSString * _Nullable mimeType, NSUInteger fileLength, NSUInteger cacheLength))block
{
    dispatch_async([TYVideoDiskCacheManger cacheQueue], ^{
        [[TYVideoDiskCacheFileHandle sharedInstance] _metaDataForKey:key completion:block];
    });
}

+ (void)metaDataForKeySync:(NSString *)key
                completion:(void(^)(NSError * _Nullable error, NSString * _Nullable mimeType, NSUInteger fileLength, NSUInteger cacheLength))block
{
    [[TYVideoDiskCacheFileHandle sharedInstance] _metaDataForKey:key completion:block];
}

- (void)_metaDataForKey:(NSString *)key
             completion:(void(^)(NSError * _Nullable error, NSString * _Nullable mimeType, NSUInteger fileLength, NSUInteger cacheLength))block
{
    if (!block) {
        return;
    }
    
    if (TYVideo_isEmptyString(key)) {
//        TY_VIDEO_ERROR(@"%@ getMetaData error: Retrieve meta data with empty key", key);
        block(TYError(TYVideoCacheErrorEmptyKey, @"Retrieve meta data with empty key"), nil, 0, 0);
        return;
    }
    
    NSString *filePath = [TYVideoDiskCacheFileHandle dataPathWithKey:key];
    if (![FILE_MANAGER fileExistsAtPath:filePath]) {
//        TY_VIDEO_DEBUG(@"%@ getMetaData error: Data File not exist", key);
        block(TYError(TYVideoCacheErrorDataFileNotExist, @"Data File not exist"), nil, 0, 0);
        return;
    }
    
    if (!(self.metaData[key])) {
//        TY_VIDEO_DEBUG(@"%@ getMetaData error: Meta data not found", key);
        block(TYError(TYVideoCacheErrorMetaNotFound, @"Meta data not found"), nil, 0, 0);
        return;
    }
    
    long long cacheLength = [self _fileSizeAtPath:filePath];
    block(nil, self.metaData[key].mimeType, self.metaData[key].fileLength, (NSUInteger)cacheLength);
}

+ (void)hasCacheForKey:(NSString *)key
            completion:(void(^)(BOOL))block
{
    dispatch_async([TYVideoDiskCacheManger cacheQueue], ^{
        [[TYVideoDiskCacheFileHandle sharedInstance] _hasCacheForKey:key completion:block];
    });
}

- (void)_hasCacheForKey:(NSString *)key
             completion:(void(^)(BOOL))block
{
    if (!block) {
        return;
    }
    
    if (TYVideo_isEmptyString(key)) {
        block(NO);
        return;
    }
    
    NSString *filePath = [TYVideoDiskCacheFileHandle dataPathWithKey:key];
    BOOL hasCache = [FILE_MANAGER fileExistsAtPath:filePath];
    //
    dispatch_async_on_main_queue(^{
        block(hasCache);
    });
}

+ (void)getCacheInfoForKey:(NSString *)key
                completion:(void(^)(BOOL hasCache, BOOL isComplete, NSString *cachePath, NSInteger fileSize))block
{
    dispatch_async([TYVideoDiskCacheManger cacheQueue], ^{
        [[TYVideoDiskCacheFileHandle sharedInstance] _getCacheInfoForKey:key completion:block];
    });
}

- (void)_getCacheInfoForKey:(NSString *)key
                 completion:(void(^)(BOOL hasCache, BOOL isComplete, NSString *cachePath, NSInteger fileSize))block
{
    if (!block) {
        return;
    }
    
    if (TYVideo_isEmptyString(key)) {
        block(NO, NO, nil, 0);
        return;
    }
    
    NSString *filePath = [TYVideoDiskCacheFileHandle dataPathWithKey:key];
    BOOL hasCache = [FILE_MANAGER fileExistsAtPath:filePath];
    long long cacheSize = [self _fileSizeAtPath:filePath];
    NSInteger fileSize = self.metaData[key] ? self.metaData[key].fileLength : 0;
    
    block(hasCache, fileSize == cacheSize, filePath, fileSize);
}

+ (void)sizeWithCompletion:(void(^)(NSInteger))block
{
    dispatch_async([TYVideoDiskCacheManger cacheQueue], ^{
        [[TYVideoDiskCacheFileHandle sharedInstance] _sizeWithCompletion:block];
    });
}

- (void)_sizeWithCompletion:(void(^)(NSInteger))block
{
    if (!block) {
        return;
    }
    
    long long size = [self _cacheSize];
    dispatch_async_on_main_queue(^{
        block((NSInteger)size);
    });
}

+ (void)clear
{
    dispatch_barrier_async([TYVideoDiskCacheManger cacheQueue], ^{
        [[TYVideoDiskCacheFileHandle sharedInstance] _clear];
    });
}

- (void)_clear
{
    self.metaData = [NSMutableDictionary dictionary];
    //
    [self _clearCacheSafely];
}

- (void)_clearCacheSafely
{
    NSArray<NSString *> *usingCacheItems = [TYVideoDiskCacheDeleteManager usingCacheItems];
    
    NSArray<NSString *> *childFiles = [FILE_MANAGER subpathsAtPath:[TYVideoDiskCacheFileHandle cachePath]];
    for (NSString *filename in childFiles) {
        NSString *absolutePath = [[TYVideoDiskCacheFileHandle cachePath] stringByAppendingPathComponent:filename];
        if ([usingCacheItems containsObject:filename] || [filename isEqualToString:kMetaFilename]) {
            continue;
        }
        
        [FILE_MANAGER removeItemAtPath:absolutePath error:NULL];
        if (self.metaData[filename]) {
            [self.metaData removeObjectForKey:filename];
        }
    }
    
    [self _syncMetaData];
}

- (void)_clearForKey:(NSString *)key
{
//    TY_VIDEO_DEBUG(@"clearForKey: %@", key);
    
    if (TYVideo_isEmptyString(key)) {
        return;
    }
    
    if (self.metaData[key]) {
        [self.metaData removeObjectForKey:key];
        //
        [self _syncMetaData];
    }
    //
    NSString *filePath = [TYVideoDiskCacheFileHandle dataPathWithKey:key];
    BOOL isDirectory = NO;
    BOOL fileExist = [FILE_MANAGER fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (fileExist && !isDirectory) {
        [FILE_MANAGER removeItemAtPath:filePath error:NULL];
    }
}

+ (void)clearForKeys:(NSArray<NSString *> *)keys
{
    dispatch_barrier_async([TYVideoDiskCacheManger cacheQueue], ^{
        [[TYVideoDiskCacheFileHandle sharedInstance] _clearForKeys:keys];
    });
}

- (void)_clearForKeys:(NSArray<NSString *> *)keys
{
//    TY_VIDEO_DEBUG(@"clearForKeys: %@", keys);
    
    if (TYVideo_isEmptyArray(keys)) {
        return;
    }
    
    [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        [self _clearForKey:key];
    }];
}

+ (void)trimDiskCacheToSize:(NSUInteger)size
{
    dispatch_barrier_async([TYVideoDiskCacheManger cacheQueue], ^{
        [[TYVideoDiskCacheFileHandle sharedInstance] _trimDiskCacheToSize:size];
    });
}

- (void)_trimDiskCacheToSize:(NSUInteger)size
{
    //    TY_VIDEO_INFO(@"trimDiskCacheToSize start");
    
    NSArray *resourceKeys = @[NSURLIsDirectoryKey,
                              NSURLContentAccessDateKey,
                              NSURLTotalFileAllocatedSizeKey];
    NSDirectoryEnumerator *fileEnumerator =
    [FILE_MANAGER enumeratorAtURL:[NSURL fileURLWithPath:[TYVideoDiskCacheFileHandle cachePath]]
       includingPropertiesForKeys:resourceKeys
                          options:NSDirectoryEnumerationSkipsHiddenFiles
                     errorHandler:nil];
    
    NSUInteger cacheSize = 0;
    NSMutableDictionary *cacheFiles = [NSMutableDictionary dictionary];
    for (NSURL *fileURL in fileEnumerator) {
        NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];
        if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
            continue;
        }
        cacheSize += [resourceValues[NSURLTotalFileAllocatedSizeKey] unsignedIntegerValue];
        //
        [cacheFiles setObject:resourceValues forKey:fileURL];
    }
    
    if (cacheSize <= size) {
        return;
    }
    
    NSArray *sortedFiles =
    [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                             usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                 return [obj1[NSURLContentAccessDateKey] compare:obj2[NSURLContentAccessDateKey]];
                             }];
    
    NSArray<NSString *> *usingCacheItems = [TYVideoDiskCacheDeleteManager usingCacheItems];
    for (NSURL *fileURL in sortedFiles) {
        NSString *filename = [[fileURL path] lastPathComponent];
        if ([usingCacheItems containsObject:filename] || [kMetaFilename isEqualToString:filename]) {
            continue;
        }
        
        if ([FILE_MANAGER removeItemAtURL:fileURL error:NULL]) {
            NSDictionary *resourceValues = cacheFiles[fileURL];
            cacheSize -= [resourceValues[NSURLTotalFileAllocatedSizeKey] unsignedIntegerValue];
            //
            NSString *key = fileURL.absoluteString.lastPathComponent;
            if (self.metaData[key]) {
                [self.metaData removeObjectForKey:key];
//                TY_VIDEO_DEBUG(@"trimDiskCacheToSize, key: %@", key);
            }
            //
            if (cacheSize <= size) {
                break;
            }
        }
    }
    
    [self _syncMetaData];
}

#pragma mark - Private

+ (NSString *)cachePath
{
    static NSString *cachePath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *rootCachePath = [TYVideoDiskCacheManger cachePath];
        cachePath = [rootCachePath stringByAppendingPathComponent:@"FileCache"];
    });
    
    if (![FILE_MANAGER fileExistsAtPath:cachePath]) {
        [FILE_MANAGER createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    return cachePath;
}

+ (NSString *)tmpPath
{
    static NSString *tmpPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *rootCachePath = [TYVideoDiskCacheManger cachePath];
        tmpPath = [rootCachePath stringByAppendingPathComponent:@"tmp"];
    });
    
    if (![FILE_MANAGER fileExistsAtPath:tmpPath]) {
        [FILE_MANAGER createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    return tmpPath;
}

static NSString * const kMetaFilename = @"meta";

+ (NSString *)metaPath
{
    return [[TYVideoDiskCacheFileHandle cachePath] stringByAppendingPathComponent:kMetaFilename];
}

+ (NSString *)dataPathWithKey:(NSString * _Nonnull)key
{
    return [[TYVideoDiskCacheFileHandle cachePath] stringByAppendingPathComponent:key];
}

- (BOOL)_syncMetaData
{
    BOOL succeed = [NSKeyedArchiver archiveRootObject:self.metaData toFile:[TYVideoDiskCacheFileHandle metaPath]];
    if (!succeed) {
        BOOL isDirectory = NO;
        BOOL fileExist = [FILE_MANAGER fileExistsAtPath:[TYVideoDiskCacheFileHandle metaPath] isDirectory:&isDirectory];
        uint64_t freeSize = [TYVideoDiskCacheManger freeFileSystemSize];
        NSString *status = [NSString stringWithFormat:@"fileExist = %@, isDirectory = %@, freeSize = %@", @(fileExist), @(isDirectory), @(freeSize)];
//        NSString *extra = [NSString stringWithFormat:@"%@", self.metaData];
        NSLog(@"syncMetaData error: %@, metaData: %@", status, self.metaData);
        //        TY_VIDEO_ERROR(@"syncMetaData error: %@, metaData: %@", status, self.metaData);
//        if (TY_Reporter) {
//            //            TY_Reporter(@"SyncMetaDataFail", status, extra);
//        }
    }
    
    return succeed;
}

#pragma mark - Utils

- (void)_clearCacheOnceForAll
{
    [self _clearFolderAtPath:[TYVideoDiskCacheManger cachePath]];
}

- (long long)_cacheSize
{
    return [self _folderSizeAtPath:[TYVideoDiskCacheManger cachePath]];
}

- (void)_clearFolderAtPath:(NSString *)folderPath
{
    BOOL isDirectory = NO;
    BOOL fileExist = [FILE_MANAGER fileExistsAtPath:folderPath isDirectory:&isDirectory];
    if (fileExist && isDirectory) {
        [FILE_MANAGER removeItemAtPath:folderPath error:NULL];
        [FILE_MANAGER createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

- (long long)_fileSizeAtPath:(NSString *)filePath
{
    BOOL isDirectory = NO;
    BOOL fileExist = [FILE_MANAGER fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (fileExist && !isDirectory) {
        return [[FILE_MANAGER attributesOfItemAtPath:filePath error:NULL] fileSize];
    }
    return 0;
}

- (long long)_folderSizeAtPath:(NSString *)folderPath
{
    BOOL isDirectory = NO;
    BOOL fileExist = [FILE_MANAGER fileExistsAtPath:folderPath isDirectory:&isDirectory];
    if (!fileExist || !isDirectory) {
        return 0;
    }
    
    long long folderSize = 0;
    NSArray *childFiles = [FILE_MANAGER subpathsAtPath:folderPath];
    for (NSString *fileName in childFiles) {
        NSString *absolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self _fileSizeAtPath:absolutePath];
    }
    
    return folderSize;
}

@end
