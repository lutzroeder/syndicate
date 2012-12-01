
#import <Foundation/Foundation.h>

@interface UIImage (highlightedImage)

+ (UIImage*) highlightedImage:(UIImage*)image;
+ (UIImage*) grayscaleImage:(UIImage*)image;

+ (UIImage*) imageWithSize:(CGSize)imageSize fillColor:(UIColor*)fillColor;
+ (UIImage*) imageWithSize:(CGFloat)imageSize drawCrossWithSize:(CGFloat)size width:(CGFloat)width color:(UIColor*)color;
+ (UIImage*) imageWithSize:(CGFloat)imageSize drawCircleWithSize:(CGFloat)size width:(CGFloat)width color:(UIColor*)color fillColor:(UIColor*)fillColor;

@end
