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

void cpp_glBindTexture(GLenum texture_tgt, GLuint texture)
{
    glActiveTexture(texture_tgt);
    glBindTexture(GL_TEXTURE_2D, texture);
}

void cpp_glRotate(float anchorX,float anchorY, float xDegree, float yDegree, float zDegree, KSMatrix4 &sourceMatrix)
{
    //模型视图矩阵
    KSMatrix4 tmp_modelViewMatrix;
    //加载矩阵
    ksMatrixLoadIdentity(&tmp_modelViewMatrix);
    // 先平移
    ksTranslate(&tmp_modelViewMatrix, anchorX, anchorY, 0.0);
    
    //旋转矩阵
    KSMatrix4 _rotateMartix;
    //加载旋转矩阵
    ksMatrixLoadIdentity(&_rotateMartix);
    ksRotate(&_rotateMartix, xDegree, 1.0, 0, 0);
    ksRotate(&_rotateMartix, yDegree, 0, 1.0, 0);
    ksRotate(&_rotateMartix, zDegree, 0, 0, 1.0);
    //把变换矩阵相乘.将_modelViewMatrix矩阵与_rotationMatrix矩阵相乘，结合到模型视图
    ksMatrixMultiply(&tmp_modelViewMatrix, &_rotateMartix, &tmp_modelViewMatrix);
    
    //模型视图矩阵
    KSMatrix4 _translateMatrix;
    //加载矩阵
    ksMatrixLoadIdentity(&_translateMatrix);
    ksTranslate(&_translateMatrix, -anchorX, -anchorY, 0.0);
    ksMatrixMultiply(&tmp_modelViewMatrix,  &_translateMatrix, &tmp_modelViewMatrix);
    
    ksMatrixMultiply(&sourceMatrix,  &tmp_modelViewMatrix, &sourceMatrix);
}

void cpp_glScale(float anchorX,float anchorY, float xScale, float yScale, float zScale, KSMatrix4 &sourceMatrix)
{
    //模型视图矩阵
    KSMatrix4 tmp_modelViewMatrix_s;
    //加载矩阵
    ksMatrixLoadIdentity(&tmp_modelViewMatrix_s);
    // 先平移
    ksTranslate(&tmp_modelViewMatrix_s, anchorX, anchorY, 0.0);
    
    //缩放矩阵
    KSMatrix4 _scaleMartix;
    //加载缩放矩阵
    ksMatrixLoadIdentity(&_scaleMartix);
    //缩放
    ksScale(&_scaleMartix, xScale, yScale, zScale);
    //把变换矩阵相乘.将_modelViewMatrix矩阵与_rotationMatrix矩阵相乘，结合到模型视图
    ksMatrixMultiply(&tmp_modelViewMatrix_s, &_scaleMartix, &tmp_modelViewMatrix_s);
    
    //模型视图矩阵
    KSMatrix4 _translateMatrix_s;
    //加载矩阵
    ksMatrixLoadIdentity(&_translateMatrix_s);
    ksTranslate(&_translateMatrix_s, -anchorX, -anchorY, 0.0);
    
    ksMatrixMultiply(&tmp_modelViewMatrix_s, &_translateMatrix_s, &tmp_modelViewMatrix_s);
    ksMatrixMultiply(&sourceMatrix,  &tmp_modelViewMatrix_s, &sourceMatrix);
}

void cpp_glTranslate(float xDelta, float yDelta, float zDelta, KSMatrix4 &sourceMatrix)
{
    //模型视图矩阵
    KSMatrix4 tmp_modelViewMatrix_s;
    //加载矩阵
    ksMatrixLoadIdentity(&tmp_modelViewMatrix_s);
    //位移
    ksTranslate(&tmp_modelViewMatrix_s, xDelta, yDelta, zDelta);
    ksMatrixMultiply(&sourceMatrix,  &tmp_modelViewMatrix_s, &sourceMatrix);
}

void cpp_glProjection(float left, float right, float bottom, float top, float nearZ, float farZ, KSMatrix4 &sourceMatrix)
{
    KSMatrix4 project;
    ksMatrixLoadIdentity(&project);
    ksOrtho(&project, left, right, bottom, top, nearZ, farZ);
    ksMatrixMultiply(&sourceMatrix,  &project, &sourceMatrix);
}

