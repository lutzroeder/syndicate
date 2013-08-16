
#import "WebViewController.h"

@implementation WebViewController

- (id) initWithRequest:(NSURLRequest*)request
{
    self = [super init];

    _backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back.png"] style:UIBarButtonItemStylePlain target:self action:@selector(backClick)];
    _forwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Forward.png"] style:UIBarButtonItemStylePlain target:self action:@selector(forwardClick)];
    _refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshClick)];
    _stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopClick)];
    _actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionClick)];    

    _webView = [[UIWebView alloc] init];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.scalesPageToFit = YES;
    _webView.delegate = self;
    [self.view addSubview:_webView];
    [_webView loadRequest:request];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleBordered target:nil action:nil] autorelease];

        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicatorView.frame = CGRectMake(0, 0, 20, 20);
        _activityIndicatorView.hidesWhenStopped = YES;
        _activityIndicatorButton = [[UIBarButtonItem alloc] initWithCustomView:_activityIndicatorView];

        UIBarButtonItem* fixedSpace15pxButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
        fixedSpace15pxButton.width = 15;

        UIBarButtonItem* fixedSpace40pxButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
        fixedSpace40pxButton.width = 40;

        UIBarButtonItem* flexibleSpaceButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];

        _actionToolbar = [[UIToolbar alloc] init];
        _actionToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        _actionToolbar.items = [NSArray arrayWithObjects:fixedSpace15pxButton, _backButton, fixedSpace40pxButton, _forwardButton, flexibleSpaceButton, _activityIndicatorButton, flexibleSpaceButton, _refreshButton, fixedSpace40pxButton, _actionButton, fixedSpace15pxButton, nil];
        [self.view addSubview:_actionToolbar];
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicatorView.frame = CGRectMake(0, 0, 77, 20);
        _activityIndicatorView.hidesWhenStopped = YES;
        _activityIndicatorButton = [[UIBarButtonItem alloc] initWithCustomView:_activityIndicatorView];
        
        UIBarButtonItem* fixedSpace10pxButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
        fixedSpace10pxButton.width = 10;
        
        UIToolbar* navigationToolbar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 77, 44)] autorelease];
        navigationToolbar.barStyle = -1;
        navigationToolbar.clearsContextBeforeDrawing = NO;
        navigationToolbar.items = [NSArray arrayWithObjects:_backButton, fixedSpace10pxButton, _forwardButton, nil];
        _navigationButton = [[UIBarButtonItem alloc] initWithCustomView:navigationToolbar];
        self.navigationItem.leftBarButtonItem = _navigationButton;

        _actionToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 77, 44)];
        _actionToolbar.barStyle = -1;
        _actionToolbar.clearsContextBeforeDrawing = NO;
        _actionToolbar.items = [NSArray arrayWithObjects:_refreshButton, fixedSpace10pxButton, _actionButton, nil];
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:_actionToolbar] autorelease];
    }

    _errorView = [[UIView alloc] init];
    _errorView.backgroundColor = [UIColor colorWithRed:226.0/255.0 green:231.0/255.0 blue:237.0/255.0 alpha:1.0];
    _errorView.hidden = YES;
    [self.view addSubview:_errorView];
    
    _errorLabel = [[UILabel alloc] init];
    _errorLabel.font = [UIFont boldSystemFontOfSize:14];
    _errorLabel.backgroundColor = [UIColor clearColor];
    _errorLabel.textColor = [UIColor colorWithRed:120/255.0f green:129/255.0f blue:147/255.0f alpha:1];
    _errorLabel.textAlignment = NSTextAlignmentCenter; 
    _errorLabel.shadowColor = [UIColor colorWithWhite:1 alpha:0.9];
    _errorLabel.shadowOffset = CGSizeMake(0, 1);
    _errorLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _errorLabel.numberOfLines = 0;
    _errorLabel.hidden = YES;
    [self.view addSubview:_errorLabel];
                                                          
    return self;
}

- (void) dealloc
{
    [_errorView release];
    [_errorLabel release];
    
    [_activityIndicatorButton release];
    [_activityIndicatorView release];
    
    [_backButton release];
    [_forwardButton release];
    [_refreshButton release];
    [_stopButton release];
    [_actionButton release];
    [_actionToolbar release];
    [_navigationButton release];

    [_request release];
    [_webView release];

    [super dealloc];
}

- (void) updateToolbar:(BOOL)showRefreshButton
{
    _backButton.enabled = [_webView canGoBack];
	_forwardButton.enabled = [_webView canGoForward];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        BOOL hideBackForwardToolbar = !_backButton.enabled && !_forwardButton.enabled;
        [self.navigationItem setHidesBackButton:hideBackForwardToolbar animated:YES];
    }
    
    UIBarButtonItem* button = showRefreshButton ? _refreshButton : _stopButton;
    
    NSInteger buttonIndex = 0;
    for (UIBarButtonItem* item in _actionToolbar.items)
    {
        if ((item == _stopButton) || (item == _refreshButton)) 
        {
            NSMutableArray* items = [NSMutableArray arrayWithArray:_actionToolbar.items];
            [items replaceObjectAtIndex:buttonIndex withObject:button];
            [_actionToolbar setItems:items animated:YES];
            break;
        }
        buttonIndex++;
    }
}

