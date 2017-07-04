#import "GPUImageFilter.h"
/**
 * Created by Alaric Cole
 * Allows adjustment of color temperature in terms of what an image was effectively shot in. This means higher Kelvin values will warm the image, while lower values will cool it. 
 
 */
@interface GPUImageWhiteBalanceFilter : GPUImageFilter
{
    GLint temperatureUniform, tintUniform;
}
//choose color temperature, in degrees Kelvin（最大值10000，最小值1000，正常值5000）
@property(readwrite, nonatomic) CGFloat temperature;

//adjust tint to compensate（最大值1000，最小值-1000，正常值0.0）
@property(readwrite, nonatomic) CGFloat tint;

@end
