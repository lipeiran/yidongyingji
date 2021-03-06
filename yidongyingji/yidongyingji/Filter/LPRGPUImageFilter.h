//
//  LPRGPUImageFilter.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LPRGPUImageFrameBuffer.h"
#include "LPRGPUImageContext.h"
#include "GLProgram.hpp"
#import "LPRGPUImage.hpp"
#import "LPRGPUAnimateAttr.hpp"
#import "Parse_AE.h"
#import "Header.h"

NS_ASSUME_NONNULL_BEGIN

@interface LPRGPUImageFilter : NSObject
{
    GLuint _frameBuffer;
    GLuint program;
    GLint filterPositionAttribute, filterTextureCoordinateAttribute;
    GLint filterInputTextureUniform;
    GLint _modelViewMartix_S;
    
    GLuint _texture[512];
    GLuint _texture_num;
    LPRGPUImage *_imageAsset[512];
    GLuint _imageAsset_num;
}

@property (readonly) GLuint texture_test;
@property (retain) LPRGPUImageFrameBuffer *outputFramebuffer;
@property (nonatomic) CGSize texture_size;
@property (nonatomic, copy) NSString *resName;

- (id)initSize:(CGSize)size ae:(AEConfigEntity &)aeConfig camera:(AEConfigEntity &)cameraConfig withFileName:(NSString *)fileName;

- (void)renderToTexture:(int)fr;

@end

NS_ASSUME_NONNULL_END
