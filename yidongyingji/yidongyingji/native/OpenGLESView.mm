//
//  OpenGLESView.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/23.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "OpenGLESView.h"

//编辑顶点坐标数组
GLfloat vertexData[] = {
    
    0.5, -0.25, 0.0f,    1.0f, 0.0f, //右下
    0.5, 0.25, -0.0f,    1.0f, 1.0f, //右上
    -0.5, 0.25, 0.0f,    0.0f, 1.0f, //左上
    
    0.5, -0.25, 0.0f,    1.0f, 0.0f, //右下
    -0.5, 0.25, 0.0f,    0.0f, 1.0f, //左上
    -0.5, -0.25, 0.0f,   0.0f, 0.0f, //左下
};

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
    _texture = cpp_setupTexture(GL_TEXTURE0);
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
    
    glBindTexture(GL_TEXTURE_2D, _texture);
    //设置纹理采样器,这里的 0 对应 glBindTexture的 0
    glUniform1i(glGetUniformLocation(_program, "colorMap"), 0);
    //绘图
    glDrawArrays(GL_TRIANGLES, 0, 6);
    //将渲染缓冲区 呈现到 屏幕上
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
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

@end
