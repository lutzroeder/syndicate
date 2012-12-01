
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>
#import "Account.h"
#import "WebUtility.h"
#import "WebViewController.h"
#import "NSString.h"
#import "Async.h"
#import "AsyncDelegate.h"

@interface TwitterAuthController : UIViewController <Async, UIWebViewDelegate, NSURLConnectionDelegate>
{
@private
    Account* _account;
    NSString* _consumerKey;
    NSString* _consumerSecret;
    id <AsyncDelegate> _delegate;
    NSURLConnection* _connection;
    NSMutableData* _data;
}

- (id) initWithAccount:(Account*)account consumerKey:(NSString*)consumerKey consumerSecret:(NSString*)consumerSecret;

- (NSURLRequest*) createRequest:(NSURL*)url token:(NSString*)token tokenSecret:(NSString*)tokenSecret;

- (void) resetConnection;
- (void) removeCookies;

@end
