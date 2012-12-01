
#import "FacebookAuthController.h"

@implementation FacebookAuthController

- (id) initWithAccount:(Account*)account appId:(NSString*)appId
{
    self = [super init];
    _account = account;
    _appId = [appId retain];
    return self;
}

- (void) dealloc
{
    [_delegate release];
    [self resetConnection];
    [_appId release];
    _account = nil;
    [super dealloc];
}

- (void) start:(id<AsyncDelegate>)delegate
{
    [_delegate release];
    _delegate = [delegate retain];

    [self resetConnection];
    [self removeCookies];
    
    NSMutableString* builder = [NSMutableString string];
    [builder appendString:@"https://www.facebook.com/dialog/oauth"];
    [builder appendFormat:@"?client_id=%@", [WebUtility urlEncode:_appId]];
    [builder appendFormat:@"&redirect_uri=%@", [WebUtility urlEncode:@"http://www.lutzroeder.com"]];
    [builder appendString:@"&scope=offline_access,read_stream,user_photos,friends_photos"];
    [builder appendString:@"&response_type=token"];
    [builder appendString:@"&display=touch"];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:builder]];

    UIWebView* webView = (UIWebView*) self.view;
    [webView loadRequest:request];
}

- (void) cancel
{
    [_account removeObjectForKey:@"accessToken"];
    [_account removeObjectForKey:@"expiresIn"];

    [self resetConnection];
    _connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://api.facebook.com/method/auth.expireSession?format=json&sdk=ios&sdk_version=2"]] delegate:self];
    
    [self removeCookies];

    [_delegate asyncDidCancel];
        
    [_delegate release];
    _delegate = nil;
}

- (void) resetConnection
{
    if (_connection != nil)
    {
        [_connection cancel];
        [_connection release];
        _connection = nil;
    }
}

- (void) removeCookies
{
    NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie* cookie in [cookieStorage cookiesForURL:[NSURL URLWithString:@"http://login.facebook.com"]]) 
    {
        [cookieStorage deleteCookie:cookie];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UIWebView* webView = [[[UIWebView alloc] init] autorelease];
    webView.delegate = self;
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = webView;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

- (void) webViewDidStartLoad:(UIWebView*)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void) webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void) webViewDidFinishLoad:(UIWebView*)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (BOOL) webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL* url = request.URL;
    
    if ([url.scheme isEqualToString:@"http"] && [url.host isEqualToString:@"www.lutzroeder.com"]) 
    {
        NSDictionary* params = [WebUtility parseUrlParameters:url.absoluteString afterSeparator:@"#"];

        NSString* error = [params objectForKey:@"error"];
        NSString* errorReason = [params objectForKey:@"error_reason"];
        if ([@"access_denied" isEqualToString:error] && [@"user_denied" isEqualToString:errorReason])
        {
            [_delegate asyncDidCancel];            
        }
        else
        {
            NSString* errorCode = [params objectForKey:@"error_code"];
            NSString* errorMessage = [params objectForKey:@"error_msg"];
            if (errorCode)
            {
                NSDictionary* userInfo = [NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey];
                NSError* error = [NSError errorWithDomain:@"facebookErrDomain" code:[errorCode intValue] userInfo:userInfo];
                [_delegate asyncDidFailWithError:error];
            } 
        
            NSString* accessToken = [params objectForKey:@"access_token"];
            NSString* expiresIn = [params objectForKey:@"expires_in"];
            if (![NSString isNullOrEmpty:accessToken] && ![NSString isNullOrEmpty:expiresIn])
            {
                [_account setObject:[NSString stringWithFormat:@"%@:%@", NSStringFromClass(_account.class), accessToken] forKey:@"identifier"];
                [_account setObject:accessToken forKey:@"accessToken"];
                [_account setObject:expiresIn forKey:@"expiresIn"];
                [_delegate asyncDidFinish];
            }
            
            [_delegate asyncDidCancel];
        }

        return NO;
    } 
    else if (navigationType == UIWebViewNavigationTypeLinkClicked) 
    {
        WebViewController* webViewController = [[WebViewController alloc] initWithRequest:[NSURLRequest requestWithURL:url]];
        [self.navigationController pushViewController:webViewController animated:YES];
        [webViewController release];
        return NO;
    }

    return YES;
}


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse*)response
{
}

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data 
{
}

- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error 
{
    [self resetConnection];
}

- (void) connectionDidFinishLoading:(NSURLConnection*)connection 
{
    [self resetConnection];
}

@end
