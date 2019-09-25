//
//  LPRGPUCopyWriter.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/17.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "LPRGPUImageMovieWriter.h"
#import <AssetsLibrary/ALAssetsLibrary.h>
#import "LPRGPUImageMovie.h"

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
    int _total_fr;
    BOOL _slider_bool;
    AEConfigEntity configEntity;
    AEConfigEntity camera_configEntity;

    LPRGPUImageFrameBuffer *myFrameBuffer;
    LPRGPUImageMovie *_preMovie;
}

@end

@implementation LPRGPUImageMovieWriter

@synthesize movieWriterContext = _movieWriterContext;

- (id)initWithMovieURL:(NSURL *)newMovieURL withFileName:(NSString *)fileName size:(CGSize)newSize;
{
    return [self initWithMovieURL:newMovieURL withFileName:fileName size:newSize fileType:AVFileTypeQuickTimeMovie outputSettings:nil];
}

- (id)initWithMovieURL:(NSURL *)newMovieURL withFileName:(NSString *)fileName size:(CGSize)newSize fileType:(NSString *)newFileType outputSettings:(NSMutableDictionary *)outputSettings;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    self.resName = fileName;

    videoSize = newSize;
    movieURL = newMovieURL;
    fileType = newFileType;
    
    _movieWriterContext = [[LPRGPUImageContext alloc] init];
    [_movieWriterContext useSharegroup:[[[LPRGPUImageContext sharedImageProcessingContext] context] sharegroup]];
    
    runSynchronouslyOnContextQueue(_movieWriterContext, ^{
        [self->_movieWriterContext useAsCurrentContext];
        
        if ([LPRGPUImageContext supportsFastTextureUpload])
        {
            GLProgram glProgram1;
            //编译program
            char *tmpV = (char *)[kGPUImageVertexShaderString UTF8String];
            char *tmpF = (char *)[kSamplingFragmentShaderC_file_lpr UTF8String];
            self->_program = cpp_compileProgramWithContent(glProgram1, tmpV, tmpF);
        }
        
        //从program中获取position 顶点属性
        self->moviePositionAttribute = glGetAttribLocation(self->_program, "position");
        //从program中获取textCoordinate 纹理属性
        self->movieTextureCoordinateAttribute = glGetAttribLocation(self->_program, "inputTextureCoordinate");
        self->movieInputTextureUniform = glGetUniformLocation(self->_program, "inputImageTexture");
        self->movieInputTextureUniform2 = glGetUniformLocation(self->_program, "inputImageTexture2");

        [self->_movieWriterContext useAsCurrentContext];
        glUseProgram(self->_program);
        glEnableVertexAttribArray(self->moviePositionAttribute);
        glEnableVertexAttribArray(self->movieTextureCoordinateAttribute);
    });
    
    [self setMaskMovieTexture];
    [self commonInit:outputSettings];
    
    return self;
}

- (void)commonInit:(NSDictionary *)settings;
{
    NSLog(@"%s",__func__);
    NSError *error = nil;
    assetWriter = [[AVAssetWriter alloc]initWithURL:movieURL fileType:fileType error:&error];
    if (error != nil)
    {
        NSLog(@"error is:%@\n",error);
    }
    
    if (settings == nil)
    {
        NSMutableDictionary *setting = [[NSMutableDictionary alloc]init];
        [setting setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
        [setting setObject:[NSNumber numberWithInt:videoSize.width] forKey:AVVideoWidthKey];
        [setting setObject:[NSNumber numberWithInt:videoSize.height] forKey:AVVideoHeightKey];
        settings = setting;
    }
    else
    {
        __unused NSString *videoCodec = [settings objectForKey:AVVideoCodecKey];
        __unused NSNumber *width = [settings objectForKey:AVVideoWidthKey];
        __unused NSNumber *height = [settings objectForKey:AVVideoHeightKey];
        
        NSAssert(videoCodec && width && height, @"OutputSettings is missing required parameters.");
    }
    assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
    assetWriterVideoInput.expectsMediaDataInRealTime = NO;
    
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],kCVPixelBufferPixelFormatTypeKey,[NSNumber numberWithInt:videoSize.width], kCVPixelBufferWidthKey,[NSNumber numberWithInt:videoSize.height],kCVPixelBufferHeightKey,nil];
    assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterVideoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    [assetWriter addInput:assetWriterVideoInput];
}

