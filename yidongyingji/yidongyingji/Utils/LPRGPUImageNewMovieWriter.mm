//
//  LPRGPUImageMovieWriter.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/17.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "LPRGPUImageNewMovieWriter.h"

@interface LPRGPUImageNewMovieWriter ()
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
    
    LPRGPUImageFrameBuffer *myFrameBuffer;
}

@end

@implementation LPRGPUImageNewMovieWriter


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
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        
        if ([GPUImageContext supportsFastTextureUpload])
        {
            GLProgram glProgram1;
            //编译program
            char *tmpV = (char *)[kSamplingVertexShaderC_lpr UTF8String];
            char *tmpF = (char *)[kPassThroughFragmentShaderC_lpr UTF8String];
            self->_program = cpp_compileProgramWithContent(glProgram1, tmpV, tmpF);
        }
        
        //从program中获取position 顶点属性
        self->moviePositionAttribute = glGetAttribLocation(self->_program, "position");
        //从program中获取textCoordinate 纹理属性
        self->movieTextureCoordinateAttribute = glGetAttribLocation(self->_program, "inputTextureCoordinate");
        self->movieInputTextureUniform = glGetUniformLocation(self->_program, "inputImageTexture");
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
        
        CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache], renderTarget,
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
    runSynchronouslyOnVideoProcessingQueue(^{
        [[GPUImageContext sharedImageProcessingContext] useAsCurrentContext];
        
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

- (void)renderAtInternalSizeUsingTexture:(LPRGPUImageFrameBuffer *)textureId
{
    [GPUImageContext useImageProcessingContext];
    [self setFilterFBO];
    glUseProgram(_program);
    
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);

    static const GLfloat squareVertices[] = {
        -0.5f, -0.5f,
        0.5f, -0.5f,
        -0.5f,  0.5f,
        0.5f,  0.5f,
    };
    
    static const GLfloat textureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, [textureId texture]);
    glUniform1i(movieInputTextureUniform, 4);
    
    glVertexAttribPointer(moviePositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(movieTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glFinish();
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

- (void)startRecording
{
    self->imageFilter = [[LPRGPUImageFilter alloc]initSize:CGSizeMake(Draw_w, Draw_h) imageName:@"img_1.png" ae:self->configEntity];
    [self->imageFilter renderToTexture:60];
    myFrameBuffer = self->imageFilter.outputFramebuffer;
    
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:CMTimeMake(0, 30)];
    
    LPRGPUImageFrameBuffer *inputFramebufferForBlock = myFrameBuffer;
    glFinish();
    
    // Render the frame with swizzled colors, so that they can be uploaded quickly as BGRA frames
    [GPUImageContext useImageProcessingContext];
    [self renderAtInternalSizeUsingTexture:inputFramebufferForBlock];
    
    GLubyte * rawImagePixels = (GLubyte *)malloc(videoSize.width * videoSize.height * 4);
    glReadPixels(0, 0, videoSize.width, videoSize.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/abc2.rgb"];
    unlink(pathToMovie.UTF8String);
    FILE *dst_file = fopen(pathToMovie.UTF8String, "wb");
    fwrite(rawImagePixels, 1, videoSize.width*4*videoSize.height, dst_file);
    fclose(dst_file);
    NSLog(@"end");
    
    return;
}

- (void)stopRecording
{
    NSLog(@"%s",__func__);
    
}

@end
