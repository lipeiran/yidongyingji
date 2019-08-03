//
//  OpenGLESView.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/23.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "OpenGLES2DView.h"
#include "GLESMath.h"

@interface OpenGLES2DView ()
{
    CADisplayLink *_displayLink;
    NSTimer *_theTimer;
}

@end

@implementation OpenGLES2DView

#pragma mark -
#pragma LifeCycle

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)dealloc
{
    // Filter销毁
    filter.destropDisplayFrameBuffer();
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    NSLog(@"%s",__func__);
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
    {
        return nil;
    }
    // Filter前原生配置
    [self setConfigPre];
    
    // Filter配置
    filter.initWithProgram(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);

    //---------------- 获取图片数据可以放到C++文件中，由ffmpeg解码 ---------------//
    int w1,h1,w2,h2,w3,h3,w4,h4;
    GLubyte * byte1 = NULL,*byte2 = NULL,*byte3 = NULL,*byte4 = NULL;
    
    byte1 = [OpenGLES2DTools getImageDataWithName:@"img_0.png" width:&w1 height:&h1];
    byte2 = [OpenGLES2DTools getImageDataWithName:@"img_1.png" width:&w2 height:&h2];
    byte3 = [OpenGLES2DTools getImageDataWithName:@"img_2.png" width:&w3 height:&h3];
    byte4 = [OpenGLES2DTools getImageDataWithName:@"img_3.png" width:&w4 height:&h4];
    
    GPUImage image1;
    image1.byte = byte1;
    image1.w = w1;
    image1.h = h1;
    filter.addImageAsset(image1);
    GPUImage image2;
    image2.byte = byte2;
    image2.w = w2;
    image2.h = h2;
    filter.addImageAsset(image2);
    GPUImage image3;
    image3.byte = byte3;
    image3.w = w3;
    image3.h = h3;
    filter.addImageAsset(image3);
    GPUImage image4;
    image4.byte = byte4;
    image4.w = w4;
    image4.h = h4;
    filter.addImageAsset(image4);

    char *configPath = (char *)[[[NSBundle mainBundle]pathForResource:@"tp" ofType:@"json"] UTF8String];
    filter.addConfigure(configPath);
    
    // Filter后原生配置
    [self setConfigTail];
    
//    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateDisplay:)];
//    _displayLink.frameInterval = 2;
//    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    float theInterval = 1.0/25.0f;  //每秒调用30次
    _theTimer = [NSTimer scheduledTimerWithTimeInterval:theInterval target:self selector:@selector(updateDisplay:) userInfo:nil repeats:YES];
    return self;
}

- (void)updateDisplay:(NSTimer *)timer
{
    filter.draw();
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark -
#pragma private methods

- (void)setConfigPre
{
    // 设置全局数据
    [self setLocalData];
    // 设置 EAGL layer 环境
    [self setupLayer];
    // 设置OpenGLES上下文
    [self setupContext];
    // 获取图片数据
    [self setImageData];
}

- (void)setConfigTail
{
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
}

// 设置全局数据
- (void)setLocalData
{
    scale = [UIScreen mainScreen].scale;
}

// 设置 EAGL layer 环境
- (void)setupLayer
{
    self.opaque = YES;
    self.hidden = NO;
    // 创建特殊图层
    self.eaglLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:[UIScreen mainScreen].scale];
    self.eaglLayer.opaque = YES;
    NSDictionary *options = @{kEAGLDrawablePropertyRetainedBacking:@(false),kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};
    self.eaglLayer.drawableProperties = options;
}

// 设置OpenGLES上下文
- (void)setupContext
{
    // 创建context
    self.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!_context)
    {
        NSLog(@"context创建失败");
        return;
    }
    // 设置当前context并判断是否设置成功
    if ([EAGLContext setCurrentContext:self.context] == false)
    {
        NSLog(@"设置当前context失败！");
    }
}

// 获取图片数据
- (void)setImageData
{
//    byte1 = [OpenGLES2DTools getImageDataWithName:@"10_480_480.jpeg" width:&w1 height:&h1];
//    byte2 = [OpenGLES2DTools getImageDataWithName:@"11_320_480.jpeg" width:&w2 height:&h2];
}

@end
