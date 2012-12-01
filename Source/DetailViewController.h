
#import <UIKit/UIKit.h>
#import "EmptyViewController.h"

@interface DetailViewController : UINavigationController <UISplitViewControllerDelegate>
{
    @private
    EmptyViewController* _emptyViewController;
}

- (UIViewController*) viewController;
- (void) setViewController:(UIViewController*)viewController;

@end
