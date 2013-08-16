
#import "GoogleReader.h"

@implementation GoogleReader

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider
{
    self = [super init];

    _authenticate = nil;
    _synchronize = nil;
    _serviceProvider = [serviceProvider retain];
    _clientId = [@"" retain];
    _clientSecret = [@"" retain];
    
    return self;
}

- (void) dealloc
{
    [_authenticate release];
    [_synchronize release];
    [_clientSecret release];
    [_clientId release];
    [_serviceProvider release];
    [super dealloc];
}

- (NSString*) name
{
    return @"Google Reader";
}

- (id <Async>) authenticate
{
    if (_authenticate == nil)
    {
        _authenticate = [[GoogleReaderAuthController alloc] initWithAccount:self clientId:_clientId clientSecret:_clientSecret];
    }

    return _authenticate;
}

- (id <Async>) synchronize
{
    if (_synchronize == nil)
    {
        _synchronize = [[GoogleReaderSync alloc] initWithServiceProvider:_serviceProvider account:self clientId:_clientId clientSecret:_clientSecret];
    }
    
    return _synchronize;
}

@end
