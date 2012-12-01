
#import <Foundation/Foundation.h>
#import "ServiceProvider.h"
#import "OrientationController.h"
#import "StorageService.h"
#import "AccountTypeService.h"
#import "AccountService.h"
#import "SyncService.h"
#import "ImageService.h"
#import "AccountsController.h"
#import "FeedsController.h"
#import "DetailViewController.h"
#import "UIImage.h"

@interface Application : UIApplication <UIApplicationDelegate, ServiceProvider>
{
    @private
    NSMutableDictionary* _serviceTable;
	UIWindow* _window;
}

- (void) settingsClick;

- (void) storageStart:(NSNotification*)notification;
- (void) accountRefresh:(NSNotification*)notification;

@end
