//
//  LPRGPUImageView.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "LPRGPUImageView.h"
#import "GPUImageMovie.h"

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
    BOOL _slider_bool;
    CGFloat _duration;
    int32_t _timeScale;
    AEConfigEntity configEntity;

}

@property(nonatomic, strong) NSTimer *renderTimer;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) GPUImageMovie *preMovie;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, assign) BOOL audioPlaying;

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
    [self commonInit];
    [self setTimer];
    return self;
}

- (void)stopTimer;
{
    if (self->_renderTimer)
    {
        [self->_renderTimer invalidate];
        self->_renderTimer = nil;
    }
}

- (void)setTimer
{
    self->_renderTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/_fr target:self selector:@selector(startQueue) userInfo:nil repeats:YES];
}

- (void)setMaskMovieTexture
{
    NSError *error;
    NSString *musicPath = [[NSBundle mainBundle]pathForResource:@"music" ofType:@"mp3"];
    _audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL URLWithString:musicPath] error:&error];
    _audioPlayer.numberOfLoops = 0;
    [_audioPlayer prepareToPlay];
    
    char *configPath = (char *)[[[NSBundle mainBundle]pathForResource:@"tp" ofType:@"json"] UTF8String];
    ParseAE parseAE;
    parseAE.dofile(configPath, configEntity);
    _fr = configEntity.fr;
    NSURL *tmpUrl = [[NSBundle mainBundle]URLForResource:@"tp_fg" withExtension:@"mp4"];
    AVAsset *tmpAsset = [AVAsset assetWithURL:tmpUrl];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithAsset:tmpAsset];
    _player = [AVPlayer playerWithPlayerItem:playerItem];
    _timeScale = tmpAsset.duration.timescale;
    _duration = tmpAsset.duration.value/tmpAsset.duration.timescale;
    
    _preMovie = [[GPUImageMovie alloc]initWithPlayerItem:playerItem];
    self.player.rate = 1.0;
    [_preMovie startProcessing];
    [self.player play];
}

- (void)startQueue
{
    if (_layer_exist)
    {
        if (self->_preMovie.data_ready)
        {
            runAsynchronouslyOnVideoProcessingQueue(^{
                runSynchronouslyOnVideoProcessingQueue(^{
                    int fr_pts = (int)(self.player.currentTime.value*1.0/self.player.currentTime.timescale*self->_fr);
                    [self->imageFilter renderToTexture:fr_pts];
                    [self->_preMovie processPixelBufferAtTimeWithTime:self.player.currentTime];
                    self->_texture_test = self->imageFilter.outputFramebuffer.texture;
                    self->_texture_test2 = self->_preMovie.outputFramebuffer.texture;
                    [self draw];
                    if ( !self.audioPlaying )
                    {
                        self.audioPlaying = YES;
                        [self.audioPlayer play];
                    }
                });
            });
        }
    }
}

- (void)commonInit;
{
    // Set scaling to account for Retina display
    [self setMaskMovieTexture];

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
            
            self->imageFilter = [[LPRGPUImageFilter alloc]initSize:screenSize imageName:nil ae:self->configEntity];
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
}

- (void)dealloc
{
    [self stopTimer];
    runSynchronouslyOnVideoProcessingQueue(^{
        [self destroyDisplayFramebuffer];
    });
}

#pragma mark -
#pragma mark Managing the display FBOs

- (void)play
{
    NSLog(@"%s",__func__);
    self->_slider_bool = NO;
    self.preMovie.not_check_new = NO;
}

- (void)pause
{
    NSLog(@"%s",__func__);
    self->_slider_bool = YES;
    self.preMovie.not_check_new = YES;
    [self.player pause];
    [self.audioPlayer pause];
}

- (void)resume
{
    NSLog(@"%s",__func__);
    self->_slider_bool = NO;
    self.preMovie.not_check_new = NO;
    [self.player play];
    [self.audioPlayer play];
}

- (void)stop
{
    NSLog(@"%s",__func__);
    self->_slider_bool = YES;
    self.preMovie.not_check_new = YES;
}

- (void)seekToPercent:(CGFloat)percent;
{
    NSLog(@"%s",__func__);
    self->_slider_bool = YES;
    self.preMovie.not_check_new = YES;

    CGFloat tmpNowSecond = _duration * percent;
    [self.player seekToTime:CMTimeMakeWithSeconds(tmpNowSecond, _timeScale)
            toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero
          completionHandler:^(BOOL finished)
     {
     }];
    self.audioPlayer.currentTime = self.audioPlayer.duration * percent;
}

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

            glClearColor(1.0, 0.0, 1.0, 1.0);
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
