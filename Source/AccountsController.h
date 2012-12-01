
#import <Foundation/Foundation.h>
#import "ServiceProvider.h"
#import "AccountTypeService.h"
#import "AccountService.h"
#import "StorageService.h"
#import "UIImage.h"

@interface AccountsController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, AsyncDelegate>
{
    @private
    id<ServiceProvider> _serviceProvider;
    Account* _newAccount;
    Account* _deleteAccount;
}

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider;

- (void) doneClick;

@end
