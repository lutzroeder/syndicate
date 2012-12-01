
#import "DetailViewController.h"

@implementation DetailViewController

- (id) init
{
    self = [super init];
    _emptyViewController = [[EmptyViewController alloc] init];
    self.viewController = _emptyViewController;
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (UIViewController*) viewController
{
    if ((self.viewControllers.count == 1) && (![[self.viewControllers objectAtIndex:0] isKindOfClass:[EmptyViewController class]]))
    {
        return [self.viewControllers objectAtIndex:0];
    }
    return nil;
}

- (void) setViewController:(UIViewController*)viewController
{
    if (viewController == nil)
    {        
        viewController = _emptyViewController;
    }

    self.viewControllers = [NSArray arrayWithObject:viewController];
}

- (BOOL) splitViewController:(UISplitViewController*)splitViewController shouldHideViewController:(UIViewController*)viewController inOrientation:(UIInterfaceOrientation)orientation
{
    return NO;
}

@end
