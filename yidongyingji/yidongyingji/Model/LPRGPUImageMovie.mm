//
//  GPUImageMovie.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/7.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "LPRGPUImageMovie.h"
#import "LPRGPUImageColorConversion.h"

@interface LPRGPUImageMovie ()<AVPlayerItemOutputPullDelegate>
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

@interface LPRGPUImageMovie ()
{
    CADisplayLink *displayLink;
    AVAssetReader *reader;
    AVAssetReaderOutput *_readerVideoTrackOutput;
    BOOL videoEncodingIsFinished;
    CMTime processingFrameTime;
}
@end

@implementation LPRGPUImageMovie

- (id)initWithAsset:(AVAsset *)asset;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    [self yuvConversionSetup];
    self.asset = asset;
    return self;
}

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
        [LPRGPUImageContext useImageProcessingContext];
        GLProgram glProgram;
        self->_preferredConversion = kColorConversion709;
        self->isFullYUVRange       = YES;
        char *tmpV = (char *)[kGPUImageVertexShaderString UTF8String];
        char *tmpF = (char *)[kGPUImageYUVFullRangeConversionForLAFragmentShaderString UTF8String];
 
        self->yuvConversionProgram = cpp_compileProgramWithContent(glProgram, tmpV, tmpF);
        
        self->yuvConversionPositionAttribute = glGetAttribLocation(self->yuvConversionProgram, "position");
        self->yuvConversionTextureCoordinateAttribute = glGetAttribLocation(self->yuvConversionProgram, "inputTextureCoordinate");
        self->yuvConversionLuminanceTextureUniform = glGetUniformLocation(self->yuvConversionProgram, "luminanceTexture");
        self->yuvConversionChrominanceTextureUniform = glGetUniformLocation(self->yuvConversionProgram, "chrominanceTexture");
        self->yuvConversionMatrixUniform = glGetUniformLocation(self->yuvConversionProgram, "colorConversionMatrix");
        
        [LPRGPUImageContext useImageProcessingContext];
        glUseProgram(self->yuvConversionProgram);

        glEnableVertexAttribArray(self->yuvConversionPositionAttribute);
        glEnableVertexAttribArray(self->yuvConversionTextureCoordinateAttribute);
        self.outputFramebuffer = [[LPRGPUImageFrameBuffer alloc]initWithSize:CGSizeMake(Draw_w, Draw_h)];
    });
}

- (BOOL)videoEncodingIsFinished
{
    return videoEncodingIsFinished;
}

- (void)startProcessing;
{
    if (self.playerItem)
    {
        [self processPlayerItem];
    }
    if (self.asset)
    {
        [self processAsset];
    }
}

- (void)endProcessing;
{
    
}

- (void)cancelProcessing;
{
    
}

- (void)processMovieFrame:(CMSampleBufferRef)movieSampleBuffer;
{
    CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(movieSampleBuffer);
    CVImageBufferRef movieFrame = CMSampleBufferGetImageBuffer(movieSampleBuffer);
    
    processingFrameTime = currentSampleTime;
    [self processMovieFrame:movieFrame withSampleTime:currentSampleTime];
}

- (BOOL)readNextVideoFrameFromOutput:(AVAssetReaderOutput *)readerVideoTrackOutput;
{
    if (reader.status == AVAssetReaderStatusReading && ! videoEncodingIsFinished)
    {
        CMSampleBufferRef sampleBufferRef = [readerVideoTrackOutput copyNextSampleBuffer];
        if (sampleBufferRef)
        {
            __unsafe_unretained LPRGPUImageMovie *weakSelf = self;
            runSynchronouslyOnVideoProcessingQueue(^{
                [weakSelf processMovieFrame:sampleBufferRef];
                CMSampleBufferInvalidate(sampleBufferRef);
                CFRelease(sampleBufferRef);
            });
            
            return YES;
        }
        else
        {
            videoEncodingIsFinished = YES;
            [self endProcessing];
        }
    }
    return NO;
}

- (BOOL)copyNextFrame
{
    BOOL success = NO;
    if (_readerVideoTrackOutput)
    {
        success = [self readNextVideoFrameFromOutput:_readerVideoTrackOutput];
    }
    return success;
}

