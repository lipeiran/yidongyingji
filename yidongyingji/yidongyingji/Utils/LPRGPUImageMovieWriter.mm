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
    
    GLint moviePositionAttribute, movieTextureCoordinateAttribute;
    GLint movieInputTextureUniform;
    GLint movieInputTextureUniform2;
    
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

@synthesize movieWriterContext = _movieWriterContext;

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize;
{
    return [self initWithMovieURL:newMovieURL size:newSize fileType:AVFileTypeQuickTimeMovie outputSettings:nil];
}

- (id)initWithMovieURL:(NSURL *)newMovieURL size:(CGSize)newSize fileType:(NSString *)newFileType outputSettings:(NSMutableDictionary *)outputSettings;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    videoSize = newSize;
    movieURL = newMovieURL;
    fileType = newFileType;
    
    _movieWriterContext = [[GPUImageContext alloc] init];
    [_movieWriterContext useSharegroup:[[[GPUImageContext sharedImageProcessingContext] context] sharegroup]];
    
    
    
    
    
    [self commonInit:outputSettings];

    return self;
}

- (void)commonInit:(NSDictionary *)settings;
{
    NSLog(@"%s",__func__);

    
    
    
}

- (void)createDataFBO
{
    NSLog(@"%s",__func__);
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &movieFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    
    
    
}

- (void)setFilterFBO
{
    if (!movieFramebuffer)
    {
        [self createDataFBO];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    glViewport(0, 0, Draw_w, Draw_h);
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
