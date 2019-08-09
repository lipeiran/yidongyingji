//
//  LPRGPUImageFilter.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "LPRGPUImageFilter.h"
#import "Parse_AE.h"

//编辑顶点坐标源数组
GLfloat vertexData_src_lpr[30] = {
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    1.0, 1.0, -0.0f,    1.0f, 1.0f, //右上
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    -1.0, -1.0, 0.0f,   0.0f, 0.0f, //左下
};

//编辑顶点坐标目标数组
GLfloat vertexData_dst_lpr[30] = {
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    1.0, 1.0, -0.0f,    1.0f, 1.0f, //右上
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    -1.0, -1.0, 0.0f,   0.0f, 0.0f, //左下
};

static const GLfloat imageVerticesaa[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};

static const GLfloat noRotationTextureCoordinatesaa[] = {
    0.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f,
};

NSString *const kGPUImageVertexShaderString = SHADER_STRING
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

NSString *const kGPUImagePassthroughFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
 );

NSString *const kPicGPUImageVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 varying vec2 textureCoordinate;
 uniform mat4 modelViewMatrix;
 void main()
 {
     gl_Position = modelViewMatrix * position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const kPicGPUImagePassthroughFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 void main()
 {
    lowp vec4 tex = texture2D(inputImageTexture, vec2(textureCoordinate.x,1.0-textureCoordinate.y));
    gl_FragColor = tex;
 }
 );


@interface LPRGPUImageFilter ()
{
    AEConfigEntity configEntity;
    float _aspectRatio;
    float _perspective_left;
    float _perspective_right;
    float _perspective_bottom;
    float _perspective_top;
    float _perspective_near;
    float _perspective_far;
}

@end

@implementation LPRGPUImageFilter
@synthesize texture_test = _texture_test;

- (void)addImageAsset:(GPUImage &)image
{
    GPUImage *tmpImage = &image;
    tmpImage->index = _imageAsset_num;
    _imageAsset[_imageAsset_num] = tmpImage;
    _imageAsset_num++;
}

- (void)addImageTexture:(GPUImage &)image
{
    memcpy(vertexData_dst_lpr, vertexData_src_lpr, 30*sizeof(GLfloat));
    _texture[_texture_num] = cpp_createImageTexture(image.byte, image.w, image.h, self.texture_size.width, vertexData_dst_lpr);
    _texture_num++;
}

- (void)addConfigure:(char *)configFilePath
{
    ParseAE parseAE;
    parseAE.dofile(configFilePath, configEntity);
    for (int i = 0; i < configEntity.layers_num; i++)
    {
        AELayerEntity &tmpEntity = configEntity.layers[i];
        int tmpAsset_index = parseAE.asset_index_refId(tmpEntity.refId, configEntity);
        AEAssetEntity tmpAsset = configEntity.assets[tmpAsset_index];
        tmpEntity.layer_w = tmpAsset.w;
        tmpEntity.layer_h = tmpAsset.h;
    }
    
    [self upImageTexture];
}

- (void)upImageTexture
{
    ParseAE parseAE;
    for (int i = 0; i < configEntity.layers_num; i++)
    {
        AELayerEntity &layer = configEntity.layers[i];
        int asset_index = parseAE.asset_index_refId(layer.refId, configEntity);
        GPUImage *tmpImage = _imageAsset[asset_index];
        [self addImageTexture:*tmpImage];
    }
}

- (id)initSize:(CGSize)size imageName:(nullable NSString *)imageName
{
    if (!(self = [super init]))
    {
        return nil;
    }
    if (imageName == NULL)
    {
        _ae_b = YES;
    }
    self.texture_size = size;
    _aspectRatio = size.height/size.width;
    _perspective_left = -1;
    _perspective_right = 1;
    _perspective_bottom = -_aspectRatio;
    _perspective_top = _aspectRatio;
    _perspective_near = 0.1f;
    _perspective_far = 100.0f;
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        GLProgram glProgram1;
        
        char *tmpV = NULL;
        char *tmpF = NULL;
        
        if (self->_ae_b)
        {
            tmpV = (char *)[kPicGPUImageVertexShaderString UTF8String];
            tmpF = (char *)[kPicGPUImagePassthroughFragmentShaderString UTF8String];
        }
        else
        {
            tmpV = (char *)[kGPUImageVertexShaderString UTF8String];
            tmpF = (char *)[kGPUImagePassthroughFragmentShaderString UTF8String];
        }
        
        self->program = cpp_compileProgramWithContent(glProgram1, tmpV, tmpF);
        
        if (self->_ae_b)
        {
            //从program中获取position 顶点属性
            self->filterPositionAttribute = glGetAttribLocation(self->program, "position");
            //从program中获取textCoordinate 纹理属性
            self->filterTextureCoordinateAttribute = glGetAttribLocation(self->program, "inputTextureCoordinate");
            self->filterInputTextureUniform = glGetUniformLocation(self->program, "inputImageTexture");
            self->_modelViewMartix_S = glGetUniformLocation(self->program, "modelViewMatrix");
        }
        else
        {
            //从program中获取position 顶点属性
            self->filterPositionAttribute = glGetAttribLocation(self->program, "position");
            //从program中获取textCoordinate 纹理属性
            self->filterTextureCoordinateAttribute = glGetAttribLocation(self->program, "inputTextureCoordinate");
            self->filterInputTextureUniform = glGetUniformLocation(self->program, "inputImageTexture");
        }

        [GPUImageContext useImageProcessingContext];
        glUseProgram(self->program);
        
        glEnableVertexAttribArray(self->filterPositionAttribute);
        glEnableVertexAttribArray(self->filterTextureCoordinateAttribute);
        
        self.outputFramebuffer = [[LPRGPUImageFrameBuffer alloc]initWithSize:CGSizeMake(480, 640)];
        
        if (self->_ae_b)
        {
            char *configPath = (char *)[[[NSBundle mainBundle]pathForResource:@"tp" ofType:@"json"] UTF8String];
            int w1,h1,w2,h2,w3,h3,w4,h4;
            GLubyte *byte1 = NULL,*byte2 = NULL,*byte3 = NULL,*byte4 = NULL;
            byte1 = [OpenGLES2DTools getImageDataWithName:@"img_0.png" width:&w1 height:&h1];
            byte2 = [OpenGLES2DTools getImageDataWithName:@"img_1.png" width:&w2 height:&h2];
            byte3 = [OpenGLES2DTools getImageDataWithName:@"img_2.png" width:&w3 height:&h3];
            byte4 = [OpenGLES2DTools getImageDataWithName:@"img_3.png" width:&w4 height:&h4];
            GPUImage image1;
            image1.byte = byte1;
            image1.w = w1;
            image1.h = h1;
            GPUImage image2;
            image2.byte = byte2;
            image2.w = w2;
            image2.h = h2;
            GPUImage image3;
            image3.byte = byte3;
            image3.w = w3;
            image3.h = h3;
            GPUImage image4;
            image4.byte = byte4;
            image4.w = w4;
            image4.h = h4;
            
            [self addImageAsset:image1];
            [self addImageAsset:image2];
            [self addImageAsset:image3];
            [self addImageAsset:image4];
            [self addConfigure:configPath];
        }
        else
        {
            GLubyte *byte = NULL;
            int w;
            int h;
            byte = [OpenGLES2DTools getImageDataWithName:imageName width:&w height:&h];
            
            self->_texture_test = cpp_setupTexture(GL_TEXTURE4);
            cpp_upGPUTexture(w, h, byte);
        }
        
        [self renderToTexture];
    });
    
    return self;
}

