
#import <Foundation/Foundation.h>
#import "Orientation.h"

@interface OrientationController : UINavigationController
{
    @private
    Orientation _orientation;
    UIDeviceOrientation _lastOrientation;
    UIButton* _lockButton;
    NSTimer* _lockTimer;
}

- (void) toggleLockClick;

- (Orientation) orientation;
- (void) setOrientation:(Orientation)orientation;

@end
