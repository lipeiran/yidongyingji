//
//  OpenGLES2DTools.h
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/29.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OpenGLES2DTools : NSObject

+ (GLubyte *)getImageDataWithName:(NSString *)imageName width:(int*)width height:(int*)height;

@end

NS_ASSUME_NONNULL_END
