
#import <Foundation/Foundation.h>
#import "ImageDelegate.h"
#import "UIImage.h"

@interface ImageService : NSObject <NSURLConnectionDelegate>
{
    NSMutableDictionary* _imageViewTable; // NSURL => NSDictionary
    NSMutableDictionary* _dataTable; // NSURL => NSMutableData
    NSMutableDictionary* _imageTable; // NSURL => UIImage 
    NSMutableDictionary* _grayscaleImageTable; // NSURL => UIImage;
}

- (void) loadImage:(NSURL*)url grayscale:(BOOL)grayscale delegate:(id<ImageDelegate>)delegate target:(NSObject*)target;

@end