- (void)createDataFBO
{
    NSLog(@"%s",__func__);
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &movieFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    
    if ([LPRGPUImageContext supportsFastTextureUpload])
    {
        CVPixelBufferPoolCreatePixelBuffer(NULL, [assetWriterPixelBufferInput pixelBufferPool], &renderTarget);
        
        CVBufferSetAttachment(renderTarget, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
        CVBufferSetAttachment(renderTarget, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_601_4, kCVAttachmentMode_ShouldPropagate);
        CVBufferSetAttachment(renderTarget, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
        
        CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [_movieWriterContext coreVideoTextureCache], renderTarget,
                                                      NULL, // texture attributes
                                                      GL_TEXTURE_2D,
                                                      GL_RGBA, // opengl format
                                                      (int)videoSize.width,
                                                      (int)videoSize.height,
                                                      GL_BGRA, // native iOS format
                                                      GL_UNSIGNED_BYTE,
                                                      0,
                                                      &renderTexture);
        
        glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
    }
    
    __unused GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
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

- (void)destroyDataFBO;
{
    runSynchronouslyOnContextQueue(_movieWriterContext, ^{
        [self->_movieWriterContext useAsCurrentContext];
        
        if (self->movieFramebuffer)
        {
            glDeleteFramebuffers(1, &self->movieFramebuffer);
            self->movieFramebuffer = 0;
        }
        
        if (self->movieRenderbuffer)
        {
            glDeleteRenderbuffers(1, &self->movieRenderbuffer);
            self->movieRenderbuffer = 0;
        }
        
        if ([LPRGPUImageContext supportsFastTextureUpload])
        {
            if (self->renderTexture)
            {
                CFRelease(self->renderTexture);
            }
            if (self->renderTarget)
            {
                CVPixelBufferRelease(self->renderTarget);
            }
        }
    });
}

- (void)renderAtInternalSizeUsingTexture
{
    [_movieWriterContext useAsCurrentContext];
    [self setFilterFBO];
    glUseProgram(_program);
    
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, _texture_test);
    glUniform1i(movieInputTextureUniform, 4);
    
    glActiveTexture(GL_TEXTURE5);
    glBindTexture(GL_TEXTURE_2D, _texture_test2);
    glUniform1i(movieInputTextureUniform2, 5);
    
    glVertexAttribPointer(moviePositionAttribute, 2, GL_FLOAT, 0, 0, imageVertices_lpr);
    glVertexAttribPointer(movieTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates_lpr);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glFinish();
}

- (void)startRecording
 {
     NSLog(@"%s",__func__);
     NSString *resPath = [ResourceBasePath stringByAppendingPathComponent:self.resName];
     NSString *tp_fg_Path = [resPath stringByAppendingPathComponent:@"tp_fg.mp4"];
     
     [self->assetWriter startWriting];
     [self->assetWriter startSessionAtSourceTime:CMTimeMake(0, _fr)];
     
     self->imageFilter = [[LPRGPUImageFilter alloc]initSize:CGSizeMake(Draw_w, Draw_h) ae:self->configEntity camera:self->camera_configEntity withFileName:self.resName];
     NSURL *tmpUrl = [NSURL fileURLWithPath:tp_fg_Path];
     AVAsset *tmpAsset = [AVAsset assetWithURL:tmpUrl];
     _preMovie = [[LPRGPUImageMovie alloc]initWithAsset:tmpAsset];
     [_preMovie startProcessing];
     
     runAsynchronouslyOnContextQueue(_movieWriterContext, ^{
         for (int i = 0; i < self->_total_fr; i++)
         {
             if (self.progressBlock)
             {
                 self.progressBlock((i*1.0+1)/self->_total_fr);
             }
             [self->imageFilter renderToTexture:i];
             if (i > 0)
             {
                 [self->_preMovie copyNextFrame];
             }
             runSynchronouslyOnContextQueue(self->_movieWriterContext, ^{
                 [self->_movieWriterContext useAsCurrentContext];
                 glUseProgram(self->_program);
                 self->_texture_test = self->imageFilter.outputFramebuffer.texture;
                 self->_texture_test2 = self->_preMovie.outputFramebuffer.texture;
                 [self renderAtInternalSizeUsingTexture];
                 CVPixelBufferRef pixel_buffer = self->renderTarget;
                 CVPixelBufferLockBaseAddress(pixel_buffer, 0);
                 
                 while( ! self->assetWriterVideoInput.readyForMoreMediaData )
                 {
                     NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
                     [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
                 }
                 if(self->assetWriter.status == AVAssetWriterStatusWriting)
                 {
                     if (![self->assetWriterPixelBufferInput appendPixelBuffer:pixel_buffer withPresentationTime:CMTimeMake(i, self->_fr)])
                     {
                         NSLog(@"write failed！！！");
                     }
                     else
                     {
                         NSLog(@"write success ~~");
                     }
                 }
                 CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
             });
         }
         [self stopRecording];
     });

     return;
 }

- (void)stopRecording
{
    NSLog(@"%s",__func__);
    [self finishRecording];
}

- (void)finishRecording;
{
    [self finishRecordingWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *resPath = [ResourceBasePath stringByAppendingPathComponent:self.resName];
            NSString *wayPath = [resPath stringByAppendingPathComponent:@"music.mp3"];
            NSString *easyPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/Movie%@.mp4",self.resName]];
            NSString *destPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie_result.mp4"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:destPath])
            {
                [[NSFileManager defaultManager] removeItemAtPath:destPath error:nil];
            }
            [self audioVedioMerge:[NSURL fileURLWithPath:wayPath] vedioUrl:[NSURL fileURLWithPath:easyPath] destUrl:[NSURL fileURLWithPath:destPath]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存沙盒成功" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        });
    }];
}

- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler;
{
    runSynchronouslyOnContextQueue(_movieWriterContext, ^{
        [self->assetWriterVideoInput markAsFinished];
        [self->assetWriter finishWritingWithCompletionHandler:(handler ?: ^{
            NSLog(@"结束录制");
        })];
    });
}

- (void)setMaskMovieTexture
{
    NSString *resPath = [ResourceBasePath stringByAppendingPathComponent:self.resName];
    NSString *tp_json_Path = [resPath stringByAppendingPathComponent:@"tp.json"];
    NSString *tp_camera_Path = [resPath stringByAppendingPathComponent:@"tp_camera.json"];
    
    char *configPath = (char *)[tp_json_Path UTF8String];
    ParseAE parseAE;
    parseAE.dofile(configPath, configEntity);
    _fr = configEntity.fr;
    _total_fr = configEntity.op+1;
    if (configEntity.ddd)
    {
        char *configPath = (char *)[tp_camera_Path UTF8String];
        ParseAE parseAE;
        parseAE.dofile(configPath, camera_configEntity);
    }
}

- (void)audioVedioMerge:(NSURL *)audioUrl vedioUrl:(NSURL *)vedioUrl destUrl:(NSURL *)destUrl
{
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    NSError *error;
    
    AVMutableCompositionTrack *audioCompostionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //音频文件资源
    AVURLAsset  *audioAsset = [[AVURLAsset alloc] initWithURL:audioUrl options:nil];
    CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
    [audioCompostionTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:&error];
    
    //视频文件资源
    AVMutableCompositionTrack *vedioCompostionTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVURLAsset *vedioAsset = [[AVURLAsset alloc] initWithURL:vedioUrl options:nil];
    CMTimeRange vedio_timeRange = CMTimeRangeMake(kCMTimeZero, vedioAsset.duration);
    [vedioCompostionTrack insertTimeRange:vedio_timeRange ofTrack:[[vedioAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:&error];
    
    // presetName 与 outputFileType 要对应  导出合并的音频
    AVAssetExportSession* assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset640x480];
    assetExportSession.outputURL = destUrl;
    assetExportSession.outputFileType = @"com.apple.quicktime-movie";
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%@",assetExportSession.error);
        });
    }];
}

@end
