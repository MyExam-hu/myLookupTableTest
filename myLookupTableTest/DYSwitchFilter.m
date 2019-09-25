//
//  DYSwitchFilter.m
//  myLookupTableTest
//
//  Created by duoyi on 2019/8/22.
//  Copyright © 2019 duoyi. All rights reserved.
//

#import "DYSwitchFilter.h"

NSString *const cameraSwitchVertextShader = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 textureCoordinate;
 attribute vec2 secondTextureCoordinate;
 
 varying vec2 textureCoordinatePort;
 varying vec2 secondTextureCoordinatePort;
 
 void main()
{
    textureCoordinatePort = textureCoordinate;
    secondTextureCoordinatePort = secondTextureCoordinate;
    
    gl_Position = position;
}
 
 );


NSString *const cameraSwitchFragmentShader = SHADER_STRING
(
 precision highp float;
 
 varying highp vec2 textureCoordinatePort;
 varying highp vec2 secondTextureCoordinatePort;
 
 uniform sampler2D sourceImage;
 uniform sampler2D secondSourceImage;
 
 uniform highp float percent;// 0.0 ~ 1.0
 uniform lowp int direction;// 0: 从左到右 1:从右到左
 uniform lowp int firstTextureVisible;//0:第二个纹理是当前滤镜，1:第一个纹理是当前滤镜
 
 void main()
{
    mediump vec4 firstTextureColor = texture2D(sourceImage, textureCoordinatePort);
    mediump vec4 secondTextureColor = texture2D(secondSourceImage, secondTextureCoordinatePort);
    
    if (direction == 0) {
        if (firstTextureVisible == 0){
            if ((1.0 - textureCoordinatePort.x) < percent) {
                gl_FragColor = secondTextureColor;
            }
            else{
                gl_FragColor = firstTextureColor;
            }
        }
        else{
            if (textureCoordinatePort.x < percent) {
                gl_FragColor = secondTextureColor;
            }
            else{
                gl_FragColor = firstTextureColor;
            }
        }
    }
    else if (direction == 1){
        if (firstTextureVisible == 0){
            if (textureCoordinatePort.x < percent) {
                gl_FragColor = secondTextureColor;
            }
            else{
                gl_FragColor = firstTextureColor;
            }
        }
        else{
            if ((1.0 - textureCoordinatePort.x) < percent) {
                gl_FragColor = secondTextureColor;
            }
            else{
                gl_FragColor = firstTextureColor;
            }
        }
    }
}
 
 );

@implementation DYSwitchFilter

- (id)init;
{
    if (!(self = [super initWithVertexShaderFromString:cameraSwitchVertextShader fragmentShaderFromString:cameraSwitchFragmentShader]))
    {
        return nil;
    }
    
    percentUniform = [filterProgram uniformIndex:@"percent"];
    directionUniform = [filterProgram uniformIndex:@"direction"];
    [filterProgram use];
    
    filterInputTextureUniform = [filterProgram uniformIndex:@"sourceImage"];
    filterInputTextureUniform2 = [filterProgram uniformIndex:@"secondSourceImage"];
    
    self.percent = 1.0;
    self.direction = OISwitchFilterDirectionFromLeftToRight;
    
    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setInputRotation:(GPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    [super setInputRotation:newInputRotation atIndex:textureIndex];
    [self setInteger:self.firstFilterVisible ? 1 : 0 forUniformName:@"firstTextureVisible"];
}

- (void)setPercent:(float)percent {
    _percent = percent;
    [self setFloat:_percent forUniform:percentUniform program:filterProgram];
}

- (void)setDirection:(OISwitchFilterDirection)direction {
    _direction = direction;
    [self setFloat:_direction forUniform:directionUniform program:filterProgram];
}

@end
