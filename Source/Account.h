
#import <Foundation/Foundation.h>
#import "Async.h"
#import "AsyncDelegate.h"
#import "UIImage.h"

@interface Account : NSObject
{
    @private
    NSMutableDictionary* _state;
    UIImage* _image;
    UIImage* _grayscaleImage;
}

- (NSString*) name;
- (UIImage*) image;
- (UIImage*) grayscaleImage;

- (id <Async>) authenticate;
- (id <Async>) synchronize;

- (NSString*) identifier;

- (id) objectForKey:(NSString*)key;
- (void) setObject:(id)value forKey:(NSString*)key;
- (void) removeObjectForKey:(NSString*)key;
- (NSEnumerator*) keyEnumerator;

@end
