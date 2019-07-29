//
//  GLProgram.hpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/23.
//  Copyright © 2019 李沛然. All rights reserved.
//

#ifndef GLProgram_hpp
#define GLProgram_hpp

#include <stdio.h>
#include <stdlib.h>
#include <string>
#include "GL_Header.h"
#include "utils.hpp"

class GLProgram {
public:
    GLuint program;
    GLuint vertShader;
    GLuint fragShader;
    bool initialized;
    char *vertexShaderLog;
    char *fragmentShaderLog;
    char *programLog;
    
    GLuint initWithVertexShaderString( char *vShaderString, char *fShaderString);
    GLuint initWithVertexShaderPath(char *vShaderPath, char *fShaderPath);
    GLuint uniformIndex(char *uniformName);
    bool link();
    void use();
    void validate();
    void dealloc();
    
private:
    bool compileShader(GLuint &shader, GLenum type, char *shaderString);
};

#endif /* GLProgram_hpp */
