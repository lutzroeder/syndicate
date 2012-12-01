
#import <Foundation/Foundation.h>
#import "ServiceProvider.h"
#import "StorageService.h"
#import "ImageService.h"
#import "ImageDelegate.h"
#import "FeedItemCell.h"
#import "DetailViewController.h"
#import "RichText.h"
#import "RichTextLabel.h"
#import "WebViewController.h"
#import "WebUtility.h"

@interface FeedController : UITableViewController <UITableViewDelegate, UITableViewDataSource, ImageDelegate>
{
    @private
    id<ServiceProvider> _serviceProvider;
    NSDictionary* _feed;
    DetailViewController* _detailViewController;
    NSArray* _items;
    RichTextLabel* _highlightedRichTextLabel;
}

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider feed:(NSDictionary*)feed detailViewController:(DetailViewController*)detailViewController;

- (void) readAllClick;
- (void) didSwipe:(UIGestureRecognizer*)gestureRecognizer;

@end
