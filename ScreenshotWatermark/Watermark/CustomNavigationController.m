//
//  CustomNavigationController.m
//  ScreenshotWatermark
//
//  Created by Alix on 2018/5/21.
//  Copyright © 2018 Guanglu. All rights reserved.
//

#import "CustomNavigationController.h"

@interface CustomNavigationController ()

@end

@implementation CustomNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated{
    [super pushViewController:viewController animated:animated];
    [UIApplication sharedApplication].keyWindow.frame = [UIApplication sharedApplication].keyWindow.frame;
}
- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    [UIApplication sharedApplication].keyWindow.frame = [UIApplication sharedApplication].keyWindow.frame;
    return [super popViewControllerAnimated:animated];
}
@end
