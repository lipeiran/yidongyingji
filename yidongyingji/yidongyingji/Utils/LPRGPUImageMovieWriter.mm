//
//  LPRGPUImageMovieWriter.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/17.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "LPRGPUImageMovieWriter.h"

@interface LPRGPUImageMovieWriter ()
{
    GLuint movieRenderbuffer, movieFramebuffer;
    
    GLint displayPositionAttribute, displayTextureCoordinateAttribute;
    GLint displayInputTextureUniform;
    GLint displayInputTextureUniform2;
    
    CGSize boundsSizeAtFrameBufferEpoch;
    
    GLuint _program;
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _position;
    GLuint _textCoordinate;
    
    GLuint _texture_test;
    GLuint _texture_test2;
    
    BOOL _layer_exist;
    int _fr;
    BOOL _slider_bool;
    AEConfigEntity configEntity;
}

@end

@implementation LPRGPUImageMovieWriter


- (id)init
{
    if (!(self = [super init]))
    {
        return NULL;
    }
    [self commonInit];
    return self;
}

- (void)commonInit
{
    NSLog(@"%s",__func__);
}

- (void)createDataFBO
{
    NSLog(@"%s",__func__);
    
}

- (void)setFilterFBO
{
    
}

- (void)destroyDataFBO
{
    NSLog(@"%s",__func__);

}

- (void)startRecording
{
    NSLog(@"%s",__func__);
    
}

- (void)stopRecording
{
    NSLog(@"%s",__func__);

}

@end
