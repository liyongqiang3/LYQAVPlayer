//
//  TYMainTabbarController.m
//  TYVideoPayerDemo
//
//  Created by yongqiang li on 2018/9/14.
//  Copyright © 2018 yongqiang. All rights reserved.
//

#import "TYMainTabbarController.h"
#import "TYFeedViewController.h"
#import "TYSetViewController.h"
#import "TYFollowViewController.h"

@interface TYMainTabbarController ()

@property (nonatomic) TYFeedViewController *feedVc;
@property (nonatomic) TYSetViewController *setVc;
@property (nonatomic) TYFollowViewController *followVc;

@end

@implementation TYMainTabbarController

- (id)init
{
    self = [super init];
    if (self) {
        [self loadViewContollers];
    }
    return self;
}

- (void)loadViewContollers
{
    self.feedVc = [[TYFeedViewController alloc] init];
    self.feedVc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"feed" image:nil tag:0];
    UINavigationController *feedNav = [[UINavigationController alloc] initWithRootViewController:self.feedVc];
    self.followVc = [[TYFollowViewController alloc] init];
    self.followVc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"关注" image:nil tag:0];
    self.followVc.title = @"关注";
    UINavigationController *followNav = [[UINavigationController alloc] initWithRootViewController:self.followVc];
    self.setVc = [[TYSetViewController alloc] init];
    self.setVc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"设置" image:nil tag:0];
    self.setVc.title = @"设置";
    UINavigationController *setNav = [[UINavigationController alloc] initWithRootViewController:self.setVc];
    self.viewControllers = @[feedNav,followNav,setNav];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
