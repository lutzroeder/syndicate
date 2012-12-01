
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "ServiceProvider.h"
#import "StorageService.h"
#import "ImageService.h"
#import "SyncService.h"
#import "FeedCell.h"
#import "FeedController.h"
#import "DetailViewController.h"
#import "UIImage.h"

@interface FeedsController : UITableViewController <UITableViewDelegate, UITableViewDataSource, AsyncDelegate, ImageDelegate>
{
    @private
    id<ServiceProvider> _serviceProvider;
    DetailViewController* _detailViewController;
    UIBarButtonItem* _settingsButton;
    UIBarButtonItem* _readAllButton;
    UIBarButtonItem* _cancelButton;
    UIBarButtonItem* _unreadAllButton;
    UIAlertView* _alertView;
    NSArray* _feeds;
}

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider detailViewController:(DetailViewController*)detailViewController;

- (void) cancelClick;
- (void) readAllClick;
- (void) unreadAllClick;

- (void) storageRefresh:(NSNotification*)notification;
- (void) didSwipe:(UIGestureRecognizer*)gestureRecognizer;

@end
