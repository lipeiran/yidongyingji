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
#import "LPRGPUImageView.h"

@interface ViewController ()
@property (nonatomic, strong) OpenGLESView *glesView;
@property (nonatomic, strong) OpenGLES2DView *gles2DView;
@property (nonatomic, strong) GuideView *guideView;
@property (nonatomic, strong) LPRGPUImageView *lprGPUView;
@property (nonatomic, strong) UISlider *progress_slider;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor redColor];
    self.lprGPUView = [[LPRGPUImageView alloc]initWithFrame:CGRectMake(self.view.bounds.origin.x/[UIScreen mainScreen].scale, self.view.bounds.origin.y/[UIScreen mainScreen].scale, 480/[UIScreen mainScreen].scale, 640/[UIScreen mainScreen].scale)];
    [self.view addSubview:self.lprGPUView];
    
    self.progress_slider = [[UISlider alloc]initWithFrame:CGRectMake(100, 400, 200, 30)];
    [self.progress_slider addTarget:self action:@selector(changeSliderValue:) forControlEvents:UIControlEventValueChanged];
    [self.progress_slider addTarget:self action:@selector(touchDownAction:) forControlEvents:UIControlEventTouchDown];
    [self.progress_slider addTarget:self action:@selector(touchUpInsideAction:) forControlEvents:UIControlEventTouchUpInside];
    self.progress_slider.value = 0.0;
    [self.view addSubview:self.progress_slider];
}

- (void)changeSliderValue:(UISlider *)slider
{
    
}

- (void)touchDownAction:(UISlider *)slider
{
    
}

- (void)touchUpInsideAction:(UISlider *)slider
{
    
}



@end
