
#import "FeedsController.h"

@implementation FeedsController

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider detailViewController:(DetailViewController*)detailViewController;
{
    self = [super init];

    self.title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    
    _serviceProvider = [serviceProvider retain];
    _detailViewController = [detailViewController retain];

    _readAllButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithSize:16 drawCircleWithSize:12 width:2 color:[UIColor whiteColor] fillColor:nil] style:UIBarButtonItemStylePlain target:self action:@selector(readAllClick)];
    _unreadAllButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithSize:16 drawCircleWithSize:12 width:2 color:[UIColor whiteColor] fillColor:[UIColor whiteColor]] style:UIBarButtonItemStylePlain target:self action:@selector(unreadAllClick)];
    _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancelClick)];
    self.navigationItem.rightBarButtonItem = _readAllButton;

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.957 alpha:1.0];
    self.tableView.showsVerticalScrollIndicator = YES;

    self.refreshControl = [[[UIRefreshControl alloc] init] autorelease];
    self.refreshControl.backgroundColor = [UIColor clearColor];
    [self.refreshControl addTarget:self action:@selector(refreshInvoked:forState:) forControlEvents:UIControlEventValueChanged];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storageRefresh:) name:@"StorageRefresh" object:nil];

    return self;
}

- (void) refreshInvoked:(id)sender forState:(UIControlState)state
{
    [self start];
}
        
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"StorageRefresh" object:nil];
    
    [_feeds release];
    [_alertView release];
    [_cancelButton release];
    [_readAllButton release];
    [_settingsButton release];
    [_detailViewController release];
    [_serviceProvider release];
    [super dealloc];
}

- (void) updateUnreadCount
{
    NSInteger count = 0;
    for (NSDictionary* feed in _feeds)
    {
        count += [[feed objectForKey:@"unread"] intValue];
    }
    
    SyncService* syncService = [_serviceProvider serviceWithName:@"SyncService"];
    if (!syncService.synchronizing)
    {
        if (_feeds.count == 0)
        {
            [self.navigationItem setRightBarButtonItem:nil animated:YES];
        }
        else if (count == 0)
        {
            [self.navigationItem setRightBarButtonItem:_unreadAllButton animated:YES];
        }
        else
        {
            [self.navigationItem setRightBarButtonItem:_readAllButton animated:YES];            
        }
    }
    
    // Update application badge
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];    
}

- (void) refresh
{
    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
    NSArray* feeds = [storageService feeds];
    
    [_feeds release];
    _feeds = [feeds retain];
    
    if ((_feeds.count == 0) && (_detailViewController))
    {
        [_detailViewController setViewController:nil];
    }
    
    [self.tableView reloadData];   

    [self updateUnreadCount];
}

- (void) start
{
    [self.navigationItem setHidesBackButton:YES animated:YES];
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    [self.navigationItem setRightBarButtonItem:_cancelButton animated:YES];

    SyncService* syncService = [_serviceProvider serviceWithName:@"SyncService"];
    [syncService start:self];    
}

- (void) stop
{    
    [self.refreshControl endRefreshing];

    [self.navigationItem setHidesBackButton:NO animated:YES];
    [self.navigationItem setLeftBarButtonItem:_settingsButton animated:YES];
    // [self.navigationItem setRightBarButtonItem:_readAllButton animated:YES];
     
    [self refresh];
}

