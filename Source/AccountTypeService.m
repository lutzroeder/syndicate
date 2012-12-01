
#import "AccountTypeService.h"

@implementation AccountTypeService

- (id) init
{
    self = [super init];
    _accountTypes = [[NSMutableArray alloc] init];
    return self;
}

- (void) dealloc
{
    [_accountTypes release];
    [super dealloc];
}

- (void) addAccountType:(NSString*)accountType
{
    [_accountTypes addObject:accountType];
}

- (void) removeAccountType:(NSString*)accountType
{
    [_accountTypes removeObject:accountType];
}

- (NSArray*) accountTypes
{
    return _accountTypes;
}

@end
