
#import "GoogleReaderSync.h"

@implementation GoogleReaderSync

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
    [_actions addObject:[NSValue valueWithPointer:@selector(createReadItems)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(beginDownloadReadingList)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(endDownloadReadingList)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(beginGetToken)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(endGetToken)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(beginUploadReadState)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(endUploadReadState)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(updateReadState)]];

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

    [_token release];
    _token = nil;
    [_continuation release];
    _continuation = nil;
    [_readServerItems release];
    _readServerItems = nil;
    [_readClientItems release];
    _readClientItems = nil;
    [_actions release];
    _actions = nil;
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

- (NSString*) unixTimeNow
{
    return [NSString stringWithFormat:@"%ld", time(NULL)];
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
            _accessToken = [accessToken retain];
            _authorization = [[NSString alloc] initWithFormat:@"%@ %@", tokenType, accessToken];
            [self nextAction];
        }
    }
}

- (void) createReadItems
{
    [_delegate asyncProgressChanged:0.2];
    
    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];

    [_readClientItems release];
    [_readServerItems release];
    _readClientItems = [[NSMutableArray arrayWithArray:[storageService itemsForAccount:_account.identifier unread:NO]] retain];
    _readServerItems = [[NSMutableArray arrayWithArray:[storageService itemsForAccount:_account.identifier unread:YES]] retain]; // start with all unread items and remove the ones that are unread on the server as well -- finally mark those as read on the client
    
    _progress = 0.3;

    [_continuation release];
    _continuation = nil;

    [self nextAction];
}

- (void) beginDownloadReadingList
{
    _progress = _progress + ((0.7 * _progress) * 0.25);
    [_delegate asyncProgressChanged:_progress];

    [self resetConnection];
    _data = [[NSMutableData alloc] init];

    NSMutableString* url = [NSMutableString string];
    [url appendString:@"https://www.google.com/reader/api/0/stream/contents/user/-/state/com.google/reading-list"];
    [url appendFormat:@"?xt=user/-/state/com.google/read&r=n&n=50&ck=%@", [self unixTimeNow]];
    if (![NSString isNullOrEmpty:_continuation])
    {
        [url appendFormat:@"&c=%@", _continuation];
    }

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request addValue:_authorization forHTTPHeaderField:@"Authorization"];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void) endDownloadReadingList
{
    NSError* error = nil;

    // NSLog(@"%@", [[[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding] autorelease]);

    NSDictionary* root = [NSJSONSerialization JSONObjectWithData:_data options:0 error:&error];

    [self resetConnection];
    if (error != nil)
    {
        [_delegate asyncDidFailWithError:error];
    }
    else if (root != nil)
    {
        NSArray* items = [root objectForKey:@"items"];
        for (int i = 0; i < [items count]; i++)
        {
            NSDictionary* item = [items objectAtIndex:i];
        
            NSString* feed = [[item objectForKey:@"origin"] objectForKey:@"streamId"];
            NSString* name = [WebUtility htmlDecode:[[item objectForKey:@"origin"] objectForKey:@"title"]]; 
            NSString* identifier = [item objectForKey:@"id"];
            
            NSString* image = @"";
            NSString* htmlUrl = [[item objectForKey:@"origin"] objectForKey:@"htmlUrl"];
            if (htmlUrl != nil)
            {
                NSURL* url = [NSURL URLWithString:htmlUrl];
                url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", url.scheme, url.host]];
                url = [url URLByAppendingPathComponent:@"favicon.ico"];
                image = url.absoluteString;
            }

            NSString* from = [item objectForKey:@"author"] ? [item objectForKey:@"author"] : @"";
            NSString* title = [item objectForKey:@"title"] ? [item objectForKey:@"title"] : @"";

            NSString* content = @"";
            if ([item objectForKey:@"content"])
            {
                content = [[item objectForKey:@"content"] objectForKey:@"content"];
            }
            else if ([item objectForKey:@"summary"])
            {
                content = [[item objectForKey:@"summary"] objectForKey:@"content"];
            }
            
            NSString* link = @"";
            if ([item objectForKey:@"alternate"])
            {
                for (NSDictionary* alternate in [item objectForKey:@"alternate"])
                {
                    if ([@"text/html" isEqualToString:[alternate objectForKey:@"type"]])
                    {
                        link = [alternate objectForKey:@"href"];
                        break;
                    }
                }            
            }

            NSDate* date = [NSDate dateWithTimeInterval:[[item objectForKey:@"updated"] doubleValue] sinceDate:[NSDate dateWithTimeIntervalSince1970:0]];

            NSNumber* unread = [NSNumber numberWithBool:![_readClientItems containsObject:identifier]];
            // If object is unread on the server and unread on the client do not mark it as read on the client.
            if ([_readServerItems containsObject:identifier])
            {
                [_readServerItems removeObject:identifier];
            }
            
            NSMutableDictionary* target = [[NSMutableDictionary alloc] init];
            [target setObject:_account.identifier forKey:@"account"];
            [target setObject:feed forKey:@"feed"];
            [target setObject:name forKey:@"name"];
            [target setObject:identifier forKey:@"identifier"];
            [target setObject:image forKey:@"image"];
            [target setObject:link forKey:@"link"];
            [target setObject:from forKey:@"from"];
            [target setObject:@"" forKey:@"fromLink"];
            [target setObject:@"" forKey:@"to"];
            [target setObject:@"" forKey:@"toLink"];
            [target setObject:title forKey:@"title"];
            [target setObject:content forKey:@"content"];
            [target setObject:@"" forKey:@"message"];
            [target setObject:@"" forKey:@"picture"];
            [target setObject:date forKey:@"date"];
            [target setObject:unread forKey:@"unread"];
            
            StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
            [storageService replaceItem:target];

            [target release];
        }


        [_continuation release];
        _continuation = [[root objectForKey:@"continuation"] retain];

        if (_continuation != nil)
        {
            [_actions insertObject:[NSValue valueWithPointer:@selector(beginDownloadReadingList)] atIndex:0];
            [_actions insertObject:[NSValue valueWithPointer:@selector(endDownloadReadingList)] atIndex:1];
        }
        
        [self nextAction];
    }
}

