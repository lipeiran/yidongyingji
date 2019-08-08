//
//  GPUImageMaskFilter.hpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#ifndef GPUImageMaskFilter_hpp
#define GPUImageMaskFilter_hpp

#include <stdio.h>
#include "GLProgram.hpp"
#include "GPUImage.hpp"
#include "GPUAnimateAttr.hpp"
#include "Parse_AE.h"
#include "TimeWheel.hpp"
#include <pthread.h>

class GPUImageMaskFilter {
public:
    GLuint _program;
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _position;
    GLuint _textCoordinate;
    GLuint _textCoordinate2;
    GLuint _textCoordinate3;
    GLuint _modelViewMartix_S;
    
    AEConfigEntity configEntity;
    
    GLuint _aBufferID[3];
    GLuint _aBufferID_num;
    GLuint _texture[3];
    GLuint _texture_num;

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
    
    void setLocalData(GLuint screenX, GLuint screenY, GLuint screenW, GLuint screenH);
    void initWithProgram(GLuint screenX, GLuint screenY, GLuint screenW, GLuint screenH);
    void draw(int fr);
    void draw();
    
    void setDisplayFrameBuffer();
    void destropDisplayFrameBuffer();

    void addMaskTexture(GLuint mask_texture_id);
    void addFiltTexture(GLuint filt_texture_id);
    void upVideoTexture();
    
    
protected:
    
private:
    
    
};


#endif /* GPUImageMaskFilter_hpp */
