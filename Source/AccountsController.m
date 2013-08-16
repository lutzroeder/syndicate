
#import "AccountsController.h"

@implementation AccountsController

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider
{
    self = [super init];

    self.title = NSLocalizedString(@"Accounts", nil);
    
    _serviceProvider = [serviceProvider retain];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneClick)] autorelease];
    
    UITableView* tableView = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped] autorelease];
    tableView.dataSource = self;
    tableView.delegate = self;
    self.tableView = tableView;
    
    return self;
}

- (void) dealloc
{
    [_newAccount release];
    [_deleteAccount release];    
    [_serviceProvider release];
    [super dealloc];
}

- (void) accountRefresh:(NSNotification*)notification
{
    [self.tableView reloadData];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountRefresh:) name:@"AccountRefresh" object:nil];

    AccountTypeService* accountTypeService = [_serviceProvider serviceWithName:@"AccountTypeService"];
    for (int i = 0; i < accountTypeService.accountTypes.count; i++)
    {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void) viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AccountRefresh" object:nil];

    [super viewDidDisappear:animated];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

- (void) doneClick
{
    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
    [storageService save];
    
    [self dismissViewControllerAnimated:YES completion:nil];

    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"StorageRefresh" object:self userInfo:nil]];
}

- (NSIndexPath*) indexPathForAccount:(Account*)account
{
    AccountService* accountService = [_serviceProvider serviceWithName:@"AccountService"];
    AccountTypeService* accountTypeService = [_serviceProvider serviceWithName:@"AccountTypeService"];
    NSInteger index = 0;
    for (index = 0; index < accountTypeService.accountTypes.count; index++)
    {
        if (account == [accountService accountForType:[accountTypeService.accountTypes objectAtIndex:index]])
        {
            return [NSIndexPath indexPathForRow:index inSection:0];
        }
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView 
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    AccountTypeService* accountTypeService = [_serviceProvider serviceWithName:@"AccountTypeService"];
    return accountTypeService.accountTypes.count;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 0)
    {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (cell == nil)
        {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
        }	

        AccountTypeService* accountTypeService = [_serviceProvider serviceWithName:@"AccountTypeService"];
        NSString* accountType = [accountTypeService.accountTypes objectAtIndex:indexPath.row];

        AccountService* accountService = [_serviceProvider serviceWithName:@"AccountService"];
        Account* account = [accountService accountForType:accountType];
        if (account != nil)
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.text = account.name;
            cell.imageView.image = account.image;
        }
        else
        {
            Account* account = [[NSClassFromString(accountType) alloc] initWithServiceProvider:_serviceProvider];

            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = account.name;
            cell.imageView.image = account.grayscaleImage;
            
            [account release];
        }

        return cell;
    }

    return nil;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 0)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        AccountTypeService* accountTypeService = [_serviceProvider serviceWithName:@"AccountTypeService"];
        NSString* accountType = [accountTypeService.accountTypes objectAtIndex:indexPath.row];
        
        AccountService* accountService = [_serviceProvider serviceWithName:@"AccountService"];
        Account* account = [accountService accountForType:accountType];

        if (account != nil)
        {
            [_deleteAccount release];
            _deleteAccount = [account retain];

            UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
            
            UIActionSheet* actionSheet = [[UIActionSheet alloc] init];
            actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
            actionSheet.destructiveButtonIndex = 0;
            actionSheet.cancelButtonIndex = 1;
            actionSheet.delegate = self;
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Sign Out", nil)];
            [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [actionSheet showFromRect:CGRectMake(0, cell.bounds.size.height / 2, cell.bounds.size.width, 0) inView:cell animated:YES];
            [actionSheet release];
        }
        else
        {
            // Create Account
            [_newAccount release];
            _newAccount = [[NSClassFromString(accountType) alloc] initWithServiceProvider:_serviceProvider];            
            UIViewController* viewController = (UIViewController*) _newAccount.authenticate;            
            [self.navigationController pushViewController:viewController animated:YES];
			
			[_newAccount.authenticate start:self];
        }
    }	    
}

- (void) actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        // Delete Account
        NSIndexPath* indexPath = [self indexPathForAccount:_deleteAccount];

        StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
        [storageService deleteAccount:_deleteAccount.identifier];
        
        AccountService* accountService = [_serviceProvider serviceWithName:@"AccountService"];
        [accountService removeAccount:_deleteAccount];
        [_deleteAccount.authenticate cancel];
        [_deleteAccount release];
        _deleteAccount = nil;
        
        if (indexPath != nil)
        {
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void) asyncDidCancel
{
    [_newAccount release];
    _newAccount = nil;
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) asyncDidFinish
{
    AccountService* accountService = [_serviceProvider serviceWithName:@"AccountService"];
    [accountService addAccount:_newAccount];
    [_newAccount release];
    _newAccount = nil;

    NSIndexPath* indexPath = [self indexPathForAccount:_newAccount];
    if (indexPath != nil)
    {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    [self.navigationController popViewControllerAnimated:YES];
}

- (void) asyncDidFailWithError:(NSError*)error
{
    UIAlertView* alertView = [[[UIAlertView alloc] init] autorelease];
    alertView.title = _newAccount.name;
    alertView.message = error.localizedDescription;
    [alertView addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [alertView show];

    [_newAccount release];
    _newAccount = nil;

    [self.navigationController popViewControllerAnimated:YES];
}

@end
