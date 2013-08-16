
#import "FacebookAuthController.h"

@implementation FacebookAuthController

- (id) initWithAccount:(Account*)account appId:(NSString *)appId
{
    self = [super init];
    _account = account;
	_appId = [appId retain];
    _accountStore = [[ACAccountStore alloc] init];
	_accounts = [[NSMutableArray array] retain];
    
    UITableView* tableView = [[[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped] autorelease];
	tableView.dataSource = self;
	tableView.delegate = self;
    self.tableView = tableView;
	
	self.navigationItem.title = @"Facebook";

    return self;
}

- (void) dealloc
{
    [_delegate release];
    [_accountStore release];
	[_appId release];
    _account = nil;
    [super dealloc];
}

- (void) start:(id<AsyncDelegate>)delegate
{
    [_delegate release];
    _delegate = [delegate retain];

	[_accounts removeAllObjects];
	
	ACAccountType* accountType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];

	// @"offline_access",
	
	NSDictionary* options = @{
		ACFacebookAppIdKey:_appId,
		ACFacebookPermissionsKey:@[ @"read_stream", @"user_photos", @"friends_photos" ] };

	[_accountStore requestAccessToAccountsWithType:accountType options:options completion:^(BOOL granted, NSError* error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!granted)
			{
				if (error.code == ACErrorAccountNotFound)
				{
					SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
					[self presentViewController:composeViewController animated:NO completion:^{
						[composeViewController dismissViewControllerAnimated:NO completion:nil];
					}];
				}
				else if (error)
				{
					[_delegate asyncDidFailWithError:error];
				}
			}
			else
			{
				NSArray* accounts = [_accountStore accountsWithAccountType:accountType];
				/*if (accounts.count == 1)
				{
					[self finish:[accounts objectAtIndex:0]];
				}
				else*/
				{
					[_accounts addObjectsFromArray:accounts];
					[self.tableView reloadData];
				}
			}
		});
	}];
}

- (void) cancel
{
	[_account removeObjectForKey:@"username"];
	[_account removeObjectForKey:@"accessToken"];

	[_delegate asyncDidCancel];
    [_delegate release];
    _delegate = nil;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

- (void) finish:(ACAccount*)account
{
	[_account setObject:account.username forKey:@"username"];
	[_account setObject:account.credential.oauthToken forKey:@"accessToken"];
	[_delegate asyncDidFinish];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_accounts count];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 0)
    {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"TwitterAccount"];
        if (cell == nil)
        {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TwitterAccount"] autorelease];
        }

		ACAccount* account = [_accounts objectAtIndex:indexPath.row];
		
		cell.textLabel.text = account.username;
		
		return cell;
    }
	
    return nil;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (indexPath.section == 0)
	{
		ACAccount* account = [_accounts objectAtIndex:indexPath.row];
		[self finish:account];
	}
}

@end