- (void) beginGetToken
{
    [_delegate asyncProgressChanged:0.7];
    
    [self resetConnection];

    _data = [[NSMutableData alloc] init];

    NSMutableString* url = [NSMutableString string];
    [url appendString:@"https://www.google.com/reader/api/0/token"];
    [url appendFormat:@"?client=%@", @"syndicate"];
    [url appendFormat:@"&ck=%@", [self unixTimeNow]];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request addValue:_authorization forHTTPHeaderField:@"Authorization"];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void) endGetToken
{
    _token = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
    [self nextAction];
}

- (void) beginUploadReadState
{
    [_delegate asyncProgressChanged:0.8];

    [self resetConnection];
    
    if ([_readClientItems count] > 0)
    {
        _data = [[NSMutableData alloc] init];

        NSMutableString* builder = [NSMutableString string];
        for (NSString* item in _readClientItems)
        {
            [builder appendFormat:@"i=%@", item];
            [builder appendString:@"&"];
        }
        [builder appendString:@"a=user/-/state/com.google/read"];
        [builder appendFormat:@"&T=%@", _token];

        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.google.com/reader/api/0/edit-tag"]];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[builder dataUsingEncoding:NSASCIIStringEncoding]];
        [request addValue:_authorization forHTTPHeaderField:@"Authorization"];
        _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }
    else
    {
        [_actions removeObjectAtIndex:0];
        [self nextAction];
    }
}

- (void) endUploadReadState
{    
    // NSString* state = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
    // if (![@"OK" isEqualToString:state])
    // [state release];
    [self nextAction];
}

- (void) updateReadState
{
    [_delegate asyncProgressChanged:0.9];

    // Delete all items marked read on the client
    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
    [storageService deleteItems:_readClientItems forAccount:_account.identifier];

    // Mark items unread which are not unread on the server
    NSMutableDictionary* item = [NSMutableDictionary dictionary];
    [item setObject:_account.identifier forKey:@"account"];
    for (NSString* identifier in _readServerItems)
    {
        [item setObject:identifier forKey:@"identifier"];
        [storageService updateItem:item unread:NO];
    }

    [self nextAction];
}

@end
