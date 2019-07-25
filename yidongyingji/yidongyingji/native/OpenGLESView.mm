//
//  OpenGLESView.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/23.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "OpenGLESView.h"
#include "Glm/glm.hpp"
#include "Glm/ext.hpp"
#include "GLESMath.h"

//编辑顶点坐标数组
GLfloat vertexData[] = {
    
    0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
    0.5, 0.5, -0.0f,    1.0f, 1.0f, //右上
    -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
    
    0.5, -0.5, 0.0f,    1.0f, 0.0f, //右下
    -0.5, 0.5, 0.0f,    0.0f, 1.0f, //左上
    -0.5, -0.5, 0.0f,   0.0f, 0.0f, //左下
};

CGFloat fov = 30.0f;

@interface OpenGLESView ()
{
    float xDegree;//X轴旋转角度
    float yDegree;//Y轴旋转角度
    float zDegree;//Z轴旋转角度
}

@end


@implementation OpenGLESView

GLProgram glProgram;

#pragma mark -
#pragma LifeCycle

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
    {
        return nil;
    }
    [self commonInit];
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self destroyDisplayFrameBuffer];
    [self createDisplayFrameBuffer];
    [self draw];
}

#pragma mark -
#pragma private methods

- (void)commonInit
{
    [self setupLayer];
    [self setupContext];
    [self compileProgram];
    [self createDisplayFrameBuffer];
    _vBufferID = cpp_createBufferObject(GL_ARRAY_BUFFER, sizeof(vertexData), GL_STATIC_DRAW, vertexData);
    [self setupTexture];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
    
}

