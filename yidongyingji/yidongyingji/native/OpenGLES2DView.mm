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
    filter.destropDisplayFrameBuffer();
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
    {
        return nil;
    }
    [self setConfigPre];
    
    filter.setLocalData(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    filter.initWithProgramAndImageByte(byte1, w1, h1, byte2, w2, h2);
    
    [self setConfigTail];
    
    [self draw];

    return self;
}

- (void)draw
{
    filter.draw();
    //将渲染缓冲区 呈现到 屏幕上
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark -
#pragma private methods

- (void)setConfigPre
{
    [self setLocalData];
    [self setupLayer];
    [self setupContext];
    [self setImageData];
}

- (void)setConfigTail
{
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
}

- (void)setLocalData
{
    //获取vsh/fsh路径
    scale = [UIScreen mainScreen].scale;
}

- (void)setupLayer
{
    // 创建特殊图层
    self.eaglLayer = (CAEAGLLayer *)self.layer;
    [self setContentScaleFactor:[UIScreen mainScreen].scale];
    self.eaglLayer.opaque = YES;
    NSDictionary *options = @{kEAGLDrawablePropertyRetainedBacking:@(false),kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};
    self.eaglLayer.drawableProperties = options;
    
    self.opaque = YES;
    self.hidden = NO;
}

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

- (void)setImageData
{
    w1 = 0;
    h1 = 0;
    byte1 = [self getImageDataWithName:@"10_480_480.jpeg" width:&w1 height:&h1];
    w2 = 0;
    h2 = 0;
    byte2 = [self getImageDataWithName:@"11_320_480.jpeg" width:&w2 height:&h2];
}

- (GLubyte *)getImageDataWithName:(NSString *)imageName width:(int*)width height:(int*)height
{
    //获取纹理图片
    CGImageRef cgImgRef = [UIImage imageNamed:imageName].CGImage;
    if (!cgImgRef)
    {
        NSLog(@"纹理获取失败");
    }
    //获取图片长、宽
    size_t wd = CGImageGetWidth(cgImgRef);
    size_t ht = CGImageGetHeight(cgImgRef);
    GLubyte *byte = (GLubyte *)calloc(wd * ht * 4, sizeof(GLubyte));
    CGContextRef contextRef = CGBitmapContextCreate(byte, wd, ht, 8, wd * 4, CGImageGetColorSpace(cgImgRef), kCGImageAlphaPremultipliedLast);
    //长宽转成float 方便下面方法使用
    float w = wd;
    float h = ht;
    CGRect rect = CGRectMake(0, 0, w, h);
    CGContextDrawImage(contextRef, rect, cgImgRef);
    //图片绘制完成后，contextRef就没用了，释放
    CGContextRelease(contextRef);
    *width = w;
    *height = h;
    return byte;
}

@end
