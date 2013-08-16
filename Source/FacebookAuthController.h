
#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "Account.h"
#import "WebUtility.h"
#import "WebViewController.h"
#import "NSString.h"
#import "Async.h"
#import "AsyncDelegate.h"

@interface FacebookAuthController : UITableViewController <Async, UITableViewDataSource, UITableViewDataSource>
{
    @private
    Account* _account;
	NSString* _appId;
    ACAccountStore* _accountStore;
	NSMutableArray* _accounts;
    id <AsyncDelegate> _delegate;
}

- (id) initWithAccount:(Account*)account appId:(NSString*)appId;

@end
