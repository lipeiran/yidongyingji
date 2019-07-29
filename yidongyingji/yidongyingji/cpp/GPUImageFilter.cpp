//
//  GPUImageFilter.cpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/29.
//  Copyright © 2019 李沛然. All rights reserved.
//

#include "GPUImageFilter.hpp"

//编辑顶点坐标数组
GLfloat vertexData1[30] = {
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    1.0, 1.0, -0.0f,    1.0f, 1.0f, //右上
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    -1.0, -1.0, 0.0f,   0.0f, 0.0f, //左下
};

//编辑顶点坐标数组
GLfloat vertexData2[30] = {
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    1.0, 1.0, -0.0f,    1.0f, 1.0f, //右上
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    -1.0, -1.0, 0.0f,   0.0f, 0.0f, //左下
};

char kSamplingVertexShaderC[] = "attribute vec4 position;attribute vec4 positionColor;attribute vec2 textCoordinate;uniform mat4 modelViewMatrix;varying lowp vec2 varyTextCoord;void main(){varyTextCoord = textCoordinate;gl_Position = modelViewMatrix * position;}";

char kSamplingFragmentShaderC[] = "varying lowp vec2 varyTextCoord;uniform sampler2D colorMap;void main(){lowp vec4 tex = texture2D(colorMap, vec2(varyTextCoord.x,1.0-varyTextCoord.y));gl_FragColor = tex ;}";

void GPUImageFilter::setLocalData(GLuint screenX, GLuint screenY, GLuint screenW, GLuint screenH)
{
    _screenWidth = screenW;
    _screenHeight = screenH;
    _aspectRatio = _screenHeight/_screenWidth;
    _perspective_left = -1;
    _perspective_right = 1;
    _perspective_bottom = -_aspectRatio;
    _perspective_top = _aspectRatio;
    _perspective_near = 0.1f;
    _perspective_far = 100.0f;
    _viewPort_x = screenX;
    _viewPort_y = screenY;
    _viewPort_w = screenW;
    _viewPort_h = screenH;
}

void GPUImageFilter::setDisplayFrameBuffer()
{
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(_viewPort_x, _viewPort_y, _viewPort_w, _viewPort_h);
}

void GPUImageFilter::destropDisplayFrameBuffer()
{
    if (_frameBuffer)
    {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    if (_renderBuffer)
    {
        glDeleteRenderbuffers(1, &_renderBuffer);
        _renderBuffer = 0;
    }
}

void GPUImageFilter::initWithProgramAndImageByte(GLubyte *byte1, int w1, int h1, GLubyte *byte2, int w2, int h2)
{
    GLProgram glProgram1;
    //编译program
    _program = cpp_compileProgramWithContent(glProgram1, kSamplingVertexShaderC, kSamplingFragmentShaderC);
    //从program中获取position 顶点属性
    _position = glGetAttribLocation(_program, "position");
    //从program中获取textCoordinate 纹理属性
    _textCoordinate = glGetAttribLocation(_program, "textCoordinate");
    _modelViewMartix_S = glGetUniformLocation(_program, "modelViewMatrix");
    glUniform1i(glGetUniformLocation(_program, "colorMap"), 0);
    
    //设置渲染缓冲区
    _renderBuffer = cpp_setupRenderBuffer();
    //设置帧缓冲区
    _frameBuffer = cpp_setupFrameBuffer();
    // 生成帧缓冲区，把renderbuffer 跟 framebuffer绑定到一起
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    _texture = cpp_createImageTexture(byte1, w1, h1, _screenWidth, vertexData1);
    _texture2 = cpp_createImageTexture(byte2, w2, h2, _screenWidth, vertexData2);
    _aBufferID = cpp_createVAO(sizeof(vertexData1), vertexData1, _position, _textCoordinate);
    _aBufferID2 = cpp_createVAO(sizeof(vertexData2), vertexData2, _position, _textCoordinate);
}

void GPUImageFilter::draw()
{
    glUseProgram(_program);
    cpp_glDraw_header(_viewPort_x, _viewPort_y, _viewPort_w, _viewPort_h);
    glBindVertexArray(_aBufferID);
    // ******************** 第一个纹理 **********************//
    {
        float anchorPX = 1.0;
        float anchorPY = 1.5;
        float rotateAngleX = 0.0f;
        float rotateAngleY = 0.0f;
        float rotateAngleZ = 0.0f;
        float scaleX = 0.5;
        float scaleY = 0.5;
        float scaleZ = 1.0;
        float deltaX = 0.0;
        float deltaY = 0.0;
        float deltaZ = -10.0;
        
        cpp_generateAndUniform2DMatrix(_perspective_left, _perspective_right, _perspective_bottom, _perspective_top, _perspective_near, _perspective_far,  deltaX,  deltaY,  deltaZ,  rotateAngleX,  rotateAngleY,  rotateAngleZ,  scaleX,  scaleY,  scaleZ,  anchorPX,  anchorPY, _modelViewMartix_S);
        cpp_glBindTexture(GL_TEXTURE0, _texture);
        glDrawArrays(GL_TRIANGLES, 0, 6);
    }
    glBindVertexArray(0);
    // ******************** 第二个纹理 **********************//
    glBindVertexArray(_aBufferID2);
    {
        float anchorPX = 0.0;
        float anchorPY = 0.0;
        float rotateAngleX = 0.0f;
        float rotateAngleY = 0.0f;
        float rotateAngleZ = 45.0f;
        float scaleX = 0.5;
        float scaleY = 0.5;
        float scaleZ = 1.0;
        float deltaX = 0.0;
        float deltaY = 0.0;
        float deltaZ = -10.0;
        
        cpp_generateAndUniform2DMatrix(_perspective_left, _perspective_right, _perspective_bottom, _perspective_top, _perspective_near, _perspective_far,  deltaX,  deltaY,  deltaZ,  rotateAngleX,  rotateAngleY,  rotateAngleZ,  scaleX,  scaleY,  scaleZ,  anchorPX,  anchorPY, _modelViewMartix_S);
        cpp_glBindTexture(GL_TEXTURE0, _texture2);
        glDrawArrays(GL_TRIANGLES, 0, 6);
    }
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindVertexArray(0);
}
