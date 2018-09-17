//
//  TYVideoObjectPool.h
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import <Foundation/Foundation.h>

@interface TYVideoObjectPool<__covariant ObjectType>  : NSObject

/*
 * @param aClass object class
 */
- (instancetype)initWithClass:(Class)aClass maxCount:(NSUInteger)count;

/*
 * @brief get an object
 */
- (ObjectType)getObject;

/*
 * @brief return an object
 */
- (void)returnObject:(ObjectType)object;

@end
