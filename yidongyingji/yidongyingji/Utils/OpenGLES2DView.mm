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

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
    {
        return nil;
    }
    // Filter前原生配置
    [self setConfigPre];
    
    // Filter配置
    filter.setLocalData(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    filter.initWithProgramAndImageByte(byte1, w1, h1, byte2, w2, h2);
    
    // Filter后原生配置
    [self setConfigTail];
    
    // Filter绘制
    filter.draw();
    
    // 显示在屏幕上
    [self.context presentRenderbuffer:GL_RENDERBUFFER];

    return self;
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
    byte1 = [GLESUtils getImageDataWithName:@"10_480_480.jpeg" width:&w1 height:&h1];
    byte2 = [GLESUtils getImageDataWithName:@"11_320_480.jpeg" width:&w2 height:&h2];
}

@end
