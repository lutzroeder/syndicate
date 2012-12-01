
#import "GoogleReader.h"

@implementation GoogleReader

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider
{
    self = [super init];

    NSString* clientId = @"";
    NSString* clientSecret = @"";

    _authenticate = [[GoogleReaderAuthController alloc] initWithAccount:self clientId:clientId clientSecret:clientSecret];
    _synchronize = [[GoogleReaderSync alloc] initWithServiceProvider:serviceProvider account:self clientId:clientId clientSecret:clientSecret];

    return self;
}

- (void) dealloc
{
    [_authenticate release];
    [_synchronize release];
    [super dealloc];
}

- (NSString*) name
{
    return @"Google Reader";
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
