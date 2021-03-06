//
//  LPRGPUCopyWriter.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/17.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import "LPRGPUImageContext.h"
#import "GLProgram.hpp"
#import "utils.hpp"
#import "LPRGPUImageFilter.h"

typedef void(^WriteBlock)(CGFloat percent);


@interface LPRGPUImageMovieWriter : NSObject
{
    NSURL *movieURL;
    NSString *fileType;
    AVAssetWriter *assetWriter;
    AVAssetWriterInput *assetWriterAudioInput;
    AVAssetWriterInput *assetWriterVideoInput;
    AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferInput;
    
    LPRGPUImageContext *_movieWriterContext;
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;
    CGSize videoSize;
    
    LPRGPUImageFilter *imageFilter;
}
@property(readonly, nonatomic) CGSize sizeInPixels;
@property(nonatomic, retain) LPRGPUImageContext * _Nullable movieWriterContext;
@property (nonatomic, copy, nullable) WriteBlock progressBlock;
@property (nonatomic, copy) NSString *resName;

// Initialization and teardown
- (id _Nullable )initWithMovieURL:(NSURL *_Nullable)newMovieURL withFileName:(NSString *)fileName size:(CGSize)newSize;

// Managing the data FBO
- (void)createDataFBO;
- (void)destroyDataFBO;

// 开始导出
- (void)startRecording;

// 结束导出
- (void)stopRecording;

@end

