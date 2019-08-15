//
//  LPRGPUImageView.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "LPRGPUImageView.h"
#import "OpenGLES2DTools.h"
#import "GPUImageMovie.h"


#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)
NSString *const kSamplingVertexShaderC_lpr = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );


NSString *const kSamplingFragmentShaderC_lpr = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;

 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     lowp vec4 textureColor2 = texture2D(inputImageTexture2, vec2(textureCoordinate.x,1.0-textureCoordinate.y));
     gl_FragColor = textureColor * 0.4 + textureColor2;
 }
 );

static const GLfloat imageVertices_lpr[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};

static const GLfloat textureCoordinates_lpr[] = {
    0.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f,
};

@interface LPRGPUImageView ()
{
    GLuint displayRenderbuffer, displayFramebuffer;
    
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
    int _fr_pts;
}

@property(nonatomic, strong) NSTimer *renderTimer;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) GPUImageMovie *preMovie;

@end

@implementation LPRGPUImageView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
    {
        return nil;
    }
    [self setMaskMovieTexture];
    [self commonInit];
    [self setTimer];
    return self;
}

- (void)setTimer
{
    self->_renderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/_fr target:self selector:@selector(startQueue) userInfo:nil repeats:YES];
}

- (void)setMaskMovieTexture
{
    _fr = 25;
    NSURL *tmpUrl = [[NSBundle mainBundle]URLForResource:@"tp_fg" withExtension:@"mp4"];
    AVAsset *tmpAsset = [AVAsset assetWithURL:tmpUrl];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithAsset:tmpAsset];
    _player = [AVPlayer playerWithPlayerItem:playerItem];
    _preMovie = [[GPUImageMovie alloc]initWithPlayerItem:playerItem];
    _player.rate = 1.0;
    [_preMovie startProcessing];
    [_player play];
}

- (void)startQueue
{
    if (_layer_exist)
    {
        if (self->_preMovie.data_ready)
        {
            runAsynchronouslyOnVideoProcessingQueue(^{
                runSynchronouslyOnVideoProcessingQueue(^{
                    [self->imageFilter renderToTexture:self->_fr_pts];
                    self->_preMovie.pts = self->_fr_pts;
                    [self->_preMovie processPtsFrameBuffer:self->_fr];
                    self->_texture_test = self->imageFilter.outputFramebuffer.texture;
                    self->_texture_test2 = self->_preMovie.outputFramebuffer.texture;
                    [self draw];
                    self->_fr_pts++;
                });
            });
        }
    }
}

- (void)commonInit;
{
    // Set scaling to account for Retina display
    if ([self respondsToSelector:@selector(setContentScaleFactor:)])
    {
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
    }
    self.opaque = YES;
    self.hidden = NO;
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    float scale = [UIScreen mainScreen].scale;
    CGSize screenSize = CGSizeMake(self.frame.size.width * scale, self.frame.size.height * scale);

    runAsynchronouslyOnVideoProcessingQueue(^{
        runSynchronouslyOnVideoProcessingQueue(^{

            [GPUImageContext useImageProcessingContext];
            GLProgram glProgram1;
            //编译program
            char *tmpV = (char *)[kSamplingVertexShaderC_lpr UTF8String];
            char *tmpF = (char *)[kSamplingFragmentShaderC_lpr UTF8String];
            self->_program = cpp_compileProgramWithContent(glProgram1, tmpV, tmpF);
            //从program中获取position 顶点属性
            self->displayPositionAttribute = glGetAttribLocation(self->_program, "position");
            //从program中获取textCoordinate 纹理属性
            self->displayTextureCoordinateAttribute = glGetAttribLocation(self->_program, "inputTextureCoordinate");
            self->displayInputTextureUniform = glGetUniformLocation(self->_program, "inputImageTexture");
            self->displayInputTextureUniform2 = glGetUniformLocation(self->_program, "inputImageTexture2");
            [GPUImageContext useImageProcessingContext];
            glUseProgram(self->_program);
            glEnableVertexAttribArray(self->displayPositionAttribute);
            glEnableVertexAttribArray(self->displayTextureCoordinateAttribute);
            [self createDisplayFramebuffer];
            
            self->imageFilter = [[LPRGPUImageFilter alloc]initSize:screenSize imageName:nil];
            self->imageFilter2 = [[LPRGPUImageFilter alloc]initSize:screenSize imageName:@"img_02.png"];
        });
    });
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _layer_exist = true;
    // The frame buffer needs to be trashed and re-created when the view size changes.
    if (!CGSizeEqualToSize(self.bounds.size, boundsSizeAtFrameBufferEpoch) &&
        !CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        runSynchronouslyOnVideoProcessingQueue(^{
            [self destroyDisplayFramebuffer];
            [self createDisplayFramebuffer];
        });
    }
    
    _fr_pts = 0;
}

- (void)dealloc
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [self destroyDisplayFramebuffer];
    });
}

#pragma mark -
#pragma mark Managing the display FBOs

- (void)createDisplayFramebuffer;
{
    [GPUImageContext useImageProcessingContext];
    
    glGenFramebuffers(1, &displayFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    
    glGenRenderbuffers(1, &displayRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
    
    [[[GPUImageContext sharedImageProcessingContext] context] renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    
    GLint backingWidth, backingHeight;
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    if ( (backingWidth == 0) || (backingHeight == 0) )
    {
        [self destroyDisplayFramebuffer];
        return;
    }
    
    _sizeInPixels.width = (CGFloat)backingWidth;
    _sizeInPixels.height = (CGFloat)backingHeight;

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, displayRenderbuffer);
    
    __unused GLuint framebufferCreationStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(framebufferCreationStatus == GL_FRAMEBUFFER_COMPLETE, @"Failure with display framebuffer generation for display of size: %f, %f", self.bounds.size.width, self.bounds.size.height);
    boundsSizeAtFrameBufferEpoch = self.bounds.size;
}

- (void)destroyDisplayFramebuffer;
{
    [GPUImageContext useImageProcessingContext];
    
    if (displayFramebuffer)
    {
        glDeleteFramebuffers(1, &displayFramebuffer);
        displayFramebuffer = 0;
    }
    
    if (displayRenderbuffer)
    {
        glDeleteRenderbuffers(1, &displayRenderbuffer);
        displayRenderbuffer = 0;
    }
}

- (void)setDisplayFramebuffer;
{
    if (!displayFramebuffer)
    {
        [self createDisplayFramebuffer];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    
    glViewport(0, 0, (GLint)_sizeInPixels.width, (GLint)_sizeInPixels.height);
}

- (void)presentFramebuffer;
{
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
    [[[GPUImageContext sharedImageProcessingContext] context] presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)draw
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        runSynchronouslyOnVideoProcessingQueue(^{
            [GPUImageContext useImageProcessingContext];
            glUseProgram(self->_program);
            [self setDisplayFramebuffer];
            
            glClearColor(1.0, 1.0, 1.0, 1.0);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            
            glActiveTexture(GL_TEXTURE4);
            glBindTexture(GL_TEXTURE_2D,self->_texture_test);
            glUniform1i(self->displayInputTextureUniform, 4);
            
            glActiveTexture(GL_TEXTURE5);
            glBindTexture(GL_TEXTURE_2D,self->_texture_test2);
            glUniform1i(self->displayInputTextureUniform2, 5);
            
            glVertexAttribPointer(self->displayPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices_lpr);
            glVertexAttribPointer(self->displayTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates_lpr);
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
            [self presentFramebuffer];
        });
    });
}

@end
