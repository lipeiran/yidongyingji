//
//  GPUImageContext.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/6.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <OpenGLES/EAGL.h>

NS_ASSUME_NONNULL_BEGIN

@class LPRGPUImageContext;

#ifdef __cplusplus
extern "C" {
#endif
    void runSynchronouslyOnVideoProcessingQueue(void (^block)(void));
    void runAsynchronouslyOnVideoProcessingQueue(void (^block)(void));
    void runSynchronouslyOnContextQueue(LPRGPUImageContext *context, void (^block)(void));
    void runAsynchronouslyOnContextQueue(LPRGPUImageContext *context, void (^block)(void));

#ifdef __cplusplus
}
#endif

@interface LPRGPUImageContext : NSObject

@property (nonatomic, readonly) dispatch_queue_t contextQueue;

@property (nonatomic, retain, readonly) EAGLContext *context;

@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;

+ (void *)contextKey;

+ (LPRGPUImageContext *)sharedImageProcessingContext;

+ (dispatch_queue_t)sharedContextQueue;

+ (void)useImageProcessingContext;

// 为了后续和安卓统一C++代码标记
+ (BOOL)supportsFastTextureUpload;

- (void)useAsCurrentContext;

- (void)useSharegroup:(EAGLSharegroup *)sharegroup;

@end

NS_ASSUME_NONNULL_END
