
#import <Foundation/Foundation.h>
#import "Account.h"
#import "WebUtility.h"
#import "WebViewController.h"
#import "NSString.h"
#import "Async.h"
#import "AsyncDelegate.h"

@interface GoogleReaderAuthController : UIViewController <Async, UIWebViewDelegate, NSURLConnectionDelegate>
{
    @private
    Account* _account;
    NSString* _clientId;
    NSString* _clientSecret;
    id <AsyncDelegate> _delegate;
    NSURLConnection* _connection;
    NSMutableData* _data;
}

- (id) initWithAccount:(Account*)account clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret;

- (void) resetConnection;
- (void) removeCookies;

@end
