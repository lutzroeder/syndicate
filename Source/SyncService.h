
#import <Foundation/Foundation.h>
#import "AccountTypeService.h"
#import "AccountService.h"
#import "Async.h"
#import "NSString.h"

@interface SyncService : NSObject <Async, AsyncDelegate>
{
    @private
    id<ServiceProvider> _serviceProvider;
    id <AsyncDelegate> _delegate;
    NSInteger _index;
}

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider;

- (BOOL) synchronizing;

@end
