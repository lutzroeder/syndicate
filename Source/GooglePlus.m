
#import "GooglePlus.h"

@implementation GooglePlus

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider
{
    self = [super init];
    
    NSString* clientId = @"";
    NSString* clientSecret = @"";
    
    _authenticate = [[GoogleReaderAuthController alloc] initWithAccount:self clientId:clientId clientSecret:clientSecret];
    _synchronize = [[GooglePlusSync alloc] initWithServiceProvider:serviceProvider account:self clientId:clientId clientSecret:clientSecret];
    
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
    return @"Google+";
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
