//
//  utils.hpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/23.
//  Copyright © 2019 李沛然. All rights reserved.
//

#ifndef utils_hpp
#define utils_hpp

#include <stdio.h>
#include <stdlib.h>
#include "GL_Header.h"
#include "GLESMath.h"

class GLProgram;

// 加载文件
char * LoadFileContent(const char*path, long&filesize);

// 创建BufferObject
GLuint cpp_createBufferObject(GLenum bufferType, GLsizeiptr size, GLenum usage, void*data = nullptr);

// 创建FBO
GLuint cpp_setupFrameBuffer();

// 创建RBO
GLuint cpp_setupRenderBuffer();

// 创建纹理
GLuint cpp_setupTexture(GLenum texture);

// 上传GPU纹理数据
void cpp_upGPUTexture(GLint width, GLint height, GLubyte *byte);

// 编译program
GLuint cpp_compileProgram(GLProgram program, char *vertexPath, char *fragmentPath);

// 编译program
GLuint cpp_compileProgramWithContent(GLProgram program, char *vertexContent, char *fragmentContent);

// 旋转
void cpp_glRotate(float anchorX,float anchorY, float xDegree, float yDegree, float zDegree, KSMatrix4 &sourceMatrix);

// 缩放
void cpp_glScale(float anchorX,float anchorY, float xScale, float yScale, float zScale, KSMatrix4 &sourceMatrix);

#endif /* utils_hpp */