- (void)processPixelBufferAtTime:(CMTime)outputItemTime
{
    if ([playerItemOutput hasNewPixelBufferForItemTime:outputItemTime] || self.not_check_new)
    {
        __unsafe_unretained LPRGPUImageMovie *weakSelf = self;
        CVPixelBufferRef pixelBuffer = [playerItemOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        if(pixelBuffer)
        {
            runSynchronouslyOnVideoProcessingQueue(^{
                [weakSelf processMovieFrame:pixelBuffer withSampleTime:outputItemTime];
                CFRelease(pixelBuffer);
            });
        }
    }
    else
    {
        int fail_c = 0;
        CMTime delta_jump = CMTimeMake(1, 100);
        while (1)
        {
            fail_c++;
            outputItemTime = CMTimeAdd(outputItemTime, delta_jump);
            if ([playerItemOutput hasNewPixelBufferForItemTime:outputItemTime] || self.not_check_new)
            {
                __unsafe_unretained LPRGPUImageMovie *weakSelf = self;
                CVPixelBufferRef pixelBuffer = [playerItemOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
                if(pixelBuffer)
                {
                    runSynchronouslyOnVideoProcessingQueue(^{
                        [weakSelf processMovieFrame:pixelBuffer withSampleTime:outputItemTime];
                        CFRelease(pixelBuffer);
                    });
                }
                break;
            }
            if (fail_c > 10)
            {
                break;
            }
        }
    }
}

- (void)processMovieFrame:(CVPixelBufferRef)movieFrame withSampleTime:(CMTime)currentSampleTime
{
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
    [LPRGPUImageContext useImageProcessingContext];

    CVOpenGLESTextureRef luminanceTextureRef = NULL;
    CVOpenGLESTextureRef chrominanceTextureRef = NULL;
    if (CVPixelBufferGetPlaneCount(movieFrame) > 0) // Check for YUV planar inputs to do RGB conversion
    {
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
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[LPRGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
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
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, [[LPRGPUImageContext sharedImageProcessingContext] coreVideoTextureCache], movieFrame, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth/2, bufferHeight/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &chrominanceTextureRef);
        if (err)
        {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        chrominanceTexture = CVOpenGLESTextureGetName(chrominanceTextureRef);
        glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        [self convertYUVToRGBOutput];

        CVPixelBufferUnlockBaseAddress(movieFrame, 0);
        CFRelease(luminanceTextureRef);
        CFRelease(chrominanceTextureRef);
    }
}

- (void)convertYUVToRGBOutput
{
    [LPRGPUImageContext useImageProcessingContext];
    glUseProgram(self->yuvConversionProgram);
    
    [self.outputFramebuffer activateFramebuffer];
    
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, luminanceTexture);
    glUniform1i(yuvConversionLuminanceTextureUniform, 4);
    
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
    glUniform1i(yuvConversionChrominanceTextureUniform, 5);
    
    glUniformMatrix3fv(yuvConversionMatrixUniform, 1, GL_FALSE, _preferredConversion);
    
    glVertexAttribPointer(yuvConversionPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices_lpr);
    glVertexAttribPointer(yuvConversionTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates_lpr);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glFinish();

}

- (void)processPtsFrameBufferWithTime:(CMTime)time
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [self processPixelBufferAtTimeWithTime:time];
    });
}

- (void)processPixelBufferAtTimeWithTime:(CMTime)time
{
    __unsafe_unretained LPRGPUImageMovie *weakSelf = self;
    CVPixelBufferRef pixelBuffer = [playerItemOutput copyPixelBufferForItemTime:time itemTimeForDisplay:NULL];
    if(pixelBuffer)
    {
        runSynchronouslyOnVideoProcessingQueue(^{
            [weakSelf processMovieFrame:pixelBuffer withSampleTime:time];
            CFRelease(pixelBuffer);
        });
    }
}

#pragma mark -
#pragma mark Private methods

- (void)processPlayerItem
{
    NSLog(@"%s",__func__);
    dispatch_queue_t videoProcessingQueue = [LPRGPUImageContext sharedContextQueue];
    NSMutableDictionary *pixBuffAttributes = [NSMutableDictionary dictionary];
    [pixBuffAttributes setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    playerItemOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
    [playerItemOutput setDelegate:self queue:videoProcessingQueue];

    [_playerItem addOutput:playerItemOutput];
    [playerItemOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:0.1];
}

- (void)processAsset
{
    NSLog(@"%s",__func__);
    reader = [self createAssetReader];

    AVAssetReaderOutput *readerVideoTrackOutput = nil;
    for( AVAssetReaderOutput *output in reader.outputs )
    {
        if( [output.mediaType isEqualToString:AVMediaTypeVideo] )
        {
            readerVideoTrackOutput = output;
            _readerVideoTrackOutput = readerVideoTrackOutput;
        }
    }
    if ([reader startReading] == NO)
    {
        return;
    }
    
    [self readNextVideoFrameFromOutput:readerVideoTrackOutput];
}

- (AVAssetReader *)createAssetReader
{
    NSLog(@"%s",__func__);
    NSError *error = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:self.asset error:&error];
    
    NSMutableDictionary *outputSettings = [NSMutableDictionary dictionary];
    if ([LPRGPUImageContext supportsFastTextureUpload])
    {
        [outputSettings setObject:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        isFullYUVRange = YES;
    }
    
    // Maybe set alwaysCopiesSampleData to NO on iOS 5.0 for faster video decoding
    AVAssetReaderTrackOutput *readerVideoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:[[self.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] outputSettings:outputSettings];
    readerVideoTrackOutput.alwaysCopiesSampleData = NO;
    [assetReader addOutput:readerVideoTrackOutput];
    
    return assetReader;
}

#pragma mark -
#pragma mark AVPlayerItemOutputPullDelegate

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
    NSLog(@"%s",__func__);
    self.data_ready = true;
}

@end
