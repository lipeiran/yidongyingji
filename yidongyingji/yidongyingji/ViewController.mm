//
//  ViewController.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/23.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLESView.h"
#import "OpenGLES2DView.h"
#import "GuideView.h"

@interface ViewController ()
@property (nonatomic, strong) OpenGLESView *glesView;
@property (nonatomic, strong) OpenGLES2DView *gles2DView;
@property (nonatomic, strong) GuideView *guideView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.glesView = [[OpenGLESView alloc]initWithFrame:self.view.bounds];
//    self.view = self.glesView;
    self.view.backgroundColor = [UIColor redColor];
    self.gles2DView = [[OpenGLES2DView alloc]initWithFrame:CGRectMake(self.view.bounds.origin.x/[UIScreen mainScreen].scale, self.view.bounds.origin.y/[UIScreen mainScreen].scale, 480/[UIScreen mainScreen].scale, 640/[UIScreen mainScreen].scale)];
    [self.view addSubview:self.gles2DView];
    
//    self.guideView = [[GuideView alloc]initWithFrame:self.view.bounds];
//    self.view = self.guideView;
}



@end
