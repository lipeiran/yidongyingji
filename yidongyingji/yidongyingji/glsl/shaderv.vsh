attribute vec4 position;
attribute vec2 textCoordinate;
varying highp vec2 varyTextCoord;
uniform vec4 projection;
uniform vec4 model;
void main()
{
    //varying 修饰，将纹理坐标传递到片元着色器
    varyTextCoord = textCoordinate;
    //给内建变量赋值
    gl_Position = projection * model * position;
}