#pragma mark -
#pragma mark Managing the display FBOs

- (void)renderToTexture
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        glUseProgram(self->program);
        
        [self.outputFramebuffer activateFramebuffer];
        
        cpp_glDraw_pre();
        
        if (self->_ae_b)
        {
            ParseAE parseAE;
            int fr = 500;
            int layer_num = self->configEntity.layers_num;
            for (int i = 0; i < layer_num; ++i)
            {
                AELayerEntity tmpEntity = self->configEntity.layers[layer_num-i-1];
                if (fr < tmpEntity.ip || fr > tmpEntity.op)
                {
                    continue;
                }
                float ae_w = tmpEntity.layer_w;
                float ae_h = tmpEntity.layer_h;
                float ae_a_x = 0.0f;
                float ae_a_y = 0.0f;
                float ae_p_x = 0.0f;
                float ae_p_y = 0.0f;
                float ae_s_x = 0.0f;
                float ae_s_y = 0.0f;
                float ae_r = 0.0f;
                int ae_blur = 0;
                float ae_alpha = 0;
                
                parseAE.get_ae_params(fr, tmpEntity, &ae_r, &ae_s_x, &ae_s_y, &ae_p_x, &ae_p_y, &ae_a_x, &ae_a_y, &ae_alpha, &ae_blur);
                
                float ae_a_x_result = (ae_a_x-ae_w/2.0)/self->_texture_size.width*2.0;
                float ae_a_y_result = (ae_h/2.0-ae_a_y)/self->_texture_size.width*2.0;
                
                GPUAnimateAttr animateAttr;
                animateAttr.anchorPX = ae_a_x_result;
                animateAttr.anchorPY = ae_a_y_result;
                animateAttr.rotateAngleZ = ae_r;
                animateAttr.scaleX = ae_s_x;
                animateAttr.scaleY = ae_s_y;
                
                float end_deltaX = (ae_w/2.0-self->_texture_size.width/2.0) + ae_p_x;
                float end_deltaY = (self->_texture_size.height/2.0-ae_h/2.0) - ae_p_y;
                
                animateAttr.deltaX = end_deltaX/self->_texture_size.width*2.0;
                animateAttr.deltaY = end_deltaY/self->_texture_size.width*2.0;
                
                cpp_glBindTexture(GL_TEXTURE3, self->_texture[layer_num-i-1]);
                glUniform1i(self->filterInputTextureUniform, 3);
                
                glVertexAttribPointer(self->filterPositionAttribute, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)vertexData_dst_lpr + 0);
                glVertexAttribPointer(self->filterTextureCoordinateAttribute, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)vertexData_dst_lpr + 3);
                
                cpp_generateAndUniform2DMatrix(self->_perspective_left, self->_perspective_right, self->_perspective_bottom, self->_perspective_top, self->_perspective_near, self->_perspective_far, animateAttr.deltaX, animateAttr.deltaY, animateAttr.deltaZ, animateAttr.rotateAngleX, animateAttr.rotateAngleY, animateAttr.rotateAngleZ, animateAttr.scaleX, animateAttr.scaleY, animateAttr.scaleZ, animateAttr.anchorPX, animateAttr.anchorPY, self->_modelViewMartix_S);
                glDrawArrays(GL_TRIANGLES, 0, 6);
            }
        }
        else
        {
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D, self->_texture_test);
            glUniform1i(self->filterInputTextureUniform, 2);
            
            glVertexAttribPointer(self->filterPositionAttribute, 2, GL_FLOAT, 0, 0, imageVerticesaa);
            glVertexAttribPointer(self->filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinatesaa);
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        }

    });
}

@end