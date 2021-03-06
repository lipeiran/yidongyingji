//
//  LPRGPUImageFilter.m
//  yidongyingji
//
//  Created by 李沛然 on 2019/8/8.
//  Copyright © 2019 李沛然. All rights reserved.
//

#import "LPRGPUImageFilter.h"

//编辑顶点坐标源数组
GLfloat vertexData_src_lpr[30] = {
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    1.0, 1.0, -0.0f,    1.0f, 1.0f, //右上
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    
    1.0, -1.0, 0.0f,    1.0f, 0.0f, //右下
    -1.0, 1.0, 0.0f,    0.0f, 1.0f, //左上
    -1.0, -1.0, 0.0f,   0.0f, 0.0f, //左下
};

@interface LPRGPUImageFilter ()
{
    AEConfigEntity *configEntity;
    AEConfigEntity *camera_configEntity;

    float cameraX;
    float cameraY;
    float cameraZ;
    
    float _aspectRatio;
    float _perspective_left;
    float _perspective_right;
    float _perspective_bottom;
    float _perspective_top;
    float _perspective_near;
    float _perspective_far;
    
    float _screen_ratio;
}

@end

@implementation LPRGPUImageFilter
@synthesize texture_test = _texture_test;

- (void)addImageAsset:(LPRGPUImage&)image
{
    LPRGPUImage *tmpImage = &image;
    tmpImage->index = _imageAsset_num;
    _imageAsset[_imageAsset_num] = tmpImage;
    _imageAsset_num++;
}

- (void)addImageTexture:(LPRGPUImage &)image
{
    memcpy(image.vertexData_dst_lpr, vertexData_src_lpr, 30*sizeof(GLfloat));
    _texture[_texture_num] = cpp_createImageTexture(image.byte, image.w, image.h, self.texture_size.width, image.vertexData_dst_lpr);
    _texture_num++;
}

- (void)addConfigure
{
    ParseAE parseAE;
    for (int i = 0; i < configEntity->layers_num; i++)
    {
        AELayerEntity &tmpEntity = configEntity->layers[i];
        int tmpAsset_index = parseAE.asset_index_refId(tmpEntity.refId, *configEntity);
        AEAssetEntity tmpAsset = configEntity->assets[tmpAsset_index];
        tmpEntity.layer_w = tmpAsset.w;
        tmpEntity.layer_h = tmpAsset.h;
        tmpEntity.asset_index = tmpAsset_index;
    }
    [self upImageTexture];
}

- (void)upImageTexture
{
    ParseAE parseAE;
    for (int i = 0; i < configEntity->layers_num; i++)
    {
        AELayerEntity &layer = configEntity->layers[i];
        int asset_index = parseAE.asset_index_refId(layer.refId, *configEntity);
        LPRGPUImage *tmpImage = _imageAsset[asset_index];
        [self addImageTexture:*tmpImage];
    }
}

- (GLubyte *)getImageDataWithName:(NSString *)imageName width:(int*)width height:(int*)height
{
    //获取纹理图片
    CGImageRef cgImgRef = [UIImage imageWithContentsOfFile:imageName].CGImage;
    if (!cgImgRef)
    {
        NSLog(@"纹理获取失败");
    }
    //获取图片长、宽
    size_t wd = CGImageGetWidth(cgImgRef);
    size_t ht = CGImageGetHeight(cgImgRef);
    GLubyte *byte = (GLubyte *)calloc(wd * ht * 4, sizeof(GLubyte));
    CGContextRef contextRef = CGBitmapContextCreate(byte, wd, ht, 8, wd * 4, CGImageGetColorSpace(cgImgRef), kCGImageAlphaPremultipliedLast);
    //长宽转成float 方便下面方法使用
    float w = wd;
    float h = ht;
    CGRect rect = CGRectMake(0, 0, w, h);
    CGContextDrawImage(contextRef, rect, cgImgRef);
    //图片绘制完成后，contextRef就没用了，释放
    CGContextRelease(contextRef);
    *width = w;
    *height = h;
    return byte;
}

- (id)initSize:(CGSize)size ae:(AEConfigEntity &)aeConfig camera:(AEConfigEntity &)cameraConfig withFileName:(NSString *)fileName
{
    if (!(self = [super init]))
    {
        return nil;
    }
    self.resName = fileName;
    
    configEntity = &aeConfig;
    camera_configEntity = &cameraConfig;
    if (configEntity->ddd == 1)
    {
        AELayerEntity layer = camera_configEntity->layers[0];
        cameraX = layer.ks.a.k_float[0]-layer.ks.p.k_float[0];
        cameraY = layer.ks.a.k_float[1]-layer.ks.p.k_float[1];
        cameraZ = layer.ks.a.k_float[2]-layer.ks.p.k_float[2];
    }
    
    self.texture_size = size;
    _aspectRatio = size.height/size.width;
    _perspective_left = -1;
    _perspective_right = 1;
    _perspective_bottom = -_aspectRatio;
    _perspective_top = _aspectRatio;
    _perspective_near = 0.1f;
    _perspective_far = 100.0f;
    _screen_ratio = Draw_w/Base_Draw_w;
    runSynchronouslyOnVideoProcessingQueue(^{
        [LPRGPUImageContext useImageProcessingContext];
        GLProgram glProgram1;
        
        char *tmpV = NULL;
        char *tmpF = NULL;
        
        tmpV = (char *)[kPicGPUImageVertexShaderString UTF8String];
        tmpF = (char *)[kPicGPUImagePassthroughFragmentShaderString UTF8String];
 
        self->program = cpp_compileProgramWithContent(glProgram1, tmpV, tmpF);
        
        //从program中获取position 顶点属性
        self->filterPositionAttribute = glGetAttribLocation(self->program, "position");
        //从program中获取textCoordinate 纹理属性
        self->filterTextureCoordinateAttribute = glGetAttribLocation(self->program, "inputTextureCoordinate");
        self->filterInputTextureUniform = glGetUniformLocation(self->program, "inputImageTexture");
        self->_modelViewMartix_S = glGetUniformLocation(self->program, "modelViewMatrix");

        [LPRGPUImageContext useImageProcessingContext];
        glUseProgram(self->program);
        
        glEnableVertexAttribArray(self->filterPositionAttribute);
        glEnableVertexAttribArray(self->filterTextureCoordinateAttribute);
        
        self.outputFramebuffer = [[LPRGPUImageFrameBuffer alloc]initWithSize:CGSizeMake(Draw_w, Draw_h)];

        NSString *resPath = [ResourceBasePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/images",self.resName]];
        
        for (int i = 0; i < self->configEntity->assets_num; i++)
        {
            NSString *imgPath = [resPath stringByAppendingPathComponent:[NSString stringWithFormat:@"img_%d.png",i]];
            int w1,h1;
            GLubyte *byte1 = [self getImageDataWithName:imgPath width:&w1 height:&h1];
            LPRGPUImage *image1 = (LPRGPUImage *)malloc(sizeof(*image1));
            image1->byte = byte1;
            image1->w = w1;
            image1->h = h1;
            [self addImageAsset:*image1];
        }
        [self addConfigure];
    });
    return self;
}

#pragma mark -
#pragma mark Managing the display FBOs

- (void)renderToTexture:(int)fr
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [LPRGPUImageContext useImageProcessingContext];
        glUseProgram(self->program);

        [self.outputFramebuffer activateFramebuffer];

        cpp_glDraw_pre();
        
        ParseAE parseAE;
        int layer_num = self->configEntity->layers_num;
        for (int i = 0; i < layer_num; ++i)
        {
            AELayerEntity tmpEntity = self->configEntity->layers[layer_num-i-1];
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
            float ae_rx = 0.0f;
            float ae_ry = 0.0f;
            float ae_rz = 0.0f;
            int ae_blur = 0;
            float ae_alpha = 0;
            parseAE.get_ae_params_3D(fr, tmpEntity, &ae_r, &ae_rx, &ae_ry, &ae_rz, &ae_s_x, &ae_s_y, &ae_p_x, &ae_p_y, &ae_a_x, &ae_a_y, &ae_alpha, &ae_blur);
            ae_w *= self->_screen_ratio;
            ae_h *= self->_screen_ratio;
            ae_a_x *= self->_screen_ratio;
            ae_a_y *= self->_screen_ratio;
            ae_p_x *= self->_screen_ratio;
            ae_p_y *= self->_screen_ratio;
            
            float ae_a_x_result = (ae_a_x-ae_w/2.0)/self->_texture_size.width*2.0;
            float ae_a_y_result = (ae_h/2.0-ae_a_y)/self->_texture_size.width*2.0;
            
            LPRGPUAnimateAttr animateAttr;
            animateAttr.anchorPX = ae_a_x_result;
            animateAttr.anchorPY = ae_a_y_result;
            animateAttr.rotateAngleX = ae_rx;
            animateAttr.rotateAngleY = ae_ry;
            animateAttr.rotateAngleZ = ae_rz;
            animateAttr.rotateAngle = ae_r;
            if (!tmpEntity.ddd)
            {
                animateAttr.rotateAngleZ = ae_r;
            }
            
            animateAttr.scaleX = ae_s_x;
            animateAttr.scaleY = ae_s_y;
            
            float end_deltaX = (ae_w/2.0-self->_texture_size.width/2.0) + ae_p_x;
            float end_deltaY = (self->_texture_size.height/2.0-ae_h/2.0) - ae_p_y;
            
            animateAttr.deltaX = end_deltaX/self->_texture_size.width*2.0;
            animateAttr.deltaY = end_deltaY/self->_texture_size.width*2.0;
            animateAttr.deltaZ = 0;
            
            cpp_glBindTexture(GL_TEXTURE3, self->_texture[layer_num-i-1]);
            glUniform1i(self->filterInputTextureUniform, 3);
            
            GLfloat *tmpData = self->_imageAsset[tmpEntity.asset_index]->vertexData_dst_lpr;
            glVertexAttribPointer(self->filterPositionAttribute, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)tmpData + 0);
            glVertexAttribPointer(self->filterTextureCoordinateAttribute, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)tmpData + 3);
            
            cpp_generateAndUniform2DMatrix(tmpEntity.ddd, self->cameraX, self->cameraY, self->cameraZ, self->_perspective_left, self->_perspective_right, self->_perspective_bottom, self->_perspective_top, self->_perspective_near, self->_perspective_far, animateAttr.deltaX, animateAttr.deltaY, animateAttr.deltaZ, animateAttr.rotateAngleX, animateAttr.rotateAngleY, animateAttr.rotateAngleZ, animateAttr.scaleX, animateAttr.scaleY, animateAttr.scaleZ, animateAttr.anchorPX, animateAttr.anchorPY, self->_modelViewMartix_S);
            glDrawArrays(GL_TRIANGLES, 0, 6);
        }

        glFinish();
    });
}

@end
