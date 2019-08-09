//
//  GPUImageMovie.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/7.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "GPUImageMovie.h"
#import "GPUImageColorConversion.h"

NSString *const kGPUImageVertexShaderString_movie = SHADER_STRING
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


@interface GPUImageMovie ()<AVPlayerItemOutputPullDelegate>
{
    const GLfloat *_preferredConversion;
    BOOL isFullYUVRange;
    AVPlayerItemVideoOutput *playerItemOutput;
    int imageBufferWidth, imageBufferHeight;
    GLuint luminanceTexture, chrominanceTexture;
    
    GLint yuvConversionProgram;
    
    GLint yuvConversionPositionAttribute, yuvConversionTextureCoordinateAttribute;
    GLint yuvConversionLuminanceTextureUniform, yuvConversionChrominanceTextureUniform;
    GLint yuvConversionMatrixUniform;
}

@end

@interface GPUImageMovie ()
{
    CVPixelBufferRef pixelBuffer;
}
@end

@implementation GPUImageMovie

- (id)initWithPlayerItem:(AVPlayerItem *)playerItem
{
    if (!(self = [super init]))
    {
        return nil;
    }
    [self yuvConversionSetup];
    self.playerItem = playerItem;
    return self;
}

- (void)yuvConversionSetup
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        GLProgram glProgram;
        self->_preferredConversion = kColorConversion709;
        self->isFullYUVRange       = YES;
        char *tmpV = (char *)[kGPUImageVertexShaderString_movie UTF8String];
        char *tmpF = (char *)[kGPUImageYUVFullRangeConversionForLAFragmentShaderString UTF8String];
 
        self->yuvConversionProgram = cpp_compileProgramWithContent(glProgram, tmpV, tmpF);
        
        self->yuvConversionPositionAttribute = glGetAttribLocation(self->yuvConversionProgram, "position");
        self->yuvConversionTextureCoordinateAttribute = glGetAttribLocation(self->yuvConversionProgram, "inputTextureCoordinate");
        self->yuvConversionLuminanceTextureUniform = glGetUniformLocation(self->yuvConversionProgram, "luminanceTexture");
        self->yuvConversionChrominanceTextureUniform = glGetUniformLocation(self->yuvConversionProgram, "chrominanceTexture");
        self->yuvConversionMatrixUniform = glGetUniformLocation(self->yuvConversionProgram, "colorConversionMatrix");
        
        [GPUImageContext useImageProcessingContext];
        glUseProgram(self->yuvConversionProgram);

        glEnableVertexAttribArray(self->yuvConversionPositionAttribute);
        glEnableVertexAttribArray(self->yuvConversionTextureCoordinateAttribute);
        self.outputFramebuffer = [[LPRGPUImageFrameBuffer alloc]initWithSize:CGSizeMake(480, 640)];
    });
}

- (void)startProcessing;
{
    if (self.playerItem)
    {
        [self processPlayerItem];
    }
}

- (void)endProcessing;
{
    
}

- (void)cancelProcessing;
{
    
}

- (BOOL)copyNextFrame;
{
    return YES;
}

