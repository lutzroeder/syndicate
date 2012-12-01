
#import <Foundation/Foundation.h>
#import "ServiceProvider.h"
#import "Account.h"
#import "GooglePlusSync.h"
#import "GoogleReaderAuthController.h"

@interface GooglePlus : Account
{
    @private
    GoogleReaderAuthController* _authenticate;
    GooglePlusSync* _synchronize;
}

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider;

@end
