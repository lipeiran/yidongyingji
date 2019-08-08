//
//  LPRGPUImageFilter.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "LPRGPUImageFilter.h"

NSString *const kGPUImageVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 varying vec2 textureCoordinate;
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const kGPUImagePassthroughFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
 );

@implementation LPRGPUImageFilter
@synthesize texture_test = _texture_test;

- (id)initSize:(NSString *)imageName
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        GLProgram glProgram1;
        
        char *tmpV = (char *)[kGPUImageVertexShaderString UTF8String];
        char *tmpF = (char *)[kGPUImagePassthroughFragmentShaderString UTF8String];
        
        self->program = cpp_compileProgramWithContent(glProgram1, tmpV, tmpF);
        
        //从program中获取position 顶点属性
        self->filterPositionAttribute = glGetAttribLocation(self->program, "position");
        //从program中获取textCoordinate 纹理属性
        self->filterTextureCoordinateAttribute = glGetAttribLocation(self->program, "inputTextureCoordinate");
        self->filterInputTextureUniform = glGetUniformLocation(self->program, "inputImageTexture");

        [GPUImageContext useImageProcessingContext];
        glUseProgram(self->program);
        
        glEnableVertexAttribArray(self->filterPositionAttribute);
        glEnableVertexAttribArray(self->filterTextureCoordinateAttribute);
        
        self.outputFramebuffer = [[LPRGPUImageFrameBuffer alloc]initWithSize:CGSizeMake(480, 640)];

        GLubyte *byte = NULL;
        int w;
        int h;
        byte = [OpenGLES2DTools getImageDataWithName:imageName width:&w height:&h];
        
        self->_texture_test = cpp_setupTexture(GL_TEXTURE4);
        cpp_upGPUTexture(w, h, byte);
        
        [self renderToTexture];
    });
    
    return self;
}

#pragma mark -
#pragma mark Managing the display FBOs

- (void)renderToTexture
{
    static const GLfloat imageVerticesaa[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat noRotationTextureCoordinatesaa[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        glUseProgram(self->program);
        
        [self.outputFramebuffer activateFramebuffer];
        
        glClearColor(1.0, 1.0, 1.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, self->_texture_test);
        glUniform1i(self->filterInputTextureUniform, 2);
        
        glVertexAttribPointer(self->filterPositionAttribute, 2, GL_FLOAT, 0, 0, imageVerticesaa);
        glVertexAttribPointer(self->filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinatesaa);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    });
}

@end
