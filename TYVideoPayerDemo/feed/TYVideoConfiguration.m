//
//  TYVideoConfiguration.m
//  TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/17.
//  Copyright © 2018 yongqiang. All rights reserved.
//

#import "TYVideoConfiguration.h"

@implementation TYVideoConfiguration

+ (instancetype)sharedInstance
{
    static TYVideoConfiguration *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [TYVideoConfiguration new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.useCache = YES;
        self.repeated = YES;
        self.playbackRate = 1.0f;
    }
    
    return self;
}

@end
