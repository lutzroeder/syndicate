
#import "SyncService.h"

@implementation SyncService

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider;
{
    self = [super init];
    _serviceProvider = [serviceProvider retain];
    _index = -1;
    return self;
}

- (void) dealloc
{
    [_serviceProvider release];
    [_delegate release];
    [super dealloc];
}

- (Account*) currentAccount
{
    AccountTypeService* accountTypeService = [_serviceProvider serviceWithName:@"AccountTypeService"];
    AccountService* accountService = [_serviceProvider serviceWithName:@"AccountService"];
    NSString* accountType = [accountTypeService.accountTypes objectAtIndex:_index];
    Account* account = [accountService accountForType:accountType];
    return account;
}

- (void) nextAccount
{
    AccountTypeService* accountTypeService = [_serviceProvider serviceWithName:@"AccountTypeService"];

    _index++;
    if (_index < accountTypeService.accountTypes.count)
    {
        Account* account = self.currentAccount;
        
        if ((account != nil) && (account.synchronize != nil))
        {
            [_delegate asyncTextChanged:account.name];
            [account.synchronize start:self];
        }
        else
        {
            [self nextAccount];
        }
    }
    else
    {
        StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
        [storageService save];
        
        _index = -1;
        [_delegate asyncDidFinish];
    }
    
    AccountService* accountService = [_serviceProvider serviceWithName:@"AccountService"];
    [accountService save];
}

- (void) asyncDidCancel
{
    _index = -1;
    [_delegate asyncDidCancel];
}

- (void) asyncDidFailWithError:(NSError*)error
{
    Account* account = self.currentAccount;

    NSString* message = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
    NSString* title = account.name;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:message, NSLocalizedDescriptionKey, title, @"account", nil];
    [_delegate asyncDidFailWithError:[NSError errorWithDomain:error.domain code:error.code userInfo:userInfo]];

    [self nextAccount];
}

- (void) asyncDidFinish
{
    AccountTypeService* accountTypeService = [_serviceProvider serviceWithName:@"AccountTypeService"];
    if (_index < accountTypeService.accountTypes.count)
    {
        Account* account = self.currentAccount;
        [account setObject:[NSDate date] forKey:@"lastUpdated"];
    }

    [self nextAccount];
}

- (void) asyncProgressChanged:(float)progress
{
    AccountTypeService* accountTypeService = [_serviceProvider serviceWithName:@"AccountTypeService"];
    [_delegate asyncProgressChanged:((((float) _index) + progress) / accountTypeService.accountTypes.count)];
}

- (void) asyncTextChanged:(NSString*)text
{
}

- (BOOL) synchronizing
{
    return (_index != -1);
}

- (void) start:(id<AsyncDelegate>)delegate
{
    _delegate = [delegate retain];
    _index = -1;
    [self nextAccount];
}

- (void) cancel
{
    if (_index != -1)
    {
        Account* account = self.currentAccount;        
        if (account.synchronize != nil)
        {
            [account.synchronize cancel];
        }
    }
}

@end