- (void) updateFeedCell:(FeedCell*)cell withFeed:(NSDictionary*)feed
{
    AccountService* accountSerivce = [_serviceProvider serviceWithName:@"AccountService"];
    Account* account = [accountSerivce accountForIdentifier:[feed objectForKey:@"account"]];
    
    NSNumber* unread = [feed objectForKey:@"unread"];
    BOOL empty = (unread.intValue == 0);

    cell.textLabel.textColor = empty ? [UIColor grayColor] : [UIColor blackColor];
    cell.detailTextLabel.text = empty ? @"" : unread.stringValue;

	cell.imageView.layer.cornerRadius = 2;
    cell.imageView.layer.masksToBounds = YES;
    cell.imageView.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:0.1].CGColor;
    cell.imageView.layer.borderWidth = 1;    
    cell.imageView.image = empty ? account.grayscaleImage : account.image;
    cell.imageView.alpha = empty ? 0.5 : 1;

    NSString* image = [feed objectForKey:@"image"];
    if (![NSString isNullOrEmpty:image])
    {
        ImageService* imageService = [_serviceProvider serviceWithName:@"ImageService"];
        [imageService loadImage:[NSURL URLWithString:image] grayscale:empty delegate:self target:cell];
    }
    
    [cell layoutSubviews];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_settingsButton == nil)
    {
        _settingsButton = [self.navigationItem.leftBarButtonItem retain];
    }
    
    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
    [storageService save];
    
    [self refresh];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void) cancelClick
{
    SyncService* syncService = [_serviceProvider serviceWithName:@"SyncService"];
    [syncService cancel];
}

- (void) readAllClick
{
    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
    for (NSDictionary* feed in _feeds)
    {
        [storageService updateFeed:feed unread:NO];
    }

    [self refresh];
}

- (void) unreadAllClick
{
    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
    for (NSDictionary* feed in _feeds)
    {
        [storageService updateFeed:feed unread:YES];
    }

    [self refresh];
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_feeds count];
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary* feed = [_feeds objectAtIndex:indexPath.row];

    FeedCell* cell = [[[FeedCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Feed"] autorelease];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;    
    cell.textLabel.text = [feed objectForKey:@"name"];
    [self updateFeedCell:cell withFeed:feed];

    UISwipeGestureRecognizer* swipeGestureRecognizer;
    
    swipeGestureRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)] autorelease];
    swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [cell addGestureRecognizer:swipeGestureRecognizer];
    
    swipeGestureRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)] autorelease];
    swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [cell addGestureRecognizer:swipeGestureRecognizer];
    
    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary* feed = [_feeds objectAtIndex:indexPath.row];

    FeedController* feedController = [[FeedController alloc] initWithServiceProvider:_serviceProvider feed:feed detailViewController:_detailViewController];        
    [self.navigationController pushViewController:feedController animated:YES];
    [feedController release];
}

- (void) didSwipe:(UIGestureRecognizer*)gestureRecognizer;
{
    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
    
    FeedCell* cell = (FeedCell*) gestureRecognizer.view;
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    NSMutableDictionary* feed = [_feeds objectAtIndex:indexPath.row];
    NSNumber* unread = [feed objectForKey:@"unread"];
    if ((unread != nil) && (unread.intValue == 0))
    {
        [storageService updateFeed:feed unread:YES];
        [feed setObject:[NSNumber numberWithInt:[storageService unreadCountForFeed:feed]] forKey:@"unread"];
    }
    else
    {
        [storageService updateFeed:feed unread:NO];
        [feed setObject:[NSNumber numberWithInt:0] forKey:@"unread"];
    }

    [self updateFeedCell:cell withFeed:feed];
    [self updateUnreadCount];
}

- (void) didFinishLoadingImage:(UIImage*)image target:(NSObject*)target
{
    FeedCell* cell = (FeedCell*) target;
    cell.imageView.image = image;
}

- (void) asyncDidCancel
{
    [self stop];
}

- (void) asyncDidFinish
{
    [self stop];
}

- (void) asyncDidFailWithError:(NSError*)error
{
    if (_alertView != nil)
    {
        [_alertView dismissWithClickedButtonIndex:0 animated:YES];
        [_alertView release];
    }
    
    _alertView = [[UIAlertView alloc] init];
    _alertView.title = [error.userInfo objectForKey:@"account"];    
    [_alertView setMessage:error.localizedDescription];
    [_alertView addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [_alertView show];
}

- (void) asyncTextChanged:(NSString*)text
{
    [self refresh];
}

- (void) asyncProgressChanged:(float)progress
{
    [self refresh];
}

- (void) storageRefresh:(NSNotification*)notification
{
    [self refresh];
}

@end
