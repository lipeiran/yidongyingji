//
//  GPUImageContext.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/6.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "GPUImageContext.h"

@implementation GPUImageContext
@synthesize context = _context;
@synthesize coreVideoTextureCache = _coreVideoTextureCache;

static void *openGLESContextQueueKey;

- (instancetype)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    openGLESContextQueueKey = &openGLESContextQueueKey;
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
    _contextQueue = dispatch_queue_create("com.lipeiran.GPUImage.openGLESContextQueue", attr);
    dispatch_queue_set_specific(_contextQueue, openGLESContextQueueKey, (__bridge void *)self, NULL);
    return self;
}

- (void)dealloc
{
}

- (CVOpenGLESTextureCacheRef)coreVideoTextureCache
{
    if (_coreVideoTextureCache == NULL)
    {
#if defined(__IPHONE_6_0)
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [self context], NULL, &_coreVideoTextureCache);
#else
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[self context], NULL, &_coreVideoTextureCache);
#endif
        if (err)
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
    }
    return _coreVideoTextureCache;
}

+ (void *)contextKey
{
    return openGLESContextQueueKey;
}

+ (GPUImageContext *)sharedImageProcessingContext
{
    static dispatch_once_t pred;
    static GPUImageContext *sharedImageProcessingContext = nil;
    
    dispatch_once(&pred, ^{
        sharedImageProcessingContext = [[[self class] alloc] init];
    });
    return sharedImageProcessingContext;
}

+ (dispatch_queue_t)sharedContextQueue
{
    return [[self sharedImageProcessingContext] contextQueue];
}

+ (void)useImageProcessingContext
{
    [[GPUImageContext sharedImageProcessingContext] useAsCurrentContext];
}

- (void)useAsCurrentContext
{
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext)
    {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
}

- (EAGLContext *)context
{
    if (_context == nil)
    {
        _context = [self createContext];
        [EAGLContext setCurrentContext:_context];
        glEnable(GL_DEPTH_TEST);
    }
    return _context;
}

- (EAGLContext *)createContext
{
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
    return context;
}

@end
