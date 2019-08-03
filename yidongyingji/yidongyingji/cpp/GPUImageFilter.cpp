//
//  GPUImageFilter.cpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/29.
//  Copyright © 2019 李沛然. All rights reserved.
//

#include "GPUImageFilter.hpp"
#include <iostream>

#include <cstdlib>
#include <pthread.h>
#include <unistd.h>

std::thread::id main_thread_id = std::this_thread::get_id();

void hello()
{
    if (main_thread_id == std::this_thread::get_id())
        std::cout << "This is the main thread.\n";
    else
        std::cout << "This is not the main thread.\n";
}

using namespace std;
pthread_mutex_t sum_mutex; //互斥锁

//编辑顶点坐标源数组
GLfloat vertexData_src[30] = {
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    1.0, 1.0, -0.0f,    1.0f, 1.0f, //右上
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    -1.0, -1.0, 0.0f,   0.0f, 0.0f, //左下
};

//编辑顶点坐标目标数组
GLfloat vertexData_dst[30] = {
    
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
    _draw_b = false;
    _conti = true;
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

void GPUImageFilter::initWithProgram(GLuint screenX, GLuint screenY, GLuint screenW, GLuint screenH)
{
    setLocalData(screenX, screenY, screenW, screenH);
    
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
}

void GPUImageFilter::draw(int fr)
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
      
        int tmpAsset_index = parseAE.asset_index_refId(tmpEntity.refId, configEntity);
        AEAssetEntity tmpAsset = configEntity.assets[tmpAsset_index];
        float ae_w = tmpAsset.w;
        float ae_h = tmpAsset.h;
        
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

void GPUImageFilter::draw()
{
    draw(125);
}

void GPUImageFilter::addImageTexture(GPUImage &image)
{
    memcpy(vertexData_dst, vertexData_src, 30*sizeof(GLfloat));
    _texture[_texture_num] = cpp_createImageTexture(image.byte, image.w, image.h, _screenWidth, vertexData_dst);
    _aBufferID[_aBufferID_num] = cpp_createVAO(sizeof(vertexData_dst), vertexData_dst, _position, _textCoordinate);
    _texture_num++;
    _aBufferID_num++;
}

void GPUImageFilter::addConfigure(char *configFilePath)
{
    ParseAE parseAE;
    parseAE.dofile(configFilePath, configEntity);
    upImageTexture();
}

void GPUImageFilter::upImageTexture()
{
    ParseAE parseAE;
    for (int i = 0; i < configEntity.layers_num; i++)
    {
        AELayerEntity &layer = configEntity.layers[i];
        int asset_index = parseAE.asset_index_refId(layer.refId, configEntity);
        GPUImage *tmpImage = _imageAsset[asset_index];
        addImageTexture(*tmpImage);
    }
}

void GPUImageFilter::addImageAsset(GPUImage &image)
{
    GPUImage *tmpImage = &image;
    tmpImage->index = _imageAsset_num;
    _imageAsset[_imageAsset_num] = tmpImage;
    _imageAsset_num++;
}

