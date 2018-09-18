//
//  UIView+Gesture.m
//  iHotelMerchant
//
//  Created by 张宇 on 16/6/7.
//  Copyright © 2016年 psy. All rights reserved.
//

#import "UIView+Gesture.h"

@implementation UIView (HTMGesture)

- (void)addTapAction:(SEL)tapAction target:(id)target
{
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:target action:tapAction];
    gesture.cancelsTouchesInView = NO;
    [self addGestureRecognizer:gesture];
}

@end
