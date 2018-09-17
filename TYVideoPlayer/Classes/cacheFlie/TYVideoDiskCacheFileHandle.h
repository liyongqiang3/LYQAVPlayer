//
//  TYVideoDiskCacheFileHandle.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/14.
//

#import <Foundation/Foundation.h>
#import "TYVideoDiskCacheProtocol.h"


@interface TYVideoDiskCacheFileHandle : NSObject<TYVideoDiskCacheProtocol>

/**
 * @brief singleton
 */
+ (instancetype)sharedInstance;

@end
