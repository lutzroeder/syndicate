
#import <Foundation/Foundation.h>
#import "ServiceProvider.h"
#import "Account.h"
#import "Async.h"
#import "StorageService.h"
#import "NSString.h"
#import "WebUtility.h"

@interface FacebookSync : NSObject <Async, NSURLConnectionDelegate>
{
    @private
    id<ServiceProvider> _serviceProvider;
    Account* _account;
    id <AsyncDelegate> _delegate;
    NSMutableArray* _actions;

    NSURLConnection* _connection;
    NSMutableData* _data;
}

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider account:(Account*)account;

- (void) resetSync;
- (void) resetConnection;

- (void) nextAction;

- (void) deleteReadItems;
- (void) beginDownload;
- (void) endDownload;

- (NSNumber*) parseNextDate:(NSDictionary*)root;
- (NSString*) toHtml:(NSString *)string;

@end
