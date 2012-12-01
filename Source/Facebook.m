
#import "Facebook.h"

@implementation Facebook

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider
{
    self = [super init];
    NSString* appId = @"";
    _authenticate = [[FacebookAuthController alloc] initWithAccount:self appId:appId];
    _synchronize = [[FacebookSync alloc] initWithServiceProvider:serviceProvider account:self];
    return self;
}

- (void) dealloc
{
    [_synchronize release];
    [_authenticate release];
    [super dealloc];
}

- (NSString*) name
{
    return @"Facebook";
}

- (id <Async>) authenticate
{
    return _authenticate;
}

- (id <Async>) synchronize
{
    return _synchronize;
}

@end
