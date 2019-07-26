//
//  OpenGLES2DView.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/25.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLProgram.hpp"
#import "utils.hpp"

NS_ASSUME_NONNULL_BEGIN

@interface OpenGLES2DView : UIView
{
    GLuint _program;
    GLuint _vBufferID;
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _position;
    GLuint _textCoordinate;
    GLuint _texture;
    GLuint _textureTwo;
    GLuint _modelViewMartix_S;
    GLuint _projectionMatrix_S;
    
    float _screenWidth;
    float _screenHeight;
    float _aspectRatio;
    CGFloat _scale;
}

@property (nonatomic, strong) CAEAGLLayer *eaglLayer;
@property (nonatomic, strong) EAGLContext *context;

@end

NS_ASSUME_NONNULL_END