void cpp_generate2DMatrix(float perspective_left, float perspective_right, float perspective_bottom, float perspective_top, float perspective_near, float perspective_far, float deltaX, float deltaY, float deltaZ, float rotateAngleX, float rotateAngleY, float rotateAngleZ, float scaleX, float scaleY, float scaleZ, float anchorPX,float anchorPY, KSMatrix4 &sourceMatrix)
{
    //------------------------------------------ Projection正交投影开始 ------------------------------------------//
    cpp_glProjection( perspective_left, perspective_right, perspective_bottom, perspective_top, perspective_near, perspective_far, sourceMatrix);
    //------------------------------------------ View位移开始 ------------------------------------------//
    cpp_glTranslate(deltaX, deltaY, deltaZ, sourceMatrix);
    //------------------------------------------ Model旋转开始 ------------------------------------------//
    cpp_glRotate(anchorPX, anchorPY, rotateAngleX, rotateAngleY, rotateAngleZ, sourceMatrix);
    //------------------------------------------ Model缩放开始 ------------------------------------------//
    cpp_glScale(anchorPX, anchorPY, scaleX, scaleY, scaleZ, sourceMatrix);
    //------------------------------------------ Model缩放结束 ------------------------------------------//
}

void cpp_generateAndUniform2DMatrix(float perspective_left, float perspective_right, float perspective_bottom, float perspective_top, float perspective_near, float perspective_far, float deltaX, float deltaY, float deltaZ, float rotateAngleX, float rotateAngleY, float rotateAngleZ, float scaleX, float scaleY, float scaleZ, float anchorPX,float anchorPY, GLuint modelViewProjectionMatrix_location)
{
    //模型视图矩阵
    KSMatrix4 _modelViewMatrix;
    //加载矩阵
    ksMatrixLoadIdentity(&_modelViewMatrix);
    cpp_generate2DMatrix( perspective_left,  perspective_right, perspective_bottom, perspective_top,  perspective_near,  perspective_far,  deltaX,  deltaY,  deltaZ,  rotateAngleX,  rotateAngleY,  rotateAngleZ,  scaleX,  scaleY,  scaleZ,  anchorPX,  anchorPY, _modelViewMatrix);
    glUniformMatrix4fv(modelViewProjectionMatrix_location, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix.m[0][0]);
}

GLuint cpp_createVAO(GLuint size, GLfloat* data, GLuint position_loc, GLuint texCoord_loc)
{
    GLuint aBufferID;
    GLuint vBufferID;
    glGenVertexArrays(1, &aBufferID);
    glGenBuffers(1, &vBufferID);
    
    glBindVertexArray(aBufferID);
    
    glBindBuffer(GL_ARRAY_BUFFER, vBufferID);
    glBufferData(GL_ARRAY_BUFFER, size, data, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(position_loc);
    glVertexAttribPointer(position_loc, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *) NULL + 0);
    glEnableVertexAttribArray(texCoord_loc);
    glVertexAttribPointer(texCoord_loc, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *) NULL + 3);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
    return aBufferID;
}

GLuint cpp_createImageTexture(GLubyte *byte, GLuint w, GLuint h, GLuint screenWidthPixel, GLfloat *dst_data)
{
    GLuint texture;
    texture = cpp_setupTexture(GL_TEXTURE1);
    cpp_upGPUTexture(w, h, byte);
    //释放byte
    free(byte);
    float screen_ratio = screenWidthPixel/Base_Draw_w;
    float w_ratio = w*1.0/screenWidthPixel * screen_ratio;
    float h_w_ratio = h*1.0/w*w_ratio;
    for (int i = 0; i < 6; i++)
    {
        dst_data[i*5+0] *= w_ratio;
        dst_data[i*5+1] *= h_w_ratio;
    }
    return texture;
}

// 绘制前准备
void cpp_glDraw_pre(void)
{
    //设置背景色
    glClearColor(0.0f, 1.0f, 0.0f, 1.0f);
    //清除颜色缓冲
    glClear(GL_COLOR_BUFFER_BIT);
    //开启正背面剔除
    glEnable(GL_CULL_FACE);
    //开启颜色混合
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

void cpp_glDraw_header(GLint x, GLint y, GLsizei width, GLsizei height)
{
    cpp_glDraw_pre();
    //设置视口
    glViewport(x, y, width, height);
}
