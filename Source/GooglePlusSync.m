
#import "GooglePlusSync.h"

@implementation GooglePlusSync

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider account:(Account*)account clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret
{
    self = [super init];
    _serviceProvider = [serviceProvider retain];
    _account = account;
    _clientId = [clientId retain];
    _clientSecret = [clientSecret retain];    
    return self;
}

- (void) dealloc
{
    [self resetSync];
    [_delegate release];
    [_clientSecret release];
    [_clientId release];
    _account = nil;
    [_serviceProvider release];
    [super dealloc];
}

- (void) start:(id<AsyncDelegate>)delegate
{
    [_delegate release];
    _delegate = [delegate retain];
    
    [self resetSync];
    
    _actions = [[NSMutableArray alloc] init];
    [_actions addObject:[NSValue valueWithPointer:@selector(beginAuthentication)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(endAuthentication)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(beginDownload)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(beginDownload)]];
/*    [_actions addObject:[NSValue valueWithPointer:@selector(endDownloadReadingList)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(beginGetToken)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(endGetToken)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(beginUploadReadState)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(endUploadReadState)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(updateReadState)]];
*/    
    [self nextAction];
}

- (void) cancel
{
    [_delegate asyncDidCancel];
    [_delegate release];
    _delegate = nil;
    
    [self resetSync];
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
        [self resetSync];
        [_delegate asyncDidFailWithError:[WebUtility errorForHttpStatusCode:[response statusCode]]];        
    }
}

- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    [self resetSync];
    
    NSError* underlyingError = [error.userInfo objectForKey:@"NSUnderlyingError"];
    if (underlyingError != nil)
    {
        error = underlyingError;
    }
    
    [_delegate asyncDidFailWithError:error];
}

- (void) connectionDidFinishLoading:(NSURLConnection*)connection
{
    [self nextAction];
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

- (void) resetSync
{
    [self resetConnection];
    
/*    [_token release];
    _token = nil;
    [_continuation release];
    _continuation = nil;
    [_readServerItems release];
    _readServerItems = nil;
    [_readClientItems release];
    _readClientItems = nil;
    [_actions release];
    _actions = nil;
*/
}

- (void) nextAction
{
    if ([_actions count] > 0)
    {
        SEL selector = [[_actions objectAtIndex:0] pointerValue];
        [_actions removeObjectAtIndex:0];
        [self performSelectorOnMainThread:selector withObject:self waitUntilDone:NO];
        return;
    }
    
    [_delegate asyncDidFinish];
    [self resetSync];
}

- (void) beginAuthentication
{
    [_delegate asyncProgressChanged:0.1];
    
    [self resetConnection];
    
    [_data release];
    _data = [[NSMutableData alloc] init];
    
    NSString* refreshToken = [_account objectForKey:@"refreshToken"];
    
    NSMutableString* builder = [NSMutableString string];
    [builder appendFormat:@"client_id=%@&", [WebUtility urlEncode:_clientId]];
    [builder appendFormat:@"client_secret=%@&", [WebUtility urlEncode:_clientSecret]];
    [builder appendFormat:@"refresh_token=%@&", [WebUtility urlEncode:refreshToken]];
    [builder appendString:@"grant_type=refresh_token"];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://accounts.google.com/o/oauth2/token"]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[builder dataUsingEncoding:NSASCIIStringEncoding]];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void) endAuthentication
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
        NSString* accessToken = [root objectForKey:@"access_token"];
        NSString* tokenType = [root objectForKey:@"token_type"];
        if ([NSString isNullOrEmpty:tokenType] || [NSString isNullOrEmpty:accessToken])
        {
            [self resetSync];        
            
            NSString* message = NSLocalizedString(@"Authentication failure.", nil);
            NSError* error = [NSError errorWithDomain:@"GoogleReaderSync" code:0 userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
            [_delegate asyncDidFailWithError:error];
        }
        else
        {
            _authorization = [[NSString alloc] initWithFormat:@"%@ %@", tokenType, accessToken];
            [self nextAction];
        }
    }
}

- (void) beginDownload
{
    _progress = _progress + ((0.7 * _progress) * 0.25);
    [_delegate asyncProgressChanged:_progress];
    
    [self resetConnection];
    _data = [[NSMutableData alloc] init];
    
    NSMutableString* url = [NSMutableString string];
    [url appendString:@"https://www.googleapis.com/plus/v1/people/me/activities/public"];
//    [url appendFormat:@"?xt=user/-/state/com.google/read&r=n&n=50&ck=%@", [self unixTimeNow]];
//    if (![NSString isNullOrEmpty:_continuation])
//    {
//        [url appendFormat:@"&c=%@", _continuation];
//    }
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request addValue:_authorization forHTTPHeaderField:@"Authorization"];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];

}

- (void) endDownload
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
        [self nextAction];
    }
}

@end
