//
//  TYVideoLogger.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#ifndef __TYVideoLogger_H__
#define __TYVideoLogger_H__

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, TYVideoLoggerLevel)
{
    TYVideoLoggerLevelError = 0,
    TYVideoLoggerLevelWarn,
    TYVideoLoggerLevelInfo,
    TYVideoLoggerLevelDebug,
    TYVideoLoggerLevelTrace,
};

typedef void(^TYVideoPlayerGetLogCompletion)(NSString * _Nullable content);


/**
 * @brief get log data from disk. File Log ONLY.
 */
FOUNDATION_EXTERN void TYVideoPlayerGetLogWithMaxLength(NSUInteger maxLength, TYVideoPlayerGetLogCompletion _Nonnull completion);

/**
 * @brief log utility. USE MACRO INSTEAD
 */
FOUNDATION_EXTERN void TY_VIDEO_Log(TYVideoLoggerLevel level,
                                     const char * _Nonnull file,
                                     int line,
                                     NSString * _Nonnull format,
                                     ...) NS_FORMAT_FUNCTION(4, 5);

/**
 File Log Path
 */
FOUNDATION_EXTERN NSArray<NSString *> *TYVideoSortedLogFilePaths();


@protocol TYVideoPlayerLoggerDelegate

- (void)logMessage:(NSString * _Nonnull)message level:(TYVideoLoggerLevel)level;

@end

#define TY_VIDEO_STRINGIFY(FMT, ...) ([NSString stringWithFormat:FMT, ##__VA_ARGS__])

#define TY_VIDEO_TRACE(FMT, ...)   TY_VIDEO_Log(TYVideoLoggerLevelTrace, __FILE__, __LINE__, @"%@", TY_VIDEO_STRINGIFY(FMT, ##__VA_ARGS__))
#define TY_VIDEO_DEBUG(FMT, ...)   TY_VIDEO_Log(TYVideoLoggerLevelDebug, __FILE__, __LINE__, @"%@", TY_VIDEO_STRINGIFY(FMT, ##__VA_ARGS__))
#define TY_VIDEO_INFO(FMT, ...)    TY_VIDEO_Log(TYVideoLoggerLevelInfo,  __FILE__, __LINE__, @"%@", TY_VIDEO_STRINGIFY(FMT, ##__VA_ARGS__))
#define TY_VIDEO_WARN(FMT, ...)    TY_VIDEO_Log(TYVideoLoggerLevelWarn,  __FILE__, __LINE__, @"%@", TY_VIDEO_STRINGIFY(FMT, ##__VA_ARGS__))
#define TY_VIDEO_ERROR(FMT, ...)   TY_VIDEO_Log(TYVideoLoggerLevelError, __FILE__, __LINE__, @"%@", TY_VIDEO_STRINGIFY(FMT, ##__VA_ARGS__))

#endif
