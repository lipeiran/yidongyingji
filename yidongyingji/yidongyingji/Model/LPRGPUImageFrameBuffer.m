//
//  LPRGPUImageFrameBuffer.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "LPRGPUImageFrameBuffer.h"

@interface LPRGPUImageFrameBuffer ()
{
    GLuint framebuffer;
    
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;
}

@end

@implementation LPRGPUImageFrameBuffer
@synthesize size = _size;
@synthesize texture = _texture;

- (id)initWithSize:(CGSize)framebufferSize
{
    if (!(self = [super init]))
    {
        return nil;
    }
    _size = framebufferSize;
    [self generateFramebuffer];
    return self;
}

- (void)generateTexture;
{
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // TODO: Handle mipmaps
}

- (void)generateFramebuffer;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [LPRGPUImageContext useImageProcessingContext];
        
        glGenFramebuffers(1, &self->framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, self->framebuffer);
        
        // By default, all framebuffers on iOS 5.0+ devices are backed by texture caches, using one shared cache
        if ([LPRGPUImageContext supportsFastTextureUpload])
        {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            CVOpenGLESTextureCacheRef coreVideoTextureCache = [[LPRGPUImageContext sharedImageProcessingContext] coreVideoTextureCache];
            // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
            
            CFDictionaryRef empty; // empty value for attr value.
            CFMutableDictionaryRef attrs;
            empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
            attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
            
            CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)self->_size.width, (int)self->_size.height, kCVPixelFormatType_32BGRA, attrs, &self->renderTarget);
            if (err)
            {
                NSLog(@"FBO size: %f, %f", self->_size.width, self->_size.height);
                NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
            }
            
            err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, coreVideoTextureCache, self->renderTarget,
                                                                NULL, // texture attributes
                                                                GL_TEXTURE_2D,
                                                                GL_RGBA, // opengl format
                                                                (int)self->_size.width,
                                                                (int)self->_size.height,
                                                                GL_BGRA, // native iOS format
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &self->renderTexture);
            if (err)
            {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            CFRelease(attrs);
            CFRelease(empty);
            
            glBindTexture(CVOpenGLESTextureGetTarget(self->renderTexture), CVOpenGLESTextureGetName(self->renderTexture));
            self->_texture = CVOpenGLESTextureGetName(self->renderTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(self->renderTexture), 0);
#endif
        }
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

- (void)destroyFramebuffer;
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [LPRGPUImageContext useImageProcessingContext];
        if (self->framebuffer)
        {
            glDeleteFramebuffers(1, &self->framebuffer);
            self->framebuffer = 0;
        }
        glDeleteTextures(1, &self->_texture);
    });
}

#pragma mark -
#pragma mark Usage

- (void)activateFramebuffer;
{
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glViewport(0, 0, (int)_size.width, (int)_size.height);
}

- (GLuint)texture;
{
    return _texture;
}

@end
