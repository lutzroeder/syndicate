
#import <Foundation/Foundation.h>
#import "ServiceProvider.h"
#import "Account.h"
#import "TwitterSync.h"
#import "TwitterAuthController.h"

@interface Twitter : Account
{
    @private
    TwitterSync* _synchronize;
    TwitterAuthController* _authenticate;
}

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider;

@end