- (void) updateLayout:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        CGFloat toolbarHeight = ((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight)) ? 33 : 44;
        _actionToolbar.frame = CGRectMake(_webView.frame.origin.x, self.view.frame.size.height - toolbarHeight + 1, self.view.frame.size.width, toolbarHeight - 1);
        _webView.frame = CGRectMake(_webView.frame.origin.x, _webView.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height - toolbarHeight);  
    }
    else
    {
        _webView.frame = self.view.frame;
    }

    _errorView.frame = _webView.frame;
    _errorLabel.frame = CGRectMake(40, 40, _errorView.frame.size.width - 80, _errorView.frame.size.height - 80);
}

- (void) setActivityIndicatorVisible:(BOOL)visible
{
    if (visible)
    {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            [self.navigationItem setLeftBarButtonItem:_activityIndicatorButton animated:YES];            
        }
        [_activityIndicatorView startAnimating];        
    }
    else
    {
        [_activityIndicatorView stopAnimating];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        {
            [self.navigationItem setLeftBarButtonItem:_navigationButton animated:YES];            
        }
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateLayout:self.interfaceOrientation];
    [self updateToolbar:YES];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_webView stopLoading];
}

- (void) backClick
{
    [_webView goBack];
}

- (void) forwardClick
{
    [_webView goForward];
}

- (void) refreshClick
{
    if ((_webView.request == nil) || (_webView.request.URL == nil))
    {
        [_webView loadRequest:_request];
    }
    else 
    {
        [_webView reload];
    }
}

- (void) stopClick
{
    [_webView stopLoading];
}

- (void) actionClick
{
    UIActionSheet* actionSheet = [[[UIActionSheet alloc] init] autorelease];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    actionSheet.cancelButtonIndex = 2;
    actionSheet.delegate = self;
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Open in Safari", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Share via Email", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [actionSheet showFromBarButtonItem:_actionButton animated:YES];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration 
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self updateLayout:toInterfaceOrientation];
}

- (void) showInSafari:(NSURL*)url
{
    UIApplication* application = [UIApplication sharedApplication];
    if ([application canOpenURL:url])
    {
        [application openURL:url];
    }    
}

- (void) sendEmail:(NSURL*)url
{
    MFMailComposeViewController* mailComposeViewController = [[[MFMailComposeViewController alloc] init] autorelease];
    mailComposeViewController.mailComposeDelegate = self;
    mailComposeViewController.navigationBar.barStyle = UIBarStyleBlack;
    [mailComposeViewController setSubject:[NSString stringWithFormat:NSLocalizedString(@"Fwd: %@", nil), self.navigationItem.title]];
    [mailComposeViewController setMessageBody:url.absoluteString isHTML:YES];
    [self.navigationController presentViewController:mailComposeViewController animated:YES completion:nil];
}

- (void) actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSURL* url = _webView.request.URL;
    if ([NSString isNullOrEmpty:url.absoluteString])
    {
        url = _request.URL;
    }

    switch (buttonIndex)
    {
        case 0: [self showInSafari:url]; break;
        case 1: [self sendEmail:url]; break;
    }
}

- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL) webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL* url = request.URL;
    if (![url.scheme isEqual:@"http"] && ![url.scheme isEqual:@"https"])
    {
        UIApplication* application = [UIApplication sharedApplication];
        if ([application canOpenURL:url])
        {
            [application openURL:url];
            return NO;
        }
    }
    
    [_request release];
    _request = [request retain];

    return YES;
}

- (void) webViewDidStartLoad:(UIWebView*)webView
{
    _errorLabel.hidden = YES;
    _errorView.hidden = YES;
    
    [self setActivityIndicatorVisible:YES];
    [self updateToolbar:NO];
}

- (void) webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
    [self setActivityIndicatorVisible:NO];
    [self updateToolbar:YES];

    if ((error.domain == NSURLErrorDomain) && (error.code == NSURLErrorCancelled)) return;
    if ([error.domain isEqual:@"WebKitErrorDomain"] && (error.code == 102)) return; // Ignore 'Frame Load Interrupted'

    NSError* underlyingError = [error.userInfo objectForKey:@"NSUnderlyingError"];
    if (underlyingError != nil)
    {
        error = underlyingError;
    }

    _errorLabel.text = error.localizedDescription;
    _errorLabel.hidden = NO;
    _errorView.hidden = NO;
}

- (void) webViewDidFinishLoad:(UIWebView*)webView
{
    [self setActivityIndicatorVisible:NO];    
    [self updateToolbar:YES];

    if ([NSString isNullOrEmpty:self.navigationItem.title])
    {
        self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    }
    
    [_request release];
    _request = nil;
}

@end