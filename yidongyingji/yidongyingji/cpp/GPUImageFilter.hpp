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

class GPUImageFilter {
public:
    GLuint _program;
    GLuint _aBufferID;
    GLuint _vBufferID;
    GLuint _aBufferID2;
    GLuint _vBufferID2;
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _position;
    GLuint _textCoordinate;
    GLuint _texture;
    GLuint _texture2;
    GLuint _modelViewMartix_S;

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
    
    void initWithProgramAndImageByte(GLubyte *byte1, int w1, int h1, GLubyte *byte2, int w2, int h2);
    
    void draw();
    
    void setDisplayFrameBuffer();
    void destropDisplayFrameBuffer();
private:
    
    
};

#endif /* GPUImageFilter_hpp */
