//
//  OpenGLESView.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/23.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "OpenGLES2DView.h"
#include "GLESMath.h"

//#ifdef __cplusplus
//extern "C" {
//#endif
//#include <libavcodec/avcodec.h>
//#include <libavformat/avformat.h>
//#include <libavutil/opt.h>
//#include <libswscale/swscale.h>
//#include <libavutil/imgutils.h>
//
//#ifdef __cplusplus
//}
//#endif

@interface OpenGLES2DView ()
{
    GLuint _program;
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _position;
    GLuint _textCoordinate;
    GLuint _modelViewMartix_S;
    CGRect _screenRect;
}
@property(atomic, assign) BOOL playFlag;
@property(atomic, assign) BOOL isInitContext;
@property(nonatomic, strong) EAGLContext *context;
@property(atomic, assign) BOOL isSurfaceChanged;


@property(atomic, assign) GLuint framebuffer;
@property(atomic, assign) GLuint colorRenderbuffer;
@property(atomic, assign) GLuint depthRenderbuffer;

@property(nonatomic, strong) NSThread *renderLoopThread;
@property(nonatomic, strong) CAEAGLLayer *layerPtr;
@property(nonatomic, strong) NSTimer *renderTimer;

@end

@implementation OpenGLES2DView

#pragma mark -
#pragma LifeCycle

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)dealloc
{
    self->filter.destropDisplayFrameBuffer();
}

- (void)layoutSubviews
{
    @synchronized (self)
    {
        [GPUImageContext useImageProcessingContext];
        runSynchronouslyOnVideoProcessingQueue(^{
            self->filter.destropDisplayFrameBuffer();
            [self createFrameBuffer];
        });
    }
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
    {
        return nil;
    }
    
    self.layer.opaque = YES;
    _layerPtr = (CAEAGLLayer *) self.layer;
    self.layer.opaque = YES;
    self.layer.contentsScale = [[UIScreen mainScreen] scale];
    ((CAEAGLLayer *) self.layer).drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: [NSNumber numberWithBool:YES],kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8};
    float scale = [UIScreen mainScreen].scale;
    _screenRect = CGRectMake(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    [self createFrameBuffer];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            self->_renderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/25 target:self selector:@selector(startQueue) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop]run];
        }
    });
    return self;
}

- (void)startQueue
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [self renderThreadFunc];
    });
}

- (void)renderThreadFunc
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        self->filter.draw();
        [[[GPUImageContext sharedImageProcessingContext] context] presentRenderbuffer:GL_RENDERBUFFER];
    });
}

- (void)createFrameBuffer
{
    self->filter.initWithProgram(_screenRect.origin.x,_screenRect.origin.y,_screenRect.size.width,_screenRect.size.height);
    int w1,h1,w2,h2,w3,h3,w4,h4;
    GLubyte *byte1 = NULL,*byte2 = NULL,*byte3 = NULL,*byte4 = NULL;
    byte1 = [OpenGLES2DTools getImageDataWithName:@"img_0.png" width:&w1 height:&h1];
    byte2 = [OpenGLES2DTools getImageDataWithName:@"img_1.png" width:&w2 height:&h2];
    byte3 = [OpenGLES2DTools getImageDataWithName:@"img_2.png" width:&w3 height:&h3];
    byte4 = [OpenGLES2DTools getImageDataWithName:@"img_3.png" width:&w4 height:&h4];
    GPUImage image1;
    image1.byte = byte1;
    image1.w = w1;
    image1.h = h1;
    GPUImage image2;
    image2.byte = byte2;
    image2.w = w2;
    image2.h = h2;
    GPUImage image3;
    image3.byte = byte3;
    image3.w = w3;
    image3.h = h3;
    GPUImage image4;
    image4.byte = byte4;
    image4.w = w4;
    image4.h = h4;
    char *configPath = (char *)[[[NSBundle mainBundle]pathForResource:@"tp" ofType:@"json"] UTF8String];
    
    self->filter.addImageAsset(image1);
    self->filter.addImageAsset(image2);
    self->filter.addImageAsset(image3);
    self->filter.addImageAsset(image4);
    self->filter.addConfigure(configPath);
    [[[GPUImageContext sharedImageProcessingContext] context] renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.layerPtr];
}

@end
