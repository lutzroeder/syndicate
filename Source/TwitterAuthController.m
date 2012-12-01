
#import "TwitterAuthController.h"

@implementation TwitterAuthController

- (id) initWithAccount:(Account*)account consumerKey:(NSString*)consumerKey consumerSecret:(NSString*)consumerSecret
{
    self = [super init];
    _account = account;
    _consumerKey = [consumerKey retain];
    _consumerSecret = [consumerSecret retain];    
    return self;
}

- (void) dealloc
{
    [self resetConnection];
    [_delegate release];
    [_consumerSecret release];
    [_consumerKey release];
    _account = nil;
    [super dealloc];
}

- (void) start:(id<AsyncDelegate>)delegate
{
    [_delegate release];
    _delegate = [delegate retain];

    [self resetConnection];
    [self removeCookies];

    _data = [[NSMutableData alloc] init];
    
    NSURL* url = [NSURL URLWithString:@"http://api.twitter.com/oauth/request_token"];
    NSURLRequest* request = [self createRequest:url token:@"" tokenSecret:@""];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void) cancel
{    
    [self resetConnection];
    
    [_account removeObjectForKey:@"token"];
    [_account removeObjectForKey:@"tokenSecret"];
    [_account removeObjectForKey:@"screenName"];

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
    
    [_data release];
    _data = nil;
}

- (void) removeCookies
{
    NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    
    for (NSHTTPCookie* cookie in [cookieStorage cookiesForURL:[NSURL URLWithString:@"https://twitter.com"]]) 
    {
        [cookieStorage deleteCookie:cookie];
    }
    
    for (NSHTTPCookie* cookie in [cookieStorage cookiesForURL:[NSURL URLWithString:@"http://twitter.com"]]) 
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
    if ([url.scheme isEqualToString:@"http"] && [url.host isEqualToString:@"www.callback.com"]) 
    {
        NSDictionary* params = [WebUtility parseUrlParameters:url.absoluteString afterSeparator:@"?"];
        
        NSString* token = [params objectForKey:@"oauth_token"];
        if (![NSString isNullOrEmpty:token])
        {
            _data = [[NSMutableData alloc] init];
            NSURL* url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
            NSURLRequest* request = [self createRequest:url token:token tokenSecret:@""];
            _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        }
        else
        {
            [_delegate asyncDidCancel];
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
        NSString* data = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
        NSDictionary* params = [WebUtility parseUrlParameters:data afterSeparator:@""];
        [data release];

        [self resetConnection];
        
        NSString* token = [params objectForKey:@"oauth_token"];
        NSString* tokenSecret = [params objectForKey:@"oauth_token_secret"];
        if (![NSString isNullOrEmpty:token] && ![NSString isNullOrEmpty:tokenSecret])
        {
            NSString* screenName = [params objectForKey:@"screen_name"];
            if (screenName != nil)
            {
                [_account setObject:[NSString stringWithFormat:@"%@:%@", NSStringFromClass(_account.class), token] forKey:@"identifier"];
                [_account setObject:token forKey:@"token"];
                [_account setObject:tokenSecret forKey:@"tokenSecret"];
                [_account setObject:screenName forKey:@"screenName"];
                
                [_delegate asyncDidFinish];
            }
            else
            {
                NSMutableString* builder = [NSMutableString string];
                [builder appendString:@"http://api.twitter.com/oauth/authorize"];
                [builder appendFormat:@"?oauth_token=%@", [WebUtility urlEncode:token]];
                NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:builder]];
                
                UIWebView* webView = (UIWebView*) self.view;
                [webView loadRequest:request];

                [request release];
            }            
        }
        else
        {
            [_delegate asyncDidCancel];
        }
    }
}

- (NSURLRequest*) createRequest:(NSURL*)url token:(NSString*)token tokenSecret:(NSString*)tokenSecret
{
    NSMutableString* key = [NSMutableString string];
    [key appendString:[WebUtility urlEncode:_consumerSecret]];
    [key appendString:@"&"];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    NSArray* queryParamters = [url.query componentsSeparatedByString:@"&"];
    for (NSString* queryParameter in queryParamters)
    {
        NSArray* pair = [queryParameter componentsSeparatedByString:@"="];
        if ([pair count] == 2)
        {
            [parameters setObject:[pair objectAtIndex:1] forKey:[pair objectAtIndex:0]];
        }
    }
    
    CFUUIDRef uuid = CFUUIDCreate(nil);
    NSString* nonce = (NSString*) CFUUIDCreateString(nil, uuid);
    CFRelease(uuid);
    
    [parameters setObject:@"1.0" forKey:@"oauth_version"];
    [parameters setObject:nonce forKey:@"oauth_nonce"];    
    [parameters setObject:[NSString stringWithFormat:@"%ld", time(NULL)] forKey:@"oauth_timestamp"];
    [parameters setObject:@"HMAC-SHA1" forKey:@"oauth_signature_method"];
    [parameters setObject:_consumerKey forKey:@"oauth_consumer_key"];
    [parameters setObject:@"" forKey:@"oauth_verifier"];
    
    [nonce release];
    
    if (![NSString isNullOrEmpty:token])
    {
        [parameters setObject:token forKey:@"oauth_token"];
    }
    
    if (![NSString isNullOrEmpty:tokenSecret])
    {
        [key appendString:[WebUtility urlEncode:tokenSecret]];
    }

    NSMutableString* requestParameters = [NSMutableString string];
    for (NSString* parameterName in [[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)])
    {
        if ([requestParameters length] > 0)
        {
            [requestParameters appendString:@"&"];
        }
        [requestParameters appendString:parameterName];
        [requestParameters appendString:@"="];
        [requestParameters appendString:[parameters objectForKey:parameterName]];
    }
    
    NSMutableString* query = [NSMutableString string];
    [query appendFormat:@"%@://%@%@", url.scheme, url.host, url.path];
    
    NSMutableString* signature = [NSMutableString string];
    [signature appendString:@"GET"];
    [signature appendFormat:@"&%@", [WebUtility urlEncode:query]];
    [signature appendFormat:@"&%@", [WebUtility urlEncode:requestParameters]];
    
    NSData* keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData* signatureData = [signature dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t hmacData[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, keyData.bytes, keyData.length, signatureData.bytes, signature.length, &hmacData);
    NSData* hmac = [[NSData alloc] initWithBytes:hmacData length:sizeof(hmacData)];
    NSString* hash = [WebUtility base64Encode:hmac];
    [hmac release];
    
    [query appendFormat:@"?%@", requestParameters];
    [query appendFormat:@"&oauth_signature=%@", [WebUtility urlEncode:hash]];
    
    return [NSURLRequest requestWithURL:[NSURL URLWithString:query]];
}

@end