- (void)destroyDisplayFrameBuffer
{
    if (_frameBuffer)
    {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    
    if (_renderBuffer)
    {
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
}

- (void)createDisplayFrameBuffer
{
    //设置渲染缓冲区
    [self setupRenderBuffer];
    //设置帧缓冲区
    [self setupFrameBuffer];
}

- (void)compileProgram
{
    //获取vsh/fsh路径
    NSString *vertexShaderPath = [[NSBundle mainBundle]pathForResource:@"shaderv" ofType:@"vsh"];
    NSString *fragmentShaderPath = [[NSBundle mainBundle]pathForResource:@"shaderf" ofType:@"fsh"];
    _program = cpp_compileProgram(glProgram, (char *)vertexShaderPath.UTF8String, (char *)fragmentShaderPath.UTF8String);
    //从program中获取position 顶点属性
    _position = glGetAttribLocation(_program, "position");
    //从program中获取textCoordinate 纹理属性
    _textCoordinate = glGetAttribLocation(_program, "textCoordinate");
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

- (void)setupRenderBuffer
{
    // 定义标识符ID
    _renderBuffer = cpp_setupRenderBuffer();
    // 将可绘制对象的存储绑定到OpenGLES renderbuffer对象
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
}

- (void)setupFrameBuffer
{
    _frameBuffer = cpp_setupFrameBuffer();
    // 生成帧缓冲区，把renderbuffer 跟 framebuffer绑定到一起
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
}

- (void)setDisplayFramebuffer
{
    if (!_frameBuffer)
    {
        [self createDisplayFrameBuffer];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    //获取缩放值
    CGFloat scale = [UIScreen mainScreen].scale;
    //设置视口
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height *scale);
}

- (void)setupTexture
{
    int w = 0, h = 0;
    GLubyte * byte = [self getImageDataWithName:@"test" width:&w height:&h];
    _texture = cpp_setupTexture(GL_TEXTURE1);
    cpp_upGPUTexture(w, h, byte);
    //释放byte
    free(byte);
}

- (void)draw
{
    glUseProgram(_program);
    [self setDisplayFramebuffer];
    //设置背景色
    glClearColor(1.0, 1.0, 1.0, 1);
    //清除颜色缓冲
    glClear(GL_COLOR_BUFFER_BIT);
    //开启正背面剔除
    glEnable(GL_CULL_FACE);
    //开启颜色混合
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    //获取缩放值
    CGFloat scale = [UIScreen mainScreen].scale;
    //设置视口
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height *scale);
    
    glBindBuffer(GL_ARRAY_BUFFER, _vBufferID);
    //开启顶点属性通道
    glEnableVertexAttribArray(_position);
    //设置顶点读取方式
    glVertexAttribPointer(_position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *) NULL + 0);
    //开启纹理属性通道
    glEnableVertexAttribArray(_textCoordinate);
    //设置纹理读取方式
    glVertexAttribPointer(_textCoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *) NULL + 3);
    
    GLuint projectionMatrix_S = glGetUniformLocation(_program, "projectionMatrix");
    GLuint modelViewMartix_S = glGetUniformLocation(_program, "modelViewMatrix");
    //获取view宽高 计算宽高比
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    float aspect = width / height; //长宽比
    
    //创建 4*4 投影矩阵
    KSMatrix4 _projectionMatrix;
    //加载投影矩阵
    ksMatrixLoadIdentity(&_projectionMatrix);
    //获取透视矩阵
    ksPerspective(&_projectionMatrix, 30.0, aspect, 0.00001f, 20.0f); //透视变换，视角30°
    //将投影矩阵传递到顶点着色器
    glUniformMatrix4fv(projectionMatrix_S, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    //模型视图矩阵
    KSMatrix4 _modelViewMatrix;
    //加载矩阵
    ksMatrixLoadIdentity(&_modelViewMatrix);
    //沿着z轴平移
    ksTranslate(&_modelViewMatrix, 0, 0, -3.1);
    
    //旋转矩阵
    KSMatrix4 _rotateMartix;
    //加载旋转矩阵
    ksMatrixLoadIdentity(&_rotateMartix);
    //旋转
    ksRotate(&_rotateMartix, xDegree, 1.0, 0, 0);
    ksRotate(&_rotateMartix, yDegree, 0, 1.0, 0);
    ksRotate(&_rotateMartix, zDegree, 0, 0, 1.0);
    
    //把变换矩阵相乘.将_modelViewMatrix矩阵与_rotationMatrix矩阵相乘，结合到模型视图
    ksMatrixMultiply(&_modelViewMatrix, &_rotateMartix, &_modelViewMatrix);
    //将模型视图矩阵传递到顶点着色器
    glUniformMatrix4fv(modelViewMartix_S, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix.m[0][0]);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _texture);
    //设置纹理采样器,这里的 0 对应 glBindTexture的 0
    glUniform1i(glGetUniformLocation(_program, "colorMap"), 1);

    //绘图
    glDrawArrays(GL_TRIANGLES, 0, 6);
    //将渲染缓冲区 呈现到 屏幕上
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

//纹理加载方法
-(void)loadTexture:(NSString *)name{
    CGImageRef cgImg = [UIImage imageNamed:name].CGImage;
    if (!cgImg) {
        NSLog(@"获取图片失败！");
        return;
    }
    size_t width = CGImageGetWidth(cgImg);
    size_t height = CGImageGetHeight(cgImg);
    
    // *4  因为RGBA
    GLubyte * byte = (GLubyte *)calloc(width * height * 4, sizeof(GLubyte));
    
    CGContextRef contextRef = CGBitmapContextCreate(byte, width, height, 8, width * 4, CGImageGetColorSpace(cgImg), kCGImageAlphaPremultipliedLast);
    
    
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(contextRef, rect, cgImg);
    
    CGContextRelease(contextRef);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    float w = width;
    float h = height;
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, byte);
    
    
    free(byte);
}

/**************************************************************  native  **********************************************************************/

#pragma mark -
#pragma mark Private methods

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

- (void)setupLayer
{
    // 创建特殊图层
    /*
     重写layerClass，将当前View返回的图层从CALayer替换成CAEAGLLayer
     */
    self.eaglLayer = (CAEAGLLayer *)self.layer;
    // 设置缩放
    [self setContentScaleFactor:[UIScreen mainScreen].scale];
    /*
     kEAGLDrawablePropertyRetainedBacking:NO （告诉CoreAnimation不要试图保留任何以前绘制的图像留作以后重用）
     kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8
     */
    self.eaglLayer.opaque = YES;
    NSDictionary *options = @{kEAGLDrawablePropertyRetainedBacking:@(false),kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};
    self.eaglLayer.drawableProperties = options;
    
    self.opaque = YES;
    self.hidden = NO;
}


-(void)pan:(UIPanGestureRecognizer *)pan{
    //获取偏移量
    // 返回的是相对于最原始的手指的偏移量
    CGPoint transP = [pan translationInView:self];
    
    xDegree = -transP.y;
    yDegree = -transP.x;
    
    [self draw];
}

@end
