
#import <Foundation/Foundation.h>
#import "ServiceProvider.h"
#import "StorageService.h"
#import "Account.h"

@interface AccountService : NSObject
{
    @private
    id<ServiceProvider> _serviceProvider;
    NSMutableArray* _accounts;
}

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider;

- (void) addAccount:(Account*)account;
- (void) removeAccount:(Account*)account;

- (NSArray*) accounts;
- (Account*) accountForIdentifier:(NSString*)identifier;
- (Account*) accountForType:(NSString*)accountType;

- (void) load;
- (void) save;

- (void) ubiquitousKeyValueStoreDidChangeExternallyNotification:(NSNotification*)notification;

@end
