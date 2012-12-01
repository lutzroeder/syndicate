
#import <Foundation/Foundation.h>

@protocol ImageDelegate <NSObject>

@required

- (void) didFinishLoadingImage:(UIImage*)image target:(NSObject*)target;

@end
