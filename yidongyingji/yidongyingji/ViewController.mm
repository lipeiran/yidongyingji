//
//  ViewController.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/23.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "ViewController.h"
#import "OpenGLESView.h"
#import "GuideView.h"

@interface ViewController ()
@property (nonatomic, strong) OpenGLESView *glesView;
@property (nonatomic, strong) GuideView *guideView;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.glesView = [[OpenGLESView alloc]initWithFrame:self.view.bounds];
    self.guideView = [[GuideView alloc]initWithFrame:self.view.bounds];
//    self.view = self.glesView;
    self.view = self.guideView;
}



@end
