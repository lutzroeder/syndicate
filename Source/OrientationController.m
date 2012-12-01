
#import "OrientationController.h"

@implementation OrientationController

- (id) initWithRootViewController:(UIViewController*)rootViewController
{
    self = [super initWithRootViewController:rootViewController];

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSString* value = [defaults objectForKey:@"orientation"];
    if ([@"LandscapeLeft" isEqualToString:value])
        self.orientation = OrientationLandscapeLeft;
    else if ([@"LandscapeRight" isEqualToString:value])
        self.orientation = OrientationLandscapeRight;
    else if ([@"Portrait" isEqualToString:value])
        self.orientation = OrientationPortrait;
    else if ([@"PortraitUpsideDown" isEqualToString:value])
        self.orientation = OrientationPortrait;
    else
        self.orientation = OrientationNone;
    
    return self;
}

- (void) dealloc
{
    [_lockButton release];
    [_lockTimer release];
    [super dealloc];
}

- (void) startTimer
{
    if (_lockTimer != nil)
    {
        [_lockTimer invalidate];
        [_lockTimer release];
    }    
    _lockTimer = [[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(timerInterval) userInfo:nil repeats:NO] retain];
}

- (void) timerInterval
{
    [UIView beginAnimations:@"" context:NULL];
    [UIView setAnimationDuration:0.5];
    [_lockButton setAlpha:0];
    [UIView commitAnimations];
    [_lockTimer release];
    _lockTimer = nil;
}

- (void) showLockButton
{
    if (self.view.window != nil)
    {
        if (_lockButton == nil)
        {
            _lockButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [_lockButton setImage:[UIImage imageNamed:@"Unlock"] forState:UIControlStateNormal];
            [_lockButton setImage:[UIImage imageNamed:@"Lock"] forState:UIControlStateSelected];
            [_lockButton addTarget:self action:@selector(toggleLockClick) forControlEvents:UIControlEventTouchUpInside];
            [_lockButton setHidden:YES];
            [self.view addSubview:_lockButton];
        }
        
        [_lockButton setFrame:CGRectMake((self.view.bounds.size.width / 2) - 25, self.view.bounds.size.height - 60, 50, 50)];
        [_lockButton setSelected:(self.orientation != OrientationNone)];
        [_lockButton setAlpha:0];
        [_lockButton setHidden:NO];
        
        [UIView beginAnimations:@"" context:NULL];
        [UIView setAnimationDuration:0.5];
        [_lockButton setAlpha:1];
        [UIView commitAnimations];
        
        [self startTimer];
    }
}

- (void) notificationCenterOrientationDidChange:(NSNotification*)notification
{
    UIDeviceOrientation orientiation = [UIDevice currentDevice].orientation;
    if ((orientiation != _lastOrientation) &&
        ((orientiation == UIDeviceOrientationPortrait) ||
         (orientiation == UIDeviceOrientationPortraitUpsideDown) ||
         (orientiation == UIDeviceOrientationLandscapeLeft) ||
         (orientiation == UIDeviceOrientationLandscapeRight)))
    {
        if (self.orientation != OrientationNone)
        {
            [self showLockButton];
        }
        
        _lastOrientation = orientiation;			
    }
}


- (void) viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationCenterOrientationDidChange:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _lastOrientation = UIDeviceOrientationUnknown;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void) presentModalViewController:(UIViewController*)modalViewController animated:(BOOL)animated
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [super presentModalViewController:modalViewController animated:animated];
}

- (void) dismissModalViewControllerAnimated:(BOOL)animated
{
    [super dismissModalViewControllerAnimated:animated];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL) shouldAutorotate
{
    return (self.orientation == OrientationNone);
}

// Deprecated in iOS 6
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    switch (self.orientation)
    {
        case OrientationNone: return YES;
        case OrientationLandscapeLeft: return toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft; 
        case OrientationLandscapeRight: return toInterfaceOrientation == UIInterfaceOrientationLandscapeRight; 
        case OrientationPortrait: return toInterfaceOrientation == UIInterfaceOrientationPortrait; 
        case OrientationPortraitUpsideDown: return toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown;
    }
    return NO;
}

 
- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    if (_lockButton != nil)
    {
        _lockButton.hidden = YES;
    }
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self showLockButton];
}

- (void) toggleLockClick
{
    _lockButton.selected = !_lockButton.selected;
    
    if (!_lockButton.selected)
    {
        self.orientation = OrientationNone;
    }
    else
    {
        switch ([UIDevice currentDevice].orientation)
        {
            case UIDeviceOrientationUnknown:
                
            case UIDeviceOrientationLandscapeLeft: 
                self.orientation = OrientationLandscapeLeft;
                break;
            case UIDeviceOrientationLandscapeRight: 
                self.orientation = OrientationLandscapeRight;
                break;
            case UIDeviceOrientationFaceUp:
            case UIDeviceOrientationPortrait: 
                self.orientation = OrientationPortrait;
                break;
            case UIDeviceOrientationFaceDown:
            case UIDeviceOrientationPortraitUpsideDown: 
                self.orientation = OrientationPortraitUpsideDown;
                break;
        }
    }
    
    [self startTimer];
}

- (Orientation) orientation
{
    return _orientation;
}

- (void) setOrientation:(Orientation)orientation
{
    _orientation = orientation;
    
    NSString* value = @"None";
    switch (_orientation)
    {
        case OrientationNone: value = @"None"; break;
        case OrientationLandscapeLeft: value = @"LandscapeLeft"; break;
        case OrientationLandscapeRight: value = @"LandscapeRight"; break;
        case OrientationPortrait: value = @"Portrait"; break;
        case OrientationPortraitUpsideDown: value = @"PortraitUpsideDown"; break;
    }

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:@"orientation"];
    [defaults synchronize];
}

@end
