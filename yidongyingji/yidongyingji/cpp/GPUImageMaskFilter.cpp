//
//  GPUImageMaskFilter.cpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#include "GPUImageMaskFilter.hpp"
#include <iostream>
#include <cstdlib>
#include <pthread.h>
#include <unistd.h>

using namespace std;

//编辑顶点坐标源数组
GLfloat vertexData_mask_src[30] = {
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    1.0, 1.0, -0.0f,    1.0f, 1.0f, //右上
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    -1.0, -1.0, 0.0f,   0.0f, 0.0f, //左下
};

//编辑顶点坐标目标数组
GLfloat vertexData_mask_dst[30] = {
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    1.0, 1.0, -0.0f,    1.0f, 1.0f, //右上
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    -1.0, -1.0, 0.0f,   0.0f, 0.0f, //左下
};

char kMaskSamplingVertexShaderC[] = "attribute vec4 position;attribute vec2 inputTextureCoordinate;attribute vec2 inputTextureCoordinate2;attribute vec2 inputTextureCoordinate3;varying vec2 textureCoordinate;varying vec2 textureCoordinate2;varying vec2 textureCoordinate3;void main(){gl_Position = position;textureCoordinate = inputTextureCoordinate;textureCoordinate2 = inputTextureCoordinate2;textureCoordinate3 = inputTextureCoordinate3;}";

char kMaskSamplingFragmentShaderC[] = "varying highp vec2 textureCoordinate;varying highp vec2 textureCoordinate2;varying highp vec2 textureCoordinate3;uniform sampler2D inputImageTexture;uniform sampler2D inputImageTexture2;uniform sampler2D inputImageTexture3;void main(){lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);lowp vec4 textureColor3 = texture2D(inputImageTexture3, textureCoordinate3);gl_FragColor = textureColor * (1.0 - textureColor2.r) + textureColor3;}";

void GPUImageMaskFilter::setLocalData(GLuint screenX, GLuint screenY, GLuint screenW, GLuint screenH)
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
    _aBufferID_num = 0;
    _texture_num = 0;
    memset(_aBufferID, 0, 3);
    memset(_texture, 0, 3);
}

void GPUImageMaskFilter::setDisplayFrameBuffer()
{
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(_viewPort_x, _viewPort_y, _viewPort_w, _viewPort_h);
}

void GPUImageMaskFilter::destropDisplayFrameBuffer()
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

void GPUImageMaskFilter::initWithProgram(GLuint screenX, GLuint screenY, GLuint screenW, GLuint screenH)
{
    setLocalData(screenX, screenY, screenW, screenH);
    
    GLProgram glProgram1;
    //编译program
    _program = cpp_compileProgramWithContent(glProgram1, kMaskSamplingVertexShaderC, kMaskSamplingFragmentShaderC);
    //从program中获取position 顶点属性
    _position = glGetAttribLocation(_program, "position");
    //从program中获取textCoordinate 纹理属性
    _textCoordinate = glGetAttribLocation(_program, "inputTextureCoordinate");
    _textCoordinate2 = glGetAttribLocation(_program, "inputTextureCoordinate2");
    _textCoordinate3 = glGetAttribLocation(_program, "inputTextureCoordinate3");

    glUniform1i(glGetUniformLocation(_program, "inputImageTexture"), 0);
    glUniform1i(glGetUniformLocation(_program, "inputImageTexture2"), 1);
    glUniform1i(glGetUniformLocation(_program, "inputImageTexture3"), 2);

    //设置渲染缓冲区
    _renderBuffer = cpp_setupRenderBuffer();
    //设置帧缓冲区
    _frameBuffer = cpp_setupFrameBuffer();
    // 生成帧缓冲区，把renderbuffer 跟 framebuffer绑定到一起
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
}

void GPUImageMaskFilter::draw(int fr)
{
    ParseAE parseAE;
    glUseProgram(_program);
    cpp_glDraw_header(_viewPort_x, _viewPort_y, _viewPort_w, _viewPort_h);
    
    for (int i = 0; i < _aBufferID_num; ++i)
    {
        AELayerEntity tmpEntity = configEntity.layers[_aBufferID_num-i-1];
        if (fr < tmpEntity.ip || fr > tmpEntity.op)
        {
            continue;
        }
        float ae_w = tmpEntity.layer_w;
        float ae_h = tmpEntity.layer_h;
        float ae_a_x = 0.0f;
        float ae_a_y = 0.0f;
        float ae_p_x = 0.0f;
        float ae_p_y = 0.0f;
        float ae_s_x = 0.0f;
        float ae_s_y = 0.0f;
        float ae_r = 0.0f;
        int ae_blur = 0;
        float ae_alpha = 0;
        
        parseAE.get_ae_params(fr, tmpEntity, &ae_r, &ae_s_x, &ae_s_y, &ae_p_x, &ae_p_y, &ae_a_x, &ae_a_y, &ae_alpha, &ae_blur);
        
        float ae_a_x_result = (ae_a_x-ae_w/2.0)/_viewPort_w*2.0;
        float ae_a_y_result = (ae_h/2.0-ae_a_y)/_viewPort_w*2.0;
        
        glBindVertexArray(_aBufferID[i]);
        GPUAnimateAttr animateAttr;
        animateAttr.anchorPX = ae_a_x_result;
        animateAttr.anchorPY = ae_a_y_result;
        animateAttr.rotateAngleZ = ae_r;
        animateAttr.scaleX = ae_s_x;
        animateAttr.scaleY = ae_s_y;
        
        float end_deltaX = (ae_w/2.0-_viewPort_w/2.0) + ae_p_x;
        float end_deltaY = (_viewPort_h/2.0-ae_h/2.0) - ae_p_y;
        
        animateAttr.deltaX = end_deltaX/_viewPort_w*2.0;
        animateAttr.deltaY = end_deltaY/_viewPort_w*2.0;
        
        cpp_generateAndUniform2DMatrix(_perspective_left, _perspective_right, _perspective_bottom, _perspective_top, _perspective_near, _perspective_far, animateAttr.deltaX, animateAttr.deltaY, animateAttr.deltaZ, animateAttr.rotateAngleX, animateAttr.rotateAngleY, animateAttr.rotateAngleZ, animateAttr.scaleX, animateAttr.scaleY, animateAttr.scaleZ, animateAttr.anchorPX, animateAttr.anchorPY, _modelViewMartix_S);
        cpp_glBindTexture(GL_TEXTURE0, _texture[_aBufferID_num-i-1]);
        glDrawArrays(GL_TRIANGLES, 0, 6);
        glBindVertexArray(0);
    }
    glBindVertexArray(0);
}

void GPUImageMaskFilter::draw()
{
    draw(0);
}

// 添加mask视频纹理
void GPUImageMaskFilter::addMaskTexture(GLuint mask_texture_id)
{
    
}

// 添加前景视频纹理
void GPUImageMaskFilter::addFiltTexture(GLuint filt_texture_id)
{
    
}

void GPUImageMaskFilter::upVideoTexture()
{
    memcpy(vertexData_mask_dst, vertexData_mask_src, 30*sizeof(GLfloat));
//    _texture[_texture_num] = cpp_createImageTexture(image.byte, image.w, image.h, _screenWidth, vertexData_mask_dst);
    _aBufferID[_aBufferID_num] = cpp_createVAO(sizeof(vertexData_mask_dst), vertexData_mask_dst, _position, _textCoordinate);
    _texture_num++;
    _aBufferID_num++;
}
