//
//  GPUImageFilter.hpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/29.
//  Copyright © 2019 李沛然. All rights reserved.
//

#ifndef GPUImageFilter_hpp
#define GPUImageFilter_hpp

#include <stdio.h>
#include "GLProgram.hpp"
#include "GPUImage.hpp"
#include "GPUAnimateAttr.hpp"
#include "Parse_AE.h"
#include "TimeWheel.hpp"
#include <pthread.h>

typedef void (*CPPCallback)(void *param);

class GPUImageFilter {
public:
    GLuint _program;
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _position;
    GLuint _textCoordinate;
    GLuint _modelViewMartix_S;
    
    AEConfigEntity configEntity;
    
    GLuint _aBufferID[512];
    GLuint _aBufferID_num;
    GLuint _texture[512];
    GLuint _texture_num;
    
    GPUImage *_imageAsset[512];
    GLuint _imageAsset_num;

    float _screenWidth;
    float _screenHeight;
    float _aspectRatio;
    float _scale;
    
    float _perspective_left;
    float _perspective_right;
    float _perspective_bottom;
    float _perspective_top;
    float _perspective_near;
    float _perspective_far;
    
    float _viewPort_x;
    float _viewPort_y;
    float _viewPort_w;
    float _viewPort_h;
    
    bool _draw_b;
    bool _conti;
    pthread_t _draw_t;
    CPPCallback timerCallback;
    
    void *callBackParam;
    
    void setLocalData(GLuint screenX, GLuint screenY, GLuint screenW, GLuint screenH);
    
    void initWithProgram(GLuint screenX, GLuint screenY, GLuint screenW, GLuint screenH);
    
    void draw(int fr);
    
    void draw();
    
    void setDisplayFrameBuffer();
    void destropDisplayFrameBuffer();
    
    void addImageTexture(GPUImage &image);
    
    void addConfigure(char *configFilePath);
    
    void upImageTexture();

    void addImageAsset(GPUImage &image);

protected:
    
private:
    
    
};

#endif /* GPUImageFilter_hpp */
