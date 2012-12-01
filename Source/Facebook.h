
#import <Foundation/Foundation.h>
#import "ServiceProvider.h"
#import "Account.h"
#import "FacebookSync.h"
#import "FacebookAuthController.h"

@interface Facebook : Account
{
    @private
    FacebookAuthController* _authenticate;
    FacebookSync* _synchronize;
}

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider;

@end
