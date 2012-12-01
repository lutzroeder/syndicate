
#import "Application.h"

@implementation Application

- (id) init
{
    self = [super init];
    self.delegate = self;
    _serviceTable = [[NSMutableDictionary alloc] init];
    return self;
}

- (void) dealloc
{
    [_window release];
    [_serviceTable release];
    [super dealloc];
}

- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storageStart:) name:@"StorageStart" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountRefresh:) name:@"AccountRefresh" object:nil];

    [[NSUserDefaults standardUserDefaults] synchronize];

    StorageService* storageService = [[StorageService alloc] init];
    [_serviceTable setObject:storageService forKey:@"StorageService"];

    AccountTypeService* accountTypeService = [[AccountTypeService alloc] init];
    [accountTypeService addAccountType:@"GoogleReader"];
    [accountTypeService addAccountType:@"Twitter"];
    [accountTypeService addAccountType:@"Facebook"];
    // [accountTypeService addAccountType:@"GooglePlus"];
    [_serviceTable setObject:accountTypeService forKey:@"AccountTypeService"];

    AccountService* accountService = [[AccountService alloc] initWithServiceProvider:self];
    [_serviceTable setObject:accountService forKey:@"AccountService"];
    
    SyncService* syncService = [[SyncService alloc] initWithServiceProvider:self];
    [_serviceTable setObject:syncService forKey:@"SyncService"];
    
    ImageService* imageService = [[ImageService alloc] init];
    [_serviceTable setObject:imageService forKey:@"ImageService"];
    
    UIBarButtonItem* settingsButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Gear"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsClick)] autorelease];
    
    UIViewController* rootViewController = nil;
    switch ([[UIDevice currentDevice] userInterfaceIdiom]) 
    {
        case UIUserInterfaceIdiomPad:
        {
            DetailViewController* detailViewController = [[[DetailViewController alloc] init] autorelease];
            detailViewController.navigationBar.barStyle = UIBarStyleBlack;
            [detailViewController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavigationBar.png"] forBarMetrics:UIBarMetricsDefault];

            FeedsController* feedsController = [[[FeedsController alloc] initWithServiceProvider:self detailViewController:detailViewController] autorelease];
            feedsController.navigationItem.leftBarButtonItem = settingsButton;
            UINavigationController* masterViewController = [[[UINavigationController alloc] initWithRootViewController:feedsController] autorelease];
            masterViewController.navigationBar.barStyle = UIBarStyleBlack;
            [masterViewController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavigationBar.png"] forBarMetrics:UIBarMetricsDefault];

            UISplitViewController* splitViewController = [[[UISplitViewController alloc] init] autorelease];
            splitViewController.viewControllers = [NSArray arrayWithObjects:masterViewController, detailViewController, nil];
            splitViewController.delegate = detailViewController;
            rootViewController = splitViewController;
        }
        break;

        case UIUserInterfaceIdiomPhone:
        default:
        {
            FeedsController* feedsController = [[[FeedsController alloc] initWithServiceProvider:self detailViewController:nil] autorelease];
            feedsController.navigationItem.leftBarButtonItem = settingsButton;

            OrientationController* orientationController = [[[OrientationController alloc] initWithRootViewController:feedsController] autorelease];
            orientationController.navigationBar.barStyle = UIBarStyleBlack;
            [orientationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavigationBar.png"] forBarMetrics:UIBarMetricsDefault];
            rootViewController = orientationController;
        }
        break;
    }
    
    [self setStatusBarHidden:NO withAnimation:YES];
    [self setStatusBarStyle:UIStatusBarStyleBlackOpaque];

    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _window.rootViewController = rootViewController;
    [_window makeKeyAndVisible];

    [imageService release];
    [syncService release];
    [storageService release];
    [accountTypeService release];
    [accountService release];
    
    return YES;
}

- (void) applicationWillTerminate:(UIApplication*)application
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"StorageStart" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AccountRefresh" object:nil];
    
    AccountTypeService* accountTypeService = [self serviceWithName:@"AccountTypeService"];    
    // [accountTypeService removeAccountType:@"GooglePlus"];
    [accountTypeService removeAccountType:@"Facebook"];
    [accountTypeService removeAccountType:@"Twitter"];
    [accountTypeService removeAccountType:@"GoogleReader"];
    
    StorageService* storageService = [self serviceWithName:@"StorageService"];
    [storageService save];

    [_serviceTable removeObjectForKey:@"ImageService"];
    [_serviceTable removeObjectForKey:@"SyncService"];
    [_serviceTable removeObjectForKey:@"StorageService"];
    [_serviceTable removeObjectForKey:@"AccountTypeService"];
    [_serviceTable removeObjectForKey:@"AccountService"];
}    

- (void) applicationWillResignActive:(UIApplication*)application
{
    StorageService* storageService = [self serviceWithName:@"StorageService"];
    [storageService save];
}

- (void) applicationDidEnterBackground:(UIApplication*)application
{
}

- (void) applicationWillEnterForeground:(UIApplication*)application
{
}

- (void) settingsClick
{
    AccountsController* accountsController = [[AccountsController alloc] initWithServiceProvider:self];

    UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:accountsController];
    [navigationController setModalPresentationStyle:UIModalPresentationFormSheet];
    [navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    [navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"NavigationBar.png"] forBarMetrics:UIBarMetricsDefault];

    [_window.rootViewController presentViewController:navigationController animated:YES completion:nil];
    
    [navigationController release];    
    [accountsController release];
}

- (id) serviceWithName:(NSString*)serviceName
{
    return [_serviceTable objectForKey:serviceName];
}

- (void) storageStart:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"AccountRefresh" object:self userInfo:nil]];

    AccountService* accountService = [self serviceWithName:@"AccountService"];
    if (accountService.accounts.count == 0)
    {
        [self settingsClick];
    }
}

- (void) accountRefresh:(NSNotification*)notification
{
    AccountService* accountService = [self serviceWithName:@"AccountService"];

    NSMutableArray* accounts = [NSMutableArray arrayWithCapacity:accountService.accounts.count];
    for (Account* account in accountService.accounts)
    {
        [accounts addObject:account.identifier];
    }
    
    StorageService* storageService = [self serviceWithName:@"StorageService"];
    [storageService deleteUnusedAccounts:accounts];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"StorageRefresh" object:self userInfo:nil]];
}

@end



@implementation UINavigationBar (UINavigationBarCategory)

- (void) drawRect:(CGRect)rect 
{
}

@end
