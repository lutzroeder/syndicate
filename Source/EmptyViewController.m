
#import "EmptyViewController.h"

@implementation EmptyViewController

- (id) init
{
    self = [super init];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    return self;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

@end
