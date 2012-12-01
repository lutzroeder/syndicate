
#import <Foundation/Foundation.h>
#import "ServiceProvider.h"
#import "Async.h"
#import "TwitterAuthController.h"
#import "WebUtility.h"
#import "StorageService.h"

@interface TwitterSync : NSObject <NSURLConnectionDelegate, Async>
{
    @private
    id<ServiceProvider> _serviceProvider;
    TwitterAuthController* _authenticate;
    Account* _account;
    id <AsyncDelegate> _delegate;

    NSMutableArray* _actions;

    NSURLConnection* _connection;
    NSMutableData* _data;

    NSString* _url;
    NSString* _key;
    NSNumber* _since;
    NSNumber* _max;
    NSNumber* _status;
    NSInteger _count;
    float _progress;
    float _progressMax;
}

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider account:(Account*)account authenticate:(TwitterAuthController*)authenticate;

- (void) nextAction;

- (void) deleteReadItems;

- (void) setupFriendsTimeline;
- (void) setupMentions;

- (void) setupConnection;
- (void) startConnection;
- (void) endConnection;

- (void) resetConnection;
- (void) resetSync;

@end
