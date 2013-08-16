
#import "Facebook.h"

@implementation Facebook

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider
{
    self = [super init];
    _authenticate = nil;
    _synchronize = nil;
	_appId = [@"" retain];
    _serviceProvider = [serviceProvider retain];
    return self;
}

- (void) dealloc
{
    [_synchronize release];
    [_authenticate release];
    [_serviceProvider release];
    [super dealloc];
}

- (NSString*) name
{
    return @"Facebook";
}

- (id <Async>) authenticate
{
    if (_authenticate == nil)
    {
        _authenticate = [[FacebookAuthController alloc] initWithAccount:self appId:_appId];
    }
    return _authenticate;
}

- (id <Async>) synchronize
{
    if (_synchronize == nil)
    {
        _synchronize = [[FacebookSync alloc] initWithServiceProvider:_serviceProvider account:self];
    }
    return _synchronize;
}

@end
