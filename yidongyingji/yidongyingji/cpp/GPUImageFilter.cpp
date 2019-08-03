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
    glUseProgram(_program);
    cpp_glDraw_header(_viewPort_x, _viewPort_y, _viewPort_w, _viewPort_h);
    
    for (int i = 0; i < _aBufferID_num; ++i)
    {
        glBindVertexArray(_aBufferID[i]);
        // ******************** 第一个纹理 **********************//
        {
            GPUAnimateAttr animateAttr;
            animateAttr.anchorPX = i * 0.3f;
            animateAttr.anchorPY = 0.0f;
            animateAttr.rotateAngleX = 0.0f;
            animateAttr.rotateAngleY = 0.0f;
            animateAttr.rotateAngleZ = 45.0f;
            animateAttr.scaleX = 1.0f;
            animateAttr.scaleY = 1.0f;
            animateAttr.scaleZ = 1.0f;
            animateAttr.deltaX = 0.0f;
            animateAttr.deltaY = 0.0f;
            animateAttr.deltaZ = -10.0f;
            animateAttr.alpha = 1.0f;
            
            cpp_generateAndUniform2DMatrix(_perspective_left, _perspective_right, _perspective_bottom, _perspective_top, _perspective_near, _perspective_far, animateAttr.deltaX, animateAttr.deltaY, animateAttr.deltaZ, animateAttr.rotateAngleX, animateAttr.rotateAngleY, animateAttr.rotateAngleZ, animateAttr.scaleX, animateAttr.scaleY, animateAttr.scaleZ, animateAttr.anchorPX, animateAttr.anchorPY, _modelViewMartix_S);
            cpp_glBindTexture(GL_TEXTURE0, _texture[i]);
            glDrawArrays(GL_TRIANGLES, 0, 6);
        }
        glBindVertexArray(0);
    }
    glBindVertexArray(0);
}

void GPUImageFilter::showGLScreen()
{
    draw(-1);
}

void* GPUImageFilter::game_draw_thread_callback(void *game_ptr)
{
    while (1)
    {
        this_thread::sleep_for(std::chrono::seconds(1));
        GPUImageFilter * game = (GPUImageFilter *)game_ptr;
        game->timerinvokeCallback();
    }
    return NULL;
}

void GPUImageFilter::draw()
{
    pthread_create(&_draw_t, NULL, GPUImageFilter::game_draw_thread_callback, this);
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

void GPUImageFilter::setTimerCallback(CPPCallback cb, void *param)
{
    timerCallback = cb;
    callBackParam = param;
}

void GPUImageFilter::timerinvokeCallback()
{
    timerCallback(callBackParam);
}

