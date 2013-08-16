
#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "ServiceProvider.h"
#import "Async.h"
#import "TwitterAuthController.h"
#import "WebUtility.h"
#import "StorageService.h"

@interface TwitterSync : NSObject <Async>
{
    @private
    id<ServiceProvider> _serviceProvider;
	ACAccountStore* _accountStore;
	ACAccount* _account;
    Account* _state;
    id <AsyncDelegate> _delegate;

    NSMutableArray* _actions;

    SLRequest* _request;
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

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider account:(Account*)account;

- (void) nextAction;

- (void) findAccount;
- (void) deleteReadItems;
- (void) setupFriendsTimeline;
- (void) setupMentions;
- (void) setupConnection;
- (void) startConnection;
- (void) endConnection;
- (void) resetConnection;
- (void) resetSync;

@end
