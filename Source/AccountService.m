
#import "AccountService.h"
#import "AccountTypeService.h"

@implementation AccountService

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider
{
    self = [super init];
    _serviceProvider = [serviceProvider retain];
    [self load];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ubiquitousKeyValueStoreDidChangeExternallyNotification:) name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:[NSUbiquitousKeyValueStore defaultStore]];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:[NSUbiquitousKeyValueStore defaultStore]];
     
    [_accounts release];
    [_serviceProvider release];
    [super dealloc];
}

- (void) addAccount:(Account*)account
{
    [[self mutableArrayValueForKey:@"accounts"] addObject:account];
    [self save];
}

- (void) removeAccount:(Account*)account
{
    [[self mutableArrayValueForKey:@"accounts"] removeObject:account];
    [self save];
}

- (NSArray*) accounts
{
    return _accounts;
}

- (Account*) accountForIdentifier:(NSString*)identifier
{
    for (Account* account in _accounts)
    {
        if ([identifier isEqualToString:account.identifier])
        {
            return account;
        }
    }
    return nil;
}

- (Account*) accountForType:(NSString*)accountType
{
    for (Account* account in _accounts)
    {
        if ([NSStringFromClass([account class]) isEqualToString:accountType])
        {
            return account;
        }
    }
    return nil;
}

- (void) load
{    
    [_accounts release];
    
    // Load accounts from user settings
    _accounts = [[NSMutableArray alloc] init];
    @try 
    {        
        [[self mutableArrayValueForKey:@"accounts"] removeAllObjects];

        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        
        [[self mutableArrayValueForKey:@"accounts"] removeAllObjects];
        NSArray* accounts = [defaults arrayForKey:@"accounts"];
        if (accounts != nil)
        {
            for (NSDictionary* accountTable in accounts)
            {
                NSString* type = [accountTable objectForKey:@"type"];
                Class class = NSClassFromString(type);
                Account* account = [class instancesRespondToSelector:@selector(initWithServiceProvider:)] ? [[class alloc] initWithServiceProvider:_serviceProvider] : [[class alloc] init];
                for (NSString* key in accountTable.keyEnumerator)
                {
                    if (![key isEqualToString:@"type"])
                    {
                        [account setObject:[accountTable objectForKey:key] forKey:key];
                    }
                }
                [[self mutableArrayValueForKey:@"accounts"] addObject:account];
                [account release];
            }
        }
    }
    @catch (NSException *exception) 
    {
        [[self mutableArrayValueForKey:@"accounts"] removeAllObjects];
    }
}

- (void) save
{
    // Save accounts to user settings

    NSMutableArray* accounts = [NSMutableArray arrayWithCapacity:self.accounts.count];
    for (Account* account in self.accounts)
    {
        NSMutableDictionary* accountTable = [NSMutableDictionary dictionary];
        [accountTable setObject:NSStringFromClass([account class]) forKey:@"type"];
        for (NSString* key in account.keyEnumerator)
        {
            if (![key isEqualToString:@"type"])
            {
                [accountTable setObject:[account objectForKey:key] forKey:key];
            }
        }
        [accounts addObject:accountTable];
    }

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:accounts forKey:@"accounts"];
    [defaults synchronize];
    
    NSUbiquitousKeyValueStore* defaultStore = [NSUbiquitousKeyValueStore defaultStore];
    [defaultStore setObject:accounts forKey:@"accounts"];    
    [defaultStore synchronize];
}

- (void) ubiquitousKeyValueStoreDidChangeExternallyNotification:(NSNotification*)notification
{
    NSUbiquitousKeyValueStore* defaultStore = [NSUbiquitousKeyValueStore defaultStore];
    NSDictionary* defaultTable = defaultStore.dictionaryRepresentation;

    [defaultTable enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    }];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self load];

    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"AccountRefresh" object:self userInfo:nil]];
}

@end
