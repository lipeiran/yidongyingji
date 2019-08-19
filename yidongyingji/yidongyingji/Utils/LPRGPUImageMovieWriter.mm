//
//  LPRGPUImageMovieWriter.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/17.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "LPRGPUImageMovieWriter.h"

@interface LPRGPUImageMovieWriter ()
{
    GLuint movieRenderbuffer, movieFramebuffer;
    
    GLint moviePositionAttribute, movieTextureCoordinateAttribute;
    GLint movieInputTextureUniform;
    
    CGSize boundsSizeAtFrameBufferEpoch;
    
    GLuint _program;
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _position;
    GLuint _textCoordinate;
    
    GLuint _texture_test;
    GLuint _texture_test2;
    
    BOOL _layer_exist;
    int _fr;
    BOOL _slider_bool;
    AEConfigEntity configEntity;
}

@end

@implementation LPRGPUImageMovieWriter

@synthesize movieWriterContext = _movieWriterContext;

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize;
{
    return [self initWithMovieURL:newMovieURL size:newSize fileType:AVFileTypeQuickTimeMovie outputSettings:nil];
}

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize fileType:(NSString *)newFileType outputSettings:(NSMutableDictionary *)outputSettings;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    videoSize = newSize;
    movieURL = newMovieURL;
    fileType = newFileType;
    
    _movieWriterContext = [[GPUImageContext alloc] init];
    [_movieWriterContext useSharegroup:[[[GPUImageContext sharedImageProcessingContext] context] sharegroup]];
    
    runSynchronouslyOnContextQueue(_movieWriterContext, ^{
        [self->_movieWriterContext useAsCurrentContext];
        
        if ([GPUImageContext supportsFastTextureUpload])
        {
            GLProgram glProgram1;
            //编译program
            char *tmpV = (char *)[kSamplingVertexShaderC_lpr UTF8String];
            char *tmpF = (char *)[kPassThroughFragmentShaderC_lpr UTF8String];
            self->_program = cpp_compileProgramWithContent(glProgram1, tmpV, tmpF);
        }
        else
        {
            GLProgram glProgram1;
            //编译program
            char *tmpV = (char *)[kSamplingVertexShaderC_lpr UTF8String];
            char *tmpF = (char *)[kColorSwizzlingFragmentShaderC_lpr UTF8String];
            self->_program = cpp_compileProgramWithContent(glProgram1, tmpV, tmpF);
        }
        //从program中获取position 顶点属性
        self->moviePositionAttribute = glGetAttribLocation(self->_program, "position");
        //从program中获取textCoordinate 纹理属性
        self->movieTextureCoordinateAttribute = glGetAttribLocation(self->_program, "inputTextureCoordinate");
        self->movieInputTextureUniform = glGetUniformLocation(self->_program, "inputImageTexture");
        [self->_movieWriterContext useAsCurrentContext];
        glUseProgram(self->_program);
        glEnableVertexAttribArray(self->moviePositionAttribute);
        glEnableVertexAttribArray(self->movieTextureCoordinateAttribute);
    });
    
    [self commonInit:outputSettings];

    return self;
}

- (void)commonInit:(NSDictionary *)settings;
{
    NSLog(@"%s",__func__);
    NSError *error = nil;
    assetWriter = [[AVAssetWriter alloc]initWithURL:movieURL fileType:fileType error:&error];
    if (error != nil)
    {
        NSLog(@"error is:%@\n",error);
    }
//    assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, 1000);

    if (settings == nil)
    {
        NSMutableDictionary *setting = [[NSMutableDictionary alloc]init];
        [setting setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
        [setting setObject:[NSNumber numberWithInt:videoSize.width] forKey:AVVideoWidthKey];
        [setting setObject:[NSNumber numberWithInt:videoSize.height] forKey:AVVideoHeightKey];
        settings = setting;
    }
    else
    {
        __unused NSString *videoCodec = [settings objectForKey:AVVideoCodecKey];
        __unused NSNumber *width = [settings objectForKey:AVVideoWidthKey];
        __unused NSNumber *height = [settings objectForKey:AVVideoHeightKey];
        
        NSAssert(videoCodec && width && height, @"OutputSettings is missing required parameters.");
    }
    assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    assetWriterVideoInput.expectsMediaDataInRealTime = NO;
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],kCVPixelBufferPixelFormatTypeKey,[NSNumber numberWithInt:videoSize.width], kCVPixelBufferWidthKey,[NSNumber numberWithInt:videoSize.height],kCVPixelBufferHeightKey,nil];
    assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    [assetWriter addInput:assetWriterVideoInput];
}

- (void)createDataFBO
{
    NSLog(@"%s",__func__);
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &movieFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    
    if ([GPUImageContext supportsFastTextureUpload])
    {
        CVPixelBufferPoolCreatePixelBuffer(NULL, [assetWriterPixelBufferInput pixelBufferPool], &renderTarget);
        
        CVBufferSetAttachment(renderTarget, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
        CVBufferSetAttachment(renderTarget, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_601_4, kCVAttachmentMode_ShouldPropagate);
        CVBufferSetAttachment(renderTarget, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
        
        CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [_movieWriterContext coreVideoTextureCache], renderTarget,
                                                      NULL, // texture attributes
                                                      GL_TEXTURE_2D,
                                                      GL_RGBA, // opengl format
                                                      (int)videoSize.width,
                                                      (int)videoSize.height,
                                                      GL_BGRA, // native iOS format
                                                      GL_UNSIGNED_BYTE,
                                                      0,
                                                      &renderTexture);
        
        glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
    }
    else
    {
        glGenRenderbuffers(1, &movieRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, movieRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, (int)videoSize.width, (int)videoSize.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, movieRenderbuffer);
    }
    __unused GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
}

- (void)setFilterFBO
{
    if (!movieFramebuffer)
    {
        [self createDataFBO];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    glViewport(0, 0, Draw_w, Draw_h);
}

- (void)destroyDataFBO;
{
    runSynchronouslyOnContextQueue(_movieWriterContext, ^{
        [self->_movieWriterContext useAsCurrentContext];
        
        if (self->movieFramebuffer)
        {
            glDeleteFramebuffers(1, &self->movieFramebuffer);
            self->movieFramebuffer = 0;
        }
        
        if (self->movieRenderbuffer)
        {
            glDeleteRenderbuffers(1, &self->movieRenderbuffer);
            self->movieRenderbuffer = 0;
        }
        
        if ([GPUImageContext supportsFastTextureUpload])
        {
            if (self->renderTexture)
            {
                CFRelease(self->renderTexture);
            }
            if (self->renderTarget)
            {
                CVPixelBufferRelease(self->renderTarget);
            }
        }
    });
}

- (void)renderAtInternalSizeUsingTexture:(GLuint)textureId
{
    [_movieWriterContext useAsCurrentContext];
    [self setFilterFBO];
    
    glUseProgram(_program);
    
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // This needs to be flipped to write out to video correctly
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat textureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glUniform1i(movieInputTextureUniform, 4);

    glVertexAttribPointer(moviePositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(movieTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFinish();
}

- (void)startRecording
{
    NSLog(@"%s",__func__);
    
}

- (void)stopRecording
{
    NSLog(@"%s",__func__);

}

@end
