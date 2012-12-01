
#import <Foundation/Foundation.h>

@protocol AsyncDelegate <NSObject>

@required

- (void) asyncDidCancel;
- (void) asyncDidFinish;
- (void) asyncDidFailWithError:(NSError*)error;

@optional

- (void) asyncTextChanged:(NSString*)text;
- (void) asyncProgressChanged:(float)progress;

@end
