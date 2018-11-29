//
//  TYVideoPlayerDefines.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/14.
//


#import "TYVideoPlayerDefines.h"
//#import "TYVideoDiskCacheConfiguration.h"
#import <CommonCrypto/CommonDigest.h>

NSString * const TYVideoPlayerErrorDomain           = @"TYVideoPlayerErrorDomain";

NSString * const TYReporterLabel_CachedSizeWhenPlay = @"CachedSizeWhenPlay";
NSString * const TYReporterLabel_CacheDataCorrupted = @"CacheDataCorrupted";
NSString * const TYReporterLabel_ServerError = @"ServerError";
NSString * const TYReporterLabel_CachePlay_CDN_URL = @"CachePlay_CDN_URL";
NSString * const TYReporterLabel_WriteFileFail = @"WriteFileFail";
NSString * const TYReporterLabel_ReadFileFail = @"ReadFileFail";
NSString * const TYReporterLabel_MetaDataCorrupted = @"MetaDataCorrupted";
NSString * const TYReporterLabel_PlaybackError = @"PlaybackError";

NSString * TY_MD5(NSString *str)
{
    if (TYVideo_isEmptyString(str)) {
        return str;
    }
    
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

NSError * TYError(NSInteger code, NSString *desc)
{
    NSDictionary *userInfo = @{
                               NSLocalizedDescriptionKey : (desc ? : @""),
                               };
    
    return [NSError errorWithDomain:TYVideoPlayerErrorDomain
                               code:code
                           userInfo:userInfo];
}

