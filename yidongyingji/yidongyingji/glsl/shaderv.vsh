
//顶点坐标
attribute vec4 position;
//坐标颜色
attribute vec4 positionColor;
//纹理坐标
attribute vec2 textCoordinate;
//投影矩阵
uniform mat4 projectionMatrix;
//模型视图矩阵
uniform mat4 modelViewMatrix;
//模型视图矩阵
uniform mat4 ViewViewMatrix;
//传递给片元着色器的纹理
varying lowp vec2 varyTextCoord;

void main()
{
    //传递纹理坐标
    varyTextCoord = textCoordinate;
    //内建变量赋值 投影矩阵 * 模型视图矩阵 * 顶点坐标
    gl_Position = projectionMatrix * ViewViewMatrix * modelViewMatrix * position;
}
