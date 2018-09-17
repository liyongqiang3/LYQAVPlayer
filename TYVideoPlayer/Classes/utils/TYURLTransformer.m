//
//  TYURLTransformer.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import "TYURLTransformer.h"

@interface  TYURLTransformer ()

// < custom, origin >
@property (nonatomic, strong) NSMutableDictionary<NSURL *, NSURL *> *urlMap;

@end

@implementation TYURLTransformer

+ (instancetype)sharedInstance
{
    static TYURLTransformer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [TYURLTransformer new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _urlMap = [NSMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark - Public

+ (NSURL *)customURLForOriginURL:(NSURL *)originURL
{
    return [[TYURLTransformer sharedInstance] _customURLForOriginURL:originURL];
}

+ (NSURL *)originURLForCustomURL:(NSURL *)customURL
{
    return [[TYURLTransformer sharedInstance] _originURLForCustomURL:customURL];
}

- (NSURL *)_customURLForOriginURL:(NSURL *)originURL
{
    static NSString * const customScheme = @"tyStreaming";
    
    if(!originURL){
        return nil;
    }
    
    @synchronized(self)
    {
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:originURL resolvingAgainstBaseURL:NO];
        components.scheme = customScheme;
        NSURL *customURL = [components URL];
        [self.urlMap setObject:originURL forKey:customURL];
        
        return customURL;
    }
}

- (NSURL *)_originURLForCustomURL:(NSURL *)customURL
{
    @synchronized(self)
    {
        NSURL *originURL = nil;
        
        if ([self.urlMap objectForKey:customURL]) {
            originURL = [self.urlMap objectForKey:customURL];
        }
        
        return originURL;
    }
}
@end
