//
//  YYVideoCachePrefetchTask.m
//  Pods-TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/16.
//

#import "TYVideoCachePrefetchTask.h"

@implementation TYVideoCachePrefetchTask

+ (instancetype)taskWithURL:(NSURL *)URL queue:(dispatch_queue_t)queue
{
    TYVideoCachePrefetchTask *task = [[TYVideoCachePrefetchTask alloc] initWithURL:URL queue:queue];
    //    TY_VIDEO_INFO(@"new TYVideoCachePrefetchTask: %p", task);
    
    return task;
}

- (BOOL)startWithSize:(NSUInteger)size
{
    float priority = 0.3;
    if (@available(iOS 8.0, *)) {
        priority = NSURLSessionTaskPriorityLow;
    }
    
    return [self startTaskWithRange:NSMakeRange(0, size) priority:priority];
}


@end
