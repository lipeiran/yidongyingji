//
//  GLProgram.cpp
//  yidongyingji
//
//  Created by 李沛然 on 2019/7/23.
//  Copyright © 2019 李沛然. All rights reserved.
//

#include "GLProgram.hpp"

bool GLProgram::compileShader(GLuint &shader, GLenum type, char *shaderString)
{
    GLint status;
    const GLchar *source;
    source = (GLchar *)shaderString;
    if (!source)
    {
        printf("Failed to load vertex shader");
        return false;
    }
    
    shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status != GL_TRUE)
    {
        GLint logLength;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0)
        {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(shader, logLength, &logLength, log);
            if (shader == vertShader)
            {
                vertexShaderLog = (GLchar *)malloc(logLength);
                strcpy(vertexShaderLog, log);
            }
            else
            {
                fragmentShaderLog = (GLchar *)malloc(logLength);
                strcpy(vertexShaderLog, log);
            }
            free(log);
        }
    }
    return status == GL_TRUE;
}

GLuint GLProgram::initWithVertexShaderString( char *vShaderString, char *fShaderString)
{
    initialized = false;
    program = glCreateProgram();
    if (compileShader(vertShader, GL_VERTEX_SHADER, vShaderString) == false)
    {
        printf("Failed to compile vertex shader");
    }
    
    // create and compile fragment shader
    if (compileShader(fragShader, GL_FRAGMENT_SHADER, fShaderString) == false)
    {
        printf("Failed to compile fragment shader");
    }
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    return program;
}

GLuint GLProgram::initWithVertexShaderPath(char *vShaderPath, char *fShaderPath)
{
    long vShFileSize = 0;
    long fShFileSize = 0;
    char *vShaderSource = LoadFileContent(vShaderPath, vShFileSize);
    char *fShaderSource = LoadFileContent(fShaderPath, fShFileSize);
    return initWithVertexShaderString(vShaderSource, fShaderSource);
}

GLuint GLProgram::uniformIndex(char *uniformName)
{
    return glGetUniformLocation(program, uniformName);
}

bool GLProgram::link()
{
    GLint status;
    glLinkProgram(program);
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
    {
        return false;
    }
    if (vertShader)
    {
        glDeleteShader(vertShader);
        vertShader = 0;
    }
    if (fragShader)
    {
        glDeleteShader(fragShader);
        fragShader = 0;
    }
    initialized = true;
    return false;
}

void GLProgram::use()
{
    glUseProgram(program);
}

void GLProgram::validate()
{
    GLint logLength;
    glValidateProgram(program);
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        programLog = (GLchar *)malloc(logLength);
        strcpy(programLog, log);
        free(log);
    }
}

void GLProgram::dealloc()
{
    if (vertShader)
    {
        glDeleteShader(vertShader);
    }
    if (fragShader)
    {
        glDeleteShader(fragShader);
    }
    if (program)
    {
        glDeleteProgram(program);
    }
}

