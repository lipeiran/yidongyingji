//
//  GLESUtils.h
//
//  Created by kesalin@gmail.com on 12-11-25.
//  Copyright (c) 2012 年 http://blog.csdn.net/kesalin/. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OpenGLES/ES2/gl.h>
#import <UIKit/UIKit.h>

@interface GLESUtils : NSObject

+ (GLuint)loadShader:(GLenum)type withString:(NSString *)shaderString;

+ (GLuint)loadShader:(GLenum)type withFilepath:(NSString *)shaderFilepath;

+ (GLuint)loadProgram:(NSString *)vertexShaderFilepath withFragmentShaderFilepath:(NSString *)fragmentShaderFilepath;

+ (GLubyte *)getImageDataWithName:(NSString *)imageName width:(int*)width height:(int*)height;

@end
