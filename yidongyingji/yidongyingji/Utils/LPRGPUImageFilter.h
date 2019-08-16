//
//  LPRGPUImageFilter.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPRGPUImageFrameBuffer.h"
#import "LPRGLProgram.h"
#import "LPRGPUImageContext.h"
#include "GPUImageContext.h"
#include "GLProgram.hpp"
#include "GLProgram.hpp"
#import "OpenGLES2DTools.h"
#import "GPUImage.hpp"
#import "GPUAnimateAttr.hpp"
#import "Parse_AE.h"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

NS_ASSUME_NONNULL_BEGIN

@interface LPRGPUImageFilter : NSObject
{
    LPRGPUImageFrameBuffer *firstInputFramebuffer;
    
    GLuint _frameBuffer;
    GLuint program;
    GLint filterPositionAttribute, filterTextureCoordinateAttribute;
    GLint filterInputTextureUniform;
    GLint _modelViewMartix_S;
    
    GLuint _texture[512];
    GLuint _texture_num;
    GPUImage *_imageAsset[512];
    GLuint _imageAsset_num;
    
    BOOL _ae_b;
}

@property (readonly) GLuint texture_test;
@property (retain) LPRGPUImageFrameBuffer *outputFramebuffer;
@property (nonatomic) CGSize texture_size;

- (id)initSize:(CGSize)size imageName:(nullable NSString *)imageName ae:(AEConfigEntity &)aeConfig;

- (void)renderToTexture:(int)fr;

@end

NS_ASSUME_NONNULL_END
