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
#import "LPRGPUImageView.h"
#import "LPRGPUImageMovieWriter.h"

@interface ViewController ()
@property (nonatomic, strong) OpenGLESView *glesView;
@property (nonatomic, strong) GuideView *guideView;
@property (nonatomic, strong) LPRGPUImageView *lprGPUView;
@property (nonatomic, strong) LPRGPUImageMovieWriter *movieWriter;
@property (nonatomic, strong) UISlider *progress_slider;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 预览
    [self preView];
    
    // 导出
//    [self generateMP4];
}

- (void)preView
{
    self.view.backgroundColor = [UIColor lightGrayColor];
    self.lprGPUView = [[LPRGPUImageView alloc]initWithFrame:CGRectMake(Draw_x/[UIScreen mainScreen].scale, Draw_y/[UIScreen mainScreen].scale, Draw_w/[UIScreen mainScreen].scale, Draw_h/[UIScreen mainScreen].scale)];
    [self.view addSubview:self.lprGPUView];
    
    self.progress_slider = [[UISlider alloc]initWithFrame:CGRectMake(100, 400, 200, 30)];
    [self.progress_slider addTarget:self action:@selector(changeSliderValue:) forControlEvents:UIControlEventValueChanged];
    [self.progress_slider addTarget:self action:@selector(touchDownAction:) forControlEvents:UIControlEventTouchDown];
    [self.progress_slider addTarget:self action:@selector(touchUpInsideAction:) forControlEvents:UIControlEventTouchUpInside];
    self.progress_slider.value = 0.0;
    [self.view addSubview:self.progress_slider];
}

- (void)generateMP4
{
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    NSString *configPath = @"/Users/lipeiran/Desktop/test_lpr_gpu.mp4";

    self.movieWriter = [[LPRGPUImageMovieWriter alloc]initWithMovieURL:[NSURL URLWithString:configPath] size:CGSizeMake(Draw_w, Draw_h)];
    
}

- (void)changeSliderValue:(UISlider *)slider
{
    [self.lprGPUView seekToPercent:slider.value];
}

- (void)touchDownAction:(UISlider *)slider
{
    [self.lprGPUView pause];
}

- (void)touchUpInsideAction:(UISlider *)slider
{
    [self.lprGPUView resume];
}

@end