- (void)processPixelBufferAtTime:(CMTime)outputItemTime
{
    if ([playerItemOutput hasNewPixelBufferForItemTime:outputItemTime])
    {
        if (pixelBuffer)
        {
            CFRelease(pixelBuffer);
        }

        NSLog(@"self pts is3:%d.\n",self.pts);
        __unsafe_unretained GPUImageMovie *weakSelf = self;
        pixelBuffer = [playerItemOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        if( pixelBuffer )
        {
            runSynchronouslyOnVideoProcessingQueue(^{
                [weakSelf processMovieFrame:weakSelf->pixelBuffer withSampleTime:outputItemTime];
            });
        }
    }
    else
    {
        NSLog(@"self pts 这里没有数据!!!!!:%d.\n",self.pts);
        __unsafe_unretained GPUImageMovie *weakSelf = self;
        if( pixelBuffer )
        {
            runSynchronouslyOnVideoProcessingQueue(^{
                [weakSelf processMovieFrame:weakSelf->pixelBuffer withSampleTime:outputItemTime];
            });
        }
    }
}

- (void)processMovieFrame:(CVPixelBufferRef)movieFrame withSampleTime:(CMTime)currentSampleTime
{
    NSLog(@"self pts is5:%d.\n",self.pts);

    int bufferHeight = (int) CVPixelBufferGetHeight(movieFrame);
    int bufferWidth = (int) CVPixelBufferGetWidth(movieFrame);
    
    CFStringRef colorAttachments = (CFStringRef)CVBufferGetAttachment(movieFrame, kCVImageBufferYCbCrMatrixKey, NULL);
    if (colorAttachments != NULL)
    {
        if(CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo)
        {
            if (isFullYUVRange)
            {
                _preferredConversion = kColorConversion601FullRange;
            }
            else
            {
                _preferredConversion = kColorConversion601;
            }
        }
        else
        {
            _preferredConversion = kColorConversion709;
        }
    }
    else
    {
        if (isFullYUVRange)
        {
            _preferredConversion = kColorConversion601FullRange;
        }
        else
        {
            _preferredConversion = kColorConversion601;
        }
    }
    [GPUImageContext useImageProcessingContext];

    CVOpenGLESTextureRef luminanceTextureRef = NULL;
    CVOpenGLESTextureRef chrominanceTextureRef = NULL;
    if (CVPixelBufferGetPlaneCount(movieFrame) > 0) // Check for YUV planar inputs to do RGB conversion
    {
        NSLog(@"%s",__func__);
        // fix issue 2221
        CVPixelBufferLockBaseAddress(movieFrame,0);
        if ( (imageBufferWidth != bufferWidth) && (imageBufferHeight != bufferHeight) )
        {
            imageBufferWidth = bufferWidth;
            imageBufferHeight = bufferHeight;
        }
        
        CVReturn err;
        // Y-plane
        glActiveTexture(GL_TEXTURE4);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
        if (err)
        {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        luminanceTexture = CVOpenGLESTextureGetName(luminanceTextureRef);
        glBindTexture(GL_TEXTURE_2D, luminanceTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        // UV-plane
        glActiveTexture(GL_TEXTURE5);
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
        if (err)
        {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef);
        glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        NSLog(@"self pts is6:%d.\n",self.pts);

        [self convertYUVToRGBOutput];

        CVPixelBufferUnlockBaseAddress(movieFrame, 0);
        CFRelease(luminanceTextureRef);
        CFRelease(chrominanceTextureRef);
    }
}

- (void)convertYUVToRGBOutput
{
    NSLog(@"%s",__func__);
    [GPUImageContext useImageProcessingContext];
    glUseProgram(self->yuvConversionProgram);
    
    [self.outputFramebuffer activateFramebuffer];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
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
    glBindTexture(GL_TEXTURE_2D, luminanceTexture);
    glUniform1i(yuvConversionLuminanceTextureUniform, 4);
    
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
    glUniform1i(yuvConversionChrominanceTextureUniform, 5);
    
    glUniformMatrix3fv(yuvConversionMatrixUniform, 1, GL_FALSE, _preferredConversion);
    
    glVertexAttribPointer(yuvConversionPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(yuvConversionTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)processPtsFrameBuffer
{
    CMTime outputItemTime = CMTimeMake(self.pts, 25);
//    CMTime outputItemTime = CMTimeMake(252, 25);
    NSLog(@"self pts is1:%d.\n",self.pts);
//    runAsynchronouslyOnVideoProcessingQueue(^{
        runSynchronouslyOnVideoProcessingQueue(^{
            NSLog(@"self pts is2:%d.\n",self.pts);
            [self processPixelBufferAtTime:outputItemTime];
        });
//    });
}

#pragma mark -
#pragma mark Private methods

- (void)processPlayerItem
{
    NSLog(@"%s",__func__);
    dispatch_queue_t videoProcessingQueue = [GPUImageContext sharedContextQueue];
    NSMutableDictionary *pixBuffAttributes = [NSMutableDictionary dictionary];
    [pixBuffAttributes setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    playerItemOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
    [playerItemOutput setDelegate:self queue:videoProcessingQueue];

    [_playerItem addOutput:playerItemOutput];
    [playerItemOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:0.1];
}

#pragma mark -
#pragma mark AVPlayerItemOutputPullDelegate

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
    NSLog(@"%s",__func__);
    self.data_ready = true;
}





@end
