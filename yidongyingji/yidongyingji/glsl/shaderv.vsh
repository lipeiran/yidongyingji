attribute vec4 position;
attribute vec4 positionColor;
attribute vec2 textCoordinate;
uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;
varying lowp vec2 varyTextCoord;
void main(){varyTextCoord = textCoordinate;gl_Position = projectionMatrix * modelViewMatrix * position;}
