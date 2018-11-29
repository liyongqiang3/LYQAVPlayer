//
//  TYVideoPlayerDefines.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/14.
//


#import <Foundation/Foundation.h>
#import <pthread.h>
//#include "TYVideoLogger.h"

FOUNDATION_EXPORT NSString * const TYVideoPlayerErrorDomain;
FOUNDATION_EXPORT NSString * const TYReporterLabel_CachedSizeWhenPlay;
FOUNDATION_EXPORT NSString * const TYReporterLabel_CacheDataCorrupted;
FOUNDATION_EXPORT NSString * const TYReporterLabel_ServerError;
FOUNDATION_EXPORT NSString * const TYReporterLabel_CachePlay_CDN_URL;
FOUNDATION_EXPORT NSString * const TYReporterLabel_WriteFileFail;
FOUNDATION_EXPORT NSString * const TYReporterLabel_ReadFileFail;
FOUNDATION_EXPORT NSString * const TYReporterLabel_MetaDataCorrupted;
FOUNDATION_EXPORT NSString * const TYReporterLabel_PlaybackError;

/// video player error
typedef NS_ENUM(NSInteger, TYVideoPlayerError) {
    /// unknown
    TYVideoPlayerErrorUnknown = 5000,
    /// player item nil
    TYVideoPlayerErrorPlayerItemNil,
    /// player item status failed
    TYVideoPlayerErrorPlayerItemStatusFailed,
    /// fail to play to end time
    TYVideoPlayerErrorPlayerItemFailedToPlayToEndTime,
    /// player item broken
    TYVideoPlayerErrorPlayerItemBroken,
    /// bad URL response
    TYVideoPlayerErrorURLResponse,
    /// inconsistent play source
    TYVideoPlayerErrorInconsistentPlaySource,
    /// player nit
    TYVideoPlayerErrorPlayerNil,
    /// asset nil
    TYVideoPlayerErrorAssetNil,
    /// playback error
    TYVideoPlayerErrorPlaybackError,
    
    /// cache check failed
    TYVideoCacheErrorCheckFailed = 6000,
    /// cache create file failed
    TYVideoCacheErrorCreateFileFailed,
    /// cache meta not found
    TYVideoCacheErrorMetaNotFound,
    /// cache empty key
    TYVideoCacheErrorEmptyKey,
    /// cache data file not exist
    TYVideoCacheErrorDataFileNotExist,
    /// cache write filehandle nil
    TYVideoCacheErrorWriteFileHandleNil,
    /// cache write file failed
    TYVideoCacheErrorWriteFileFailed,
    /// cache read filehandle nil
    TYVideoCacheErrorReadFileHandleNil,
    /// cache read file neta not exist
    TYVideoCacheErrorReadFileMetaNotExist,
    /// cache read file failed
    TYVideoCacheErrorReadFileFailed,
};

FOUNDATION_EXPORT NSString * TY_MD5(NSString *str);
FOUNDATION_EXPORT NSError * TYError(NSInteger code, NSString *desc);

#if DEBUG
#define TYVideo_keywordify autoreleasepool {}
#else
#define TYVideo_keywordify try {} @catch (...) {}
#endif

#ifndef onExit
inline static void blockCleanUp(__strong void(^*block)(void))
{
    (*block)();
}

#define onExit \
TYVideo_keywordify __strong void(^block)(void) __attribute__((cleanup(blockCleanUp), unused)) = ^

#endif

#ifndef TYVideo_isEmptyString
#define TYVideo_isEmptyString(param)        ( !(param) ? YES : ([(param) isKindOfClass:[NSString class]] ? (param).length == 0 : NO) )
#endif

#ifndef TYVideo_isEmptyArray
#define TYVideo_isEmptyArray(param)         ( !(param) ? YES : ([(param) isKindOfClass:[NSArray class]] ? (param).count == 0 : NO) )
#endif

static inline void dispatch_async_on_main_queue(void (^block)(void))
{
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

