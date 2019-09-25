//
//  LPRGPUImageView.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "LPRGPUImageView.h"
#import "LPRGPUImageMovie.h"

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
    
    GLuint _texture_ae;
    GLuint _texture_movie;
    
    BOOL _layer_exist;
    int _fr;
    int _total_fr;
    BOOL _slider_bool;
    CGFloat _duration;
    int32_t _timeScale;
    AEConfigEntity configEntity;
    AEConfigEntity camera_configEntity;
}

@property (nonatomic, strong) NSTimer *renderTimer;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) LPRGPUImageMovie *preMovie;

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, assign) BOOL audioPlaying;

@end

@implementation LPRGPUImageView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame withName:(NSString *)fileName
{
    if (!(self = [super initWithFrame:frame]))
    {
        return nil;
    }
    self.resName = fileName;
    [self commonInit];
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

    NSString *resPath = [ResourceBasePath stringByAppendingPathComponent:self.resName];
    NSString *musicPath = [resPath stringByAppendingPathComponent:@"music.mp3"];
    NSString *tp_fg_Path = [resPath stringByAppendingPathComponent:@"tp_fg.mp4"];
    NSString *tp_json_Path = [resPath stringByAppendingPathComponent:@"tp.json"];
    NSString *tp_camera_Path = [resPath stringByAppendingPathComponent:@"tp_camera.json"];
    
    _audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL URLWithString:musicPath] error:&error];
    _audioPlayer.numberOfLoops = 0;
    [_audioPlayer prepareToPlay];
    
    char *configPath = (char *)[tp_json_Path UTF8String];
    ParseAE parseAE;
    parseAE.dofile(configPath, configEntity);
    _fr = configEntity.fr;
    _total_fr = configEntity.op - configEntity.ip + 1;
    if (configEntity.ddd)
    {
        char *configPath = (char *)[tp_camera_Path UTF8String];
        ParseAE parseAE;
        parseAE.dofile(configPath, camera_configEntity);
    }
    
    NSURL *tmpUrl = [NSURL fileURLWithPath:tp_fg_Path];
    AVAsset *tmpAsset = [AVAsset assetWithURL:tmpUrl];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithAsset:tmpAsset];
    _player = [AVPlayer playerWithPlayerItem:playerItem];
    _timeScale = tmpAsset.duration.timescale;
    _duration = tmpAsset.duration.value/tmpAsset.duration.timescale;
    
    _preMovie = [[LPRGPUImageMovie alloc]initWithPlayerItem:playerItem];
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
                    __block int fr_pts = (int)(self.player.currentTime.value*1.0/self.player.currentTime.timescale*self->_fr);
                    if (fr_pts >= self->_total_fr)
                    {
                        [self.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
                            if (self.player.rate == 0)
                            {
                                [self.player play];
                            }
                            self.audioPlaying = false;
                            self.audioPlayer.currentTime = 0;
                            fr_pts = 0;
                            [self drawAction:fr_pts];
                        }];
                    }
                    else
                    {
                        [self drawAction:fr_pts];
                    }
                });
            });
        }
    }
}

- (void)drawAction:(int)fr_pts
{
    [self->imageFilter renderToTexture:fr_pts];
    [self->_preMovie processPixelBufferAtTimeWithTime:self.player.currentTime];
    self->_texture_ae = self->imageFilter.outputFramebuffer.texture;
    self->_texture_movie = self->_preMovie.outputFramebuffer.texture;
    [self draw];
    if ( !self.audioPlaying )
    {
        self.audioPlaying = YES;
        [self.audioPlayer play];
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

    runAsynchronouslyOnVideoProcessingQueue(^{
        runSynchronouslyOnVideoProcessingQueue(^{
            [LPRGPUImageContext useImageProcessingContext];
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
            [LPRGPUImageContext useImageProcessingContext];
            glUseProgram(self->_program);
            glEnableVertexAttribArray(self->displayPositionAttribute);
            glEnableVertexAttribArray(self->displayTextureCoordinateAttribute);
            [self createDisplayFramebuffer];
        });
    });
    [self setDataAndRefresh];
}

- (void)setDataAndRefresh
{
    [self stopTimer];
    float scale = [UIScreen mainScreen].scale;
    CGSize screenSize = CGSizeMake(self.frame.size.width * scale, self.frame.size.height * scale);

    [self setMaskMovieTexture];
    runAsynchronouslyOnVideoProcessingQueue(^{
        runSynchronouslyOnVideoProcessingQueue(^{
            self->imageFilter = [[LPRGPUImageFilter alloc]initSize:screenSize imageName:nil ae:self->configEntity camera:self->camera_configEntity withFileName:self.resName];
        });
    });
    [self setTimer];
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
    [LPRGPUImageContext useImageProcessingContext];
    
    glGenFramebuffers(1, &displayFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    
    glGenRenderbuffers(1, &displayRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
    
    [[[LPRGPUImageContext sharedImageProcessingContext] context] renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    
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
    [LPRGPUImageContext useImageProcessingContext];
    
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
    [[[LPRGPUImageContext sharedImageProcessingContext] context] presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)draw
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        runSynchronouslyOnVideoProcessingQueue(^{
            
            [LPRGPUImageContext useImageProcessingContext];
            glUseProgram(self->_program);
            [self setDisplayFramebuffer];

            glClearColor(1.0, 1.0, 1.0, 1.0);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glEnable(GL_DEPTH_TEST);

            glActiveTexture(GL_TEXTURE4);
            glBindTexture(GL_TEXTURE_2D,self->_texture_ae);
            glUniform1i(self->displayInputTextureUniform, 4);
            
            glActiveTexture(GL_TEXTURE5);
            glBindTexture(GL_TEXTURE_2D,self->_texture_movie);
            glUniform1i(self->displayInputTextureUniform2, 5);
            
            glVertexAttribPointer(self->displayPositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices_lpr);
            glVertexAttribPointer(self->displayTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates_lpr);
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
            [self presentFramebuffer];
        });
    });
}

- (void)resetByResName:(NSString *)name
{
    self.resName = name;
    [_audioPlayer stop];
    _audioPlayer = nil;
    self.audioPlaying = false;
    [_player.currentItem cancelPendingSeeks];
    [_player.currentItem.asset cancelLoading];
    _player = nil;
    [self setDataAndRefresh];
}

@end
