//
//  GPUImageMovie.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/7.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "GPUImageMovie.h"
#import "GPUImageColorConversion.h"

@interface GPUImageMovie ()<AVPlayerItemOutputPullDelegate>
{
    const GLfloat *_preferredConversion;
    BOOL isFullYUVRange;
    AVPlayerItemVideoOutput *playerItemOutput;
    int imageBufferWidth, imageBufferHeight;
    GLuint luminanceTexture, chrominanceTexture;
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
        self->_preferredConversion = kColorConversion709;
        self->isFullYUVRange = YES;
        
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
        __unsafe_unretained GPUImageMovie *weakSelf = self;
        CVPixelBufferRef pixelBuffer = [playerItemOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        if( pixelBuffer )
            runSynchronouslyOnVideoProcessingQueue(^{
                [weakSelf processMovieFrame:pixelBuffer withSampleTime:outputItemTime];
                CFRelease(pixelBuffer);
            });
    }
}

- (void)processMovieFrame:(CVPixelBufferRef)movieFrame withSampleTime:(CMTime)currentSampleTime
{
    int bufferHeight = (int) CVPixelBufferGetHeight(movieFrame);
    int bufferWidth = (int) CVPixelBufferGetWidth(movieFrame);
    
    CFTypeRef colorAttachments = CVBufferGetAttachment(movieFrame, kCVImageBufferYCbCrMatrixKey, NULL);
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
        [self convertYUVToRGBOutput];

        CVPixelBufferUnlockBaseAddress(movieFrame, 0);
        CFRelease(luminanceTextureRef);
        CFRelease(chrominanceTextureRef);
    }
}

- (void)convertYUVToRGBOutput
{
    NSLog(@"%s",__func__);
}

- (void)processPtsFrameBuffer:(double)senderInterval
{
    // Calculate the nextVsync time which is when the screen will be refreshed next.
    CMTime outputItemTime = [playerItemOutput itemTimeForHostTime:senderInterval];
    [self processPixelBufferAtTime:outputItemTime];
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
}

@end
