
#import "Twitter.h"

@implementation Twitter

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider
{
    self = [super init];

    _serviceProvider = [serviceProvider retain];
    _authenticate = nil;
    _synchronize = nil;
    
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
    return @"Twitter";
}

- (id <Async>) authenticate
{
    if (_authenticate == nil)
    {
        _authenticate = [[TwitterAuthController alloc] initWithAccount:self];
    }
    return _authenticate;
}

- (id <Async>) synchronize
{
    if (_synchronize == nil)
    {
        _synchronize = [[TwitterSync alloc] initWithServiceProvider:_serviceProvider account:self];
    }
    return _synchronize;
}

@end
