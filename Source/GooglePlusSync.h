
#import <Foundation/Foundation.h>
#import "ServiceProvider.h"
#import "Account.h"
#import "Async.h"
#import "NSString.h"
#import "WebUtility.h"

@interface GooglePlusSync : NSObject <NSURLConnectionDelegate, Async>
{
    @private
    id<ServiceProvider> _serviceProvider;
    Account* _account;
    NSString* _clientId;
    NSString* _clientSecret;
    id<AsyncDelegate> _delegate;
    
    NSMutableArray* _actions;
    
    NSURLConnection* _connection;
    NSMutableData* _data;
    
    float _progress;
    NSString* _authorization;
}

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider account:(Account*)account clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret;

- (void) resetConnection;
- (void) resetSync;

- (void) nextAction;

- (void) beginAuthentication;
- (void) endAuthentication;
- (void) beginDownload;
- (void) endDownload;

@end
