//
//  TYVideoObjectPool.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import "TYVideoObjectPool.h"

@interface TYVideoObjectPool<__covariant ObjectType> ()

// sample pool
@property (nonatomic, strong) NSMutableArray<ObjectType> *pool;

// object class
@property (nonatomic, strong) Class objectClass;

// max count
@property (nonatomic, assign) NSUInteger maxCount;

@end

@implementation TYVideoObjectPool

- (instancetype)initWithClass:(Class)aClass maxCount:(NSUInteger)count
{
    self = [super init];
    if (self) {
        _pool = [NSMutableArray arrayWithCapacity:100];
        _objectClass = aClass;
        _maxCount = count;
    }
    
    return self;
}

- (id)getObject
{
    @synchronized(self)
    {
        if (self.pool.count > 0) {
            id object = self.pool.lastObject;
            [self.pool removeLastObject];
            return object;
        }
        
        return [self.objectClass new];
    }
}

- (void)returnObject:(id)object
{
    @synchronized(self)
    {
        if (self.pool.count < self.maxCount) {
            [self.pool addObject:object];
        }
    }
}

@end
