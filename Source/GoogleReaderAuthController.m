
#import "GoogleReaderAuthController.h"

@implementation GoogleReaderAuthController

- (id) initWithAccount:(Account*)account clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret;
{
    self = [super init];
    _account = account;
    _clientId = [clientId retain];
    _clientSecret = [clientSecret retain];    
    return self;
}

- (void) dealloc
{
    [self resetConnection];
    [_delegate release];
    [_clientSecret release];
    [_clientId release];
    _account = nil;
    [super dealloc];
}

- (void) start:(id<AsyncDelegate>)delegate
{
    [_delegate release];
    _delegate = [delegate retain];
    
    [self removeCookies];
    [self resetConnection];
    
    NSMutableString* builder = [NSMutableString string];
    [builder appendString:@"https://accounts.google.com/o/oauth2/auth"];
    [builder appendString:@"?response_type=code"];
    [builder appendFormat:@"&client_id=%@", [WebUtility urlEncode:_clientId]];
    [builder appendFormat:@"&redirect_uri=%@", [WebUtility urlEncode:@"http://localhost"]];
    [builder appendString:@"&scope="];
    [builder appendString:[WebUtility urlEncode:@"https://www.google.com/reader/api"]];
    [builder appendString:@"+"];
    [builder appendString:[WebUtility urlEncode:@"https://www.googleapis.com/auth/userinfo.profile"]];
                    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:builder]];
    
    UIWebView* webView = (UIWebView*) self.view;
    [webView loadRequest:request];
}

- (void) cancel
{    
    [self resetConnection];
    
    NSString* refreshToken = [_account objectForKey:@"refreshToken"];
    if (![NSString isNullOrEmpty:refreshToken])
    {
        NSString* body = [NSString stringWithFormat:@"token=%@", [WebUtility urlEncode:refreshToken]];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://accounts.google.com/o/oauth2/revoke"]];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
        _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }

    [_account removeObjectForKey:@"refreshToken"];
    
    [self removeCookies];
    
    [_delegate asyncDidCancel];
    
    if (self.navigationController != nil)
    {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    
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
    
    [_data release];
    _data = nil;
}

- (void) removeCookies
{
    NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie* cookie in [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://accounts.google.com"]]) 
    {
        [cookieStorage deleteCookie:cookie];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    UIWebView* webView = [[UIWebView alloc] init];
    [webView setDelegate:self];
    [webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    self.view = webView;
    [webView release];
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
    
    if ([url.scheme isEqualToString:@"http"] && [url.host isEqualToString:@"localhost"]) 
    {
        NSDictionary* params = [WebUtility parseUrlParameters:url.absoluteString afterSeparator:@"?"];

        NSString* code = [params objectForKey:@"code"];
        if ([NSString isNullOrEmpty:code])
        {
            [_delegate asyncDidCancel];
        }
        else
        {
            [self resetConnection];
            _data = [[NSMutableData alloc] init];
            
            NSMutableString* builder = [NSMutableString string];
            [builder appendFormat:@"code=%@&", [WebUtility urlEncode:code]];
            [builder appendFormat:@"client_id=%@&", [WebUtility urlEncode:_clientId]];
            [builder appendFormat:@"client_secret=%@&", [WebUtility urlEncode:_clientSecret]];
            [builder appendFormat:@"redirect_uri=%@&", [WebUtility urlEncode:@"http://localhost"]];
            [builder appendString:@"grant_type=authorization_code"];
            
            NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://accounts.google.com/o/oauth2/token"]];
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:[builder dataUsingEncoding:NSASCIIStringEncoding]];
            _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        }
        
        return NO;
    }
    
    return YES;
}

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    if (_data != nil)
    {
        [_data appendData:data];
    }
}

- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)response
{
    if ([response statusCode] != 200)
    {
        [self resetConnection];
        [_delegate asyncDidFailWithError:[WebUtility errorForHttpStatusCode:[response statusCode]]];        
    }
}

- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    [self resetConnection];
    
    NSError* underlyingError = [error.userInfo objectForKey:@"NSUnderlyingError"];
    if (underlyingError != nil)
    {
        error = underlyingError;
    }
    
    [_delegate asyncDidFailWithError:error];
}

- (void) connectionDidFinishLoading:(NSURLConnection*)connection
{
    if (_data != nil)
    {
        NSError* error = nil;
        NSDictionary* root = [NSJSONSerialization JSONObjectWithData:_data options:0 error:&error];
        [self resetConnection];
        if (error != nil)
        {
            [_delegate asyncDidFailWithError:error];
        }
        else if (root != nil)
        {
            NSString* refreshToken = [root objectForKey:@"refresh_token"];
            if (![NSString isNullOrEmpty:refreshToken])
            {
                [_account setObject:[NSString stringWithFormat:@"%@:%@", NSStringFromClass(_account.class), refreshToken] forKey:@"identifier"];
                [_account setObject:refreshToken forKey:@"refreshToken"];
                
                [_delegate asyncDidFinish];
            }
            else
            {
                [_delegate asyncDidCancel];
            }            
        }
    }
}

@end
