
#import <Foundation/Foundation.h>
#import "AsyncDelegate.h"

@protocol Async <NSObject>

- (void) start:(id <AsyncDelegate>)delegate;
- (void) cancel;

@end
