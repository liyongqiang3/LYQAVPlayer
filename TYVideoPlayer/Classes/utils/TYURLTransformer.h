//
//  TYURLTransformer.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import <Foundation/Foundation.h>

@interface TYURLTransformer : NSObject

+ (NSURL *)customURLForOriginURL:(NSURL *)originURL;


+ (NSURL *)originURLForCustomURL:(NSURL *)customURL;

@end
