//
//  GuideView.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/25.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "GuideView.h"
#import <OpenGLES/ES3/gl.h>
#import "GLESUtils.h"
#import "GLESMath.h"

@interface GuideView ()
{
    float xDegree;//X轴旋转角度
    float yDegree;//Y轴旋转角度
    float zDegree;//Z轴旋转角度
}
@property(strong,nonatomic)CAEAGLLayer *eaglLayer;

@property(strong,nonatomic)EAGLContext *context;

@property(assign,nonatomic)GLuint program;

@property(assign,nonatomic)GLuint frameBuffer;

@property(assign,nonatomic)GLuint renderBuffer;

@end

@implementation GuideView

-(void)setupLayer{
    
    
    
    self.eaglLayer = (CAEAGLLayer *)self.layer;
    
    [self setContentScaleFactor:[UIScreen mainScreen].scale];
    
    NSDictionary *options = @{kEAGLDrawablePropertyRetainedBacking:@(false),
                              kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};
    
    self.eaglLayer.drawableProperties = options;
}
//重写layerClass方法
+(Class)layerClass{
    return [CAEAGLLayer class];
}

-(void)setupContext{
    self.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!_context) {
        NSLog(@"context创建失败");
        return;
    }
    if ([EAGLContext setCurrentContext:self.context]==false) {
        NSLog(@"设置当前context失败！");
        return;
    }
    
}

-(void)deleteBuffers{
    glDeleteBuffers(1, &_frameBuffer);
    _frameBuffer = 0;
    glDeleteBuffers(1, &_renderBuffer);
    _renderBuffer = 0 ;
}

-(void)setupRenderBuffer{
    
    GLuint bufferID;
    
    glGenRenderbuffers(1, &bufferID);
    
    self.renderBuffer = bufferID;
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
    
}

-(void)setupFrameBuffer{
    GLuint bufferID;
    
    glGenFramebuffers(1, &bufferID);
    
    self.frameBuffer  = bufferID;
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.renderBuffer);
}

-(void)draw{
    //设置背景色
    glClearColor(0.75, 0.85, 0.85, 1);
    //清理颜色缓冲、深度缓冲
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    //缩放
    GLfloat scale = UIScreen.mainScreen.scale;
    //设置视口
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    //获取着色器路径
    NSString *vertexShaderPath = [[NSBundle mainBundle]pathForResource:@"guide" ofType:@"vsh"];
    NSString *fragmentShaderPath = [[NSBundle mainBundle]pathForResource:@"guide" ofType:@"fsh"];
    //调用封装方法创建program
    GLuint program = [GLESUtils loadProgram:vertexShaderPath withFragmentShaderFilepath:fragmentShaderPath];
    //使用program
    glUseProgram(program);
    self.program = program;
    
    //创建顶点数组 & 索引数组
    //顶点数组 前3顶点值（x,y,z），后3位颜色值(RGB) ，最后2位纹理坐标(s,t)
    GLfloat attrArr [] = {
        -0.5, 0.5, 0.0,   0.0, 0.0, 0.5,   0.0, 1.0,
        0.5, 0.5, 0.0,    0.0, 0.5, 0.0,   1.0, 1.0,
        -0.5, -0.5, 0.0,  0.5, 0.0, 0.0,   0.0, 0.0,
        0.5, -0.5, 0.0,   0.0, 0.0, 0.5,   1.0, 0.0,
        0.0, 0.0, 1.0,     1.0, 1.0, 1.0,   0.5, 0.5
    };
    
    //索引数组
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    //定义标识符
    GLuint bufferID;
    //申请标识符
    glGenBuffers(1, &bufferID);
    //绑定缓冲区
    glBindBuffer(GL_ARRAY_BUFFER, bufferID);
    //将顶点数组的数据copy到顶点缓冲区中
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    //从program中获取position 顶点属性
    GLuint position = glGetAttribLocation(self.program, "position");
    //开启顶点属性通道
    glEnableVertexAttribArray(position);
    //设置顶点读取方式
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 0);
    
    //从program中获取positionColor 颜色属性
    GLuint positionColor = glGetAttribLocation(self.program, "positionColor");
    //开启颜色属性通道
    glEnableVertexAttribArray(positionColor);
    //设置颜色读取方式
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 3);
    
    //从program中获取textCoordinate 纹理属性
    GLuint textCoordinate = glGetAttribLocation(self.program, "textCoordinate");
    //开启纹理属性通道
    glEnableVertexAttribArray(textCoordinate);
    //设置纹理读取方式
    glVertexAttribPointer(textCoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 6);
    
    //从program中获取投影矩阵 & 模型视图矩阵
    GLuint projectionMatrix_S = glGetUniformLocation(self.program, "projectionMatrix");
    GLuint modelViewMartix_S = glGetUniformLocation(self.program, "modelViewMatrix");
    
    //获取view宽高 计算宽高比
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    float aspect = width / height; //长宽比
    
    //创建 4*4 投影矩阵
    KSMatrix4 _projectionMatrix;
    //加载投影矩阵
    ksMatrixLoadIdentity(&_projectionMatrix);
    //获取透视矩阵
    /*
     参数1：矩阵
     参数2：视角，度数为单位
     参数3：纵横比
     参数4：近平面距离
     参数5：远平面距离
     */
    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 20.0f); //透视变换，视角30°
    //将投影矩阵传递到顶点着色器
    /*
     void glUniformMatrix4fv(GLint location,  GLsizei count,  GLboolean transpose,  const GLfloat *value);
     参数列表：
     location:指要更改的uniform变量的位置
     count:更改矩阵的个数
     transpose:是否要转置矩阵，并将它作为uniform变量的值。必须为GL_FALSE
     value:执行count个元素的指针，用来更新指定uniform变量
     */
    glUniformMatrix4fv(projectionMatrix_S, 1, GL_FALSE, (GLfloat*)&_projectionMatrix.m[0][0]);
    
    //模型视图矩阵
    KSMatrix4 _modelViewMatrix;
    //加载矩阵
    ksMatrixLoadIdentity(&_modelViewMatrix);
    //沿着z轴平移
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
    
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
    //开启正背面剔除
    glEnable(GL_CULL_FACE);
    //开启颜色混合
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    //加载纹理
    [self loadTexture:@"test"];
    //设置纹理采样器,这里的 0 对应 glBindTexture的 0
    glUniform1i(glGetUniformLocation(self.program, "colorMap"), 0);
    //使用索引绘图
    /*
     void glDrawElements(GLenum mode,GLsizei count,GLenum type,const GLvoid * indices);
     参数列表：
     mode:要呈现的画图的模型GL_POINTS、GL_LINES、GL_TRIANGLES等等
     count:绘图个数
     type:类型GL_BYTE、GL_UNSIGNED_BYTE、GL_SHORT、GL_UNSIGNED_SHORT、GL_INT、GL_UNSIGNED_INT
     indices：绘制索引数组
     */
    glDrawElements(GL_TRIANGLES, sizeof(indices) / sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
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

-(void)layoutSubviews{
    [super layoutSubviews];
    
    [self setupLayer];
    
    [self setupContext];
    
    [self deleteBuffers];
    
    [self setupRenderBuffer];
    
    [self setupFrameBuffer];
    
    [self draw];
    
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
    
    
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
