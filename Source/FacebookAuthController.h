
#import <UIKit/UIKit.h>
#import "Account.h"
#import "WebUtility.h"
#import "WebViewController.h"
#import "NSString.h"
#import "Async.h"
#import "AsyncDelegate.h"

@interface FacebookAuthController : UIViewController <Async, UIWebViewDelegate, NSURLConnectionDelegate>
{
    @private
    Account* _account;
    NSString* _appId;
    id <AsyncDelegate> _delegate;
    NSURLConnection* _connection;
}

- (id) initWithAccount:(Account*)account appId:(NSString*)appId;

- (void) resetConnection;
- (void) removeCookies;

@end
