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

#ifdef __cplusplus
extern "C" {
#endif
    void runSynchronouslyOnVideoProcessingQueue(void (^block)(void));
    void runAsynchronouslyOnVideoProcessingQueue(void (^block)(void));
    
#ifdef __cplusplus
}
#endif

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

@interface GPUImageContext : NSObject

@property (nonatomic, readonly) dispatch_queue_t contextQueue;

@property (nonatomic, retain, readonly) EAGLContext *context;

@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;

+ (void *)contextKey;

+ (GPUImageContext *)sharedImageProcessingContext;

+ (dispatch_queue_t)sharedContextQueue;

+ (void)useImageProcessingContext;

- (void)useAsCurrentContext;

@end

NS_ASSUME_NONNULL_END
