
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "Account.h"
#import "NSString.h"
#import "Async.h"
#import "AsyncDelegate.h"

@interface TwitterAuthController : UITableViewController <Async, UITableViewDataSource, UITableViewDataSource>
{
@private
    Account* _state;
    ACAccountStore* _accountStore;
	NSMutableArray* _accounts;
    id <AsyncDelegate> _delegate;
    
}

- (id) initWithAccount:(Account*)state;

@end
