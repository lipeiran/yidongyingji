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
#import "GPUImageFilter.hpp"
#import "OpenGLES2DTools.h"
#import "GPUImageContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface OpenGLES2DView : UIView
{
    GPUImageFilter filter;
    float scale;
}

//@property (nonatomic, strong) CAEAGLLayer *eaglLayer;
//@property (nonatomic, strong) EAGLContext *context;

@end

NS_ASSUME_NONNULL_END

