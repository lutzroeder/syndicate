
#import "Twitter.h"

@implementation Twitter

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider
{
    self = [super init];
    _authenticate = [[TwitterAuthController alloc] initWithAccount:self consumerKey:@"4U0BjYhAnNOyC7g03D6pA" consumerSecret:@"fVjPabdR07TWAJ9p4dnmxNgEZnWA9PybKeFUaSL6M"];
    _synchronize = [[TwitterSync alloc] initWithServiceProvider:serviceProvider account:self authenticate:_authenticate];
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
    return @"Twitter";
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
