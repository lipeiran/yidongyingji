//
//  LPRGPUImageContext.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "LPRGPUImageContext.h"

@interface LPRGPUImageContext()
{
    NSMutableDictionary *shaderProgramCache;
    NSMutableArray *shaderProgramUsageHistory;
    EAGLSharegroup *_sharegroup;
}

@end

@implementation LPRGPUImageContext

static void *openGLESContextQueueKey_lpr;

- (id)init;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
    openGLESContextQueueKey_lpr = &openGLESContextQueueKey_lpr;
    _contextQueue = dispatch_queue_create("com.sunsetlakesoftware.GPUImage.openGLESContextQueue", attr);
    dispatch_queue_set_specific(_contextQueue, openGLESContextQueueKey_lpr, (__bridge void *)self, NULL);
    
    shaderProgramCache = [[NSMutableDictionary alloc] init];
    shaderProgramUsageHistory = [[NSMutableArray alloc] init];
    return self;
}

+ (void *)contextKey
{
    return openGLESContextQueueKey_lpr;
}

+ (LPRGPUImageContext *)sharedImageProcessingContext
{
    static dispatch_once_t pred;
    static LPRGPUImageContext *sharedImageProcessingContext = nil;
    
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
    [[LPRGPUImageContext sharedImageProcessingContext] useAsCurrentContext];
}

- (void)useAsCurrentContext
{
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext)
    {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
}

+ (void)setActiveShaderProgram:(LPRGLProgram *)shaderProgram
{
    LPRGPUImageContext *sharedContext = [LPRGPUImageContext sharedImageProcessingContext];
    [sharedContext setContextShaderProgram:shaderProgram];
}

- (void)setContextShaderProgram:(LPRGLProgram *)shaderProgram
{
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext)
    {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
    
    if (self.currentShaderProgram != shaderProgram)
    {
        self.currentShaderProgram = shaderProgram;
        [shaderProgram use];
    }
}

- (void)presentBufferForDisplay
{
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (LPRGLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;
{
    NSString *lookupKeyForShaderProgram = [NSString stringWithFormat:@"V: %@ - F: %@", vertexShaderString, fragmentShaderString];
    LPRGLProgram *programFromCache = [shaderProgramCache objectForKey:lookupKeyForShaderProgram];
    if (programFromCache == nil)
    {
        programFromCache = [[LPRGLProgram alloc] initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        [shaderProgramCache setObject:programFromCache forKey:lookupKeyForShaderProgram];
    }
    
    return programFromCache;
}

@end
