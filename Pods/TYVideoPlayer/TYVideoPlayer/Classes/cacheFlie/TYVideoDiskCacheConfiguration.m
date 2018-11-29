//
//  TYVideoDiskCacheConfiguration.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/14.
//

#import "TYVideoDiskCacheConfiguration.h"
#import "TYVideoPlayerDefines.h"

@implementation TYVideoDiskCacheConfiguration

+ (instancetype)sharedInstance
{
    static TYVideoDiskCacheConfiguration *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [TYVideoDiskCacheConfiguration new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 300 MB
        _costLimit = 300;
        // 5 min
        _autoTrimInterval = 5 * 60;
        //
        _fileLogEnabled = NO;
    }
    
    return self;
}

@end

NSString * TYVideoURLStringToCacheKey(NSString *urlString)
{
    NSString *cacheKey = urlString;
    if ([TYVideoDiskCacheConfiguration sharedInstance].URLStringToCacheKey) {
        cacheKey = [TYVideoDiskCacheConfiguration sharedInstance].URLStringToCacheKey(urlString);

    }
    
    return TY_MD5(cacheKey);
}
