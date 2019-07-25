//
//  utils.cpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/23.
//  Copyright © 2019 李沛然. All rights reserved.
//

#include "utils.hpp"
#include "GLProgram.hpp"

char * LoadFileContent(const char*path, long&filesize)
{
    FILE *f;
    long len;
    char *data;
    f=fopen(path,"rb");
    fseek(f,0,SEEK_END);
    len=ftell(f);
    fseek(f,0,SEEK_SET);
    data=(char*)malloc(len+1);
    filesize = len;
    fread(data,1,len,f);
    fclose(f);
    return data;
}

GLuint cpp_createBufferObject(GLenum bufferType,GLsizeiptr size,GLenum usage,void * data/* = nullptr*/)
{
    GLuint bufferID;
    glGenBuffers(1, &bufferID);
    glBindBuffer(bufferType, bufferID);
    glBufferData(bufferType, size, data, usage);
    glBindBuffer(bufferType, 0);
    return bufferID;
}

GLuint cpp_setupFrameBuffer()
{
    // 定义标识符ID
    GLuint bufferID;
    // glGenFrameBuffers申请标识符
    glGenFramebuffers(1, &bufferID);
    // 绑定缓冲区glBindFrameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, bufferID);
    return bufferID;
}

GLuint cpp_setupRenderBuffer()
{
    // 定义标识符ID
    GLuint bufferID;
    // glGenRenderBuffers 申请标识符
    glGenRenderbuffers(1, &bufferID);
    // 绑定缓冲区，注意此处为glBindRenderBuffer，不是glBindBuffer
    glBindRenderbuffer(GL_RENDERBUFFER, bufferID);
    return bufferID;
}

GLuint cpp_setupTexture(GLenum texture)
{
    GLuint tmpTexture = 0;
    glActiveTexture(texture);
    glGenTextures(1, &tmpTexture);
    glBindTexture(GL_TEXTURE_2D, tmpTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    return tmpTexture;
}

void cpp_upGPUTexture(GLint width, GLint height, GLubyte *byte)
{
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, byte);
}

GLuint cpp_compileProgram(GLProgram program, char *vertexPath, char *fragmentPath)
{
    GLuint programId = program.initWithVertexShaderPath(vertexPath, fragmentPath);
    program.link();
    program.use();
    program.validate();
    return programId;
}

GLuint cpp_compileProgramWithContent(GLProgram program, char *vertexContent, char *fragmentContent)
{
    GLuint programId = program.initWithVertexShaderString(vertexContent, fragmentContent);
    program.link();
    program.use();
    program.validate();
    return programId;
}
