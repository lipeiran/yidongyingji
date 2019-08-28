//
//  ViewController.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/23.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "ViewController.h"
#import "GuideView.h"
#import "LPRGPUImageView.h"
#import "LPRGPUCopyWriter.h"

@interface ViewController ()
@property (nonatomic, strong) GuideView *guideView;
@property (nonatomic, strong) LPRGPUImageView *lprGPUView;
@property (nonatomic, strong) LPRGPUCopyWriter *cpWriter;
@property (nonatomic, strong) UISlider *progress_slider;
@property (nonatomic, strong) UILabel *percent_label;

@property (nonatomic, strong) UIButton *exportBtn;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 预览
    [self preView];
}

- (void)preView
{
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    _percent_label = [[UILabel alloc]initWithFrame:CGRectMake(10, 100, 200, 50)];
    _percent_label.backgroundColor = [UIColor blueColor];
    _percent_label.textColor = [UIColor redColor];
    _percent_label.font = [UIFont systemFontOfSize:30];
    _percent_label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:_percent_label];
    
    _lprGPUView = [[LPRGPUImageView alloc]initWithFrame:CGRectMake(Draw_x/[UIScreen mainScreen].scale, Draw_y/[UIScreen mainScreen].scale, Draw_w/[UIScreen mainScreen].scale, Draw_h/[UIScreen mainScreen].scale)];
    [self.view addSubview:self.lprGPUView];
    
    _progress_slider = [[UISlider alloc]initWithFrame:CGRectMake(100, 400, 200, 30)];
    [self.progress_slider addTarget:self action:@selector(changeSliderValue:) forControlEvents:UIControlEventValueChanged];
    [self.progress_slider addTarget:self action:@selector(touchDownAction:) forControlEvents:UIControlEventTouchDown];
    [self.progress_slider addTarget:self action:@selector(touchUpInsideAction:) forControlEvents:UIControlEventTouchUpInside];
    self.progress_slider.value = 0.0;
    [self.view addSubview:self.progress_slider];
    
    _exportBtn = [[UIButton alloc]initWithFrame:CGRectMake(100, 450, 200, 30)];
    [self.exportBtn setTitle:@"导出" forState:UIControlStateNormal];
    [self.exportBtn addTarget:self action:@selector(generateMP4) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.exportBtn];
}

- (void)generateMP4
{
    [self.lprGPUView stopTimer];
    [self.lprGPUView removeFromSuperview];
    self.lprGPUView = nil;
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie10.mp4"];
    unlink(pathToMovie.UTF8String);

    self.cpWriter = [[LPRGPUCopyWriter alloc]initWithMovieURL:[NSURL fileURLWithPath:pathToMovie] size:CGSizeMake(Draw_w, Draw_h)];
    __block ViewController *tmpWeakSelf = self;
    self.cpWriter.progressBlock = ^(CGFloat percent){
        dispatch_async(dispatch_get_main_queue(), ^{
            tmpWeakSelf.percent_label.text = [NSString stringWithFormat:@"%.2f",percent];
        });
    };
    [self.cpWriter startRecording];
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
