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

class GLProgram;

char * LoadFileContent(const char*path, long&filesize);

GLuint cpp_createBufferObject(GLenum bufferType, GLsizeiptr size, GLenum usage, void*data = nullptr);

GLuint cpp_setupFrameBuffer();

GLuint cpp_setupRenderBuffer();

GLuint cpp_setupTexture(GLenum texture);

void cpp_upGPUTexture(GLint width, GLint height, GLubyte *byte);

GLuint cpp_compileProgram(GLProgram program, char *vertexPath, char *fragmentPath);

GLuint cpp_compileProgramWithContent(GLProgram program, char *vertexContent, char *fragmentContent);

#endif /* utils_hpp */
