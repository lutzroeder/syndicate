
#import "FacebookSync.h"

@implementation FacebookSync

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider account:(Account*)account
{
    self = [super init];
    _serviceProvider = [serviceProvider retain];
    _account = account;
    return self;
}

- (void) dealloc
{
    [self resetSync];
    _account = nil;
    [_delegate release];
    [_serviceProvider release];
    [super dealloc];
}

- (void) start:(id<AsyncDelegate>)delegate
{
    [_delegate release];
    _delegate = [delegate retain];

    [self resetSync];

    _actions = [[NSMutableArray alloc] init];
    [_actions addObject:[NSValue valueWithPointer:@selector(deleteReadItems)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(beginDownload)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(endDownload)]];
    
    [self nextAction];
}

- (void) cancel
{
    [_delegate asyncDidCancel];
    
    [_delegate release];
    _delegate = nil;
}

- (void) nextAction
{
    if ([_actions count] > 0)
    {
        SEL selector = [[_actions objectAtIndex:0] pointerValue];
        [_actions removeObjectAtIndex:0];
        [self performSelectorOnMainThread:selector withObject:self waitUntilDone:NO];
    }
    else
    {
        [self resetSync];
        [_delegate asyncDidFinish];
    }
}

- (void) resetSync
{
    [self resetConnection];
    [_actions release];
    _actions = nil;
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

- (void) deleteReadItems
{
    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
    [storageService deleteReadItemsForAccount:_account.identifier];
    [_delegate asyncProgressChanged:0.3];
    [self nextAction];
}

- (void) beginDownload
{
    [self resetConnection];
    _data = [[NSMutableData alloc] init];

    NSString* accessToken = [_account objectForKey:@"accessToken"];
    
    NSMutableString* builder = [NSMutableString string];
    [builder appendString:@"https://graph.facebook.com/me/home"];
    [builder appendString:@"?sdk=ios"];
    [builder appendFormat:@"&access_token=%@", [WebUtility urlEncode:accessToken]];
    [builder appendString:@"&format=json"];
    
    if ([_account objectForKey:@"lastSync"])
    {
        [builder appendFormat:@"&since=%@", [_account objectForKey:@"lastSync"]];
    }
    
    _connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:builder]] delegate:self];
}

- (void) endDownload
{
    [_delegate asyncProgressChanged:0.7];
    
    NSError* error = nil;
    NSDictionary* root = [NSJSONSerialization JSONObjectWithData:_data options:0 error:&error];
    [self resetConnection];
    if (error != nil)
    {
        [_delegate asyncDidFailWithError:error];
    }
    else if (root != nil)
    {
        NSArray* data = [root objectForKey:@"data"];
        
        for (int i = 0; i < [data count]; i++)
        {
            NSDictionary* item = [data objectAtIndex:i];
            
            if (([item objectForKey:@"application"]) && ([item objectForKey:@"application"] != [NSNull null]))
            {
                NSDictionary* application = [item objectForKey:@"application"];
                NSString* applicationId = [application objectForKey:@"id"];

                // Skip Twitter and Spotify items
                if ([applicationId isEqualToString:@"2231777543"] || [applicationId isEqualToString:@"174829003346"])
                {
                    continue;
                }
            }
            
            NSString* identifier = [item objectForKey:@"id"];
            NSString* feed = [[item objectForKey:@"from"] objectForKey:@"id"];
            NSString* name = [[item objectForKey:@"from"] objectForKey:@"name"];
            NSString* from = [[item objectForKey:@"from"] objectForKey:@"name"];
            NSString* fromLink = [NSString stringWithFormat:@"https://www.facebook.com/profile.php?id=%@", feed];
            NSString* image = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", feed];

            NSString* link = [item objectForKey:@"link"] ? [item objectForKey:@"link"] : @"";
            if ([NSString isNullOrEmpty:link] && [item objectForKey:@"actions"])
            {
                for (NSDictionary* action in [item objectForKey:@"actions"])
                {
                    if ((([@"Comment" isEqualToString:[action objectForKey:@"name"]]) || ([@"Like" isEqualToString:[action objectForKey:@"name"]])) && ([action objectForKey:@"link"]))
                    {
                        link = [action objectForKey:@"link"];
                        break;
                    }
                }
            }

            NSString* message = @"";
            if ([item objectForKey:@"message"])
            {
                message = [item objectForKey:@"message"];
            }
            else if ([item objectForKey:@"story"])
            {
                message = [item objectForKey:@"story"];
            }

            // Replace 'from' links in content
            if (![NSString isNullOrEmpty:message])
            {
                message = [self toHtml:message];

                NSString* targetLink = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", fromLink, from];
                message = [message stringByReplacingOccurrencesOfString:from withString:targetLink];
            }

            NSString* to = @"";
            NSString* toLink = @"";
            
            // Replace 'to' links in content
            if ([item objectForKey:@"to"] && [[item objectForKey:@"to"] objectForKey:@"data"])
            {
                NSMutableArray* result = [NSMutableArray array];
                
                for (NSObject* object in [[item objectForKey:@"to"] objectForKey:@"data"])
                {
                    if (object != [NSNull null])
                    {
                        NSDictionary* target = (NSDictionary*) object;
                        if ([message rangeOfString:[target objectForKey:@"name"]].location != NSNotFound)
                        {
                            NSString* targetLink = [NSString stringWithFormat:@"<a href=\"https://www.facebook.com/profile.php?id=%@\">%@</a>", [target objectForKey:@"id"], [target objectForKey:@"name"]];
                            message = [message stringByReplacingOccurrencesOfString:[target objectForKey:@"name"] withString:targetLink];
                        }
                        else
                        {
                            [result addObject:target];
                        }
                    }
                }
                
                // Is there is one 'to' link, store as target of message.
                if ([result count] == 1)
                {
                    NSDictionary* target = [result objectAtIndex:0];
                    to = [target objectForKey:@"name"];
                    toLink = [NSString stringWithFormat:@"https://www.facebook.com/profile.php?id=%@", [target objectForKey:@"id"]];
                }
            }
            
            NSString* picture = [item objectForKey:@"picture"] ? [item objectForKey:@"picture"] : @"";
            NSString* title = [item objectForKey:@"name"] ? [item objectForKey:@"name"] : @"";
            NSString* content = [item objectForKey:@"description"] ? [item objectForKey:@"description"] : @"";

            if ([NSString isNullOrEmpty:content] && [item objectForKey:@"caption"])
            {
                content = [item objectForKey:@"caption"];
            }
            
            NSString* type = [item objectForKey:@"type"];
            if ([@"photo" isEqualToString:type] && [NSString isNullOrEmpty:picture] && [item objectForKey:@"object_id"])
            {
                NSString* objectId = [item objectForKey:@"object_id"];
                picture = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=album&access_token=%@", objectId, [_account objectForKey:@"accessToken"]];
            }

            NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
            NSDate* date = [dateFormatter dateFromString:[item objectForKey:@"created_time"]];
            [dateFormatter release];

            NSMutableDictionary* target = [NSMutableDictionary dictionary];
            [target setObject:_account.identifier forKey:@"account"];
            [target setObject:feed forKey:@"feed"];
            [target setObject:name forKey:@"name"];
            [target setObject:identifier forKey:@"identifier"];
            [target setObject:image forKey:@"image"];
            [target setObject:link forKey:@"link"];
            [target setObject:from forKey:@"from"];
            [target setObject:fromLink forKey:@"fromLink"];
            [target setObject:to forKey:@"to"];
            [target setObject:toLink forKey:@"toLink"];
            [target setObject:title forKey:@"title"];
            [target setObject:content forKey:@"content"];
            [target setObject:message forKey:@"message"];
            [target setObject:picture forKey:@"picture"];
            [target setObject:date forKey:@"date"];
            [target setObject:[NSNumber numberWithBool:YES] forKey:@"unread"];
            StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
            [storageService replaceItem:target];
        }
        
        NSNumber* since = [self parseNextDate:root];
        if (since != nil)
        {
            [_account setObject:since forKey:@"lastSync"];        
            if ([data count] > 0)
            {
                [_actions insertObject:[NSValue valueWithPointer:@selector(beginDownload)] atIndex:0];            
                [_actions insertObject:[NSValue valueWithPointer:@selector(endDownload)] atIndex:1];            
            }
        }
        
        [self nextAction];
    }
    else
    {
        [_delegate asyncDidCancel];
    }
}

- (NSNumber*) parseNextDate:(NSDictionary*)root
{
    if ([root objectForKey:@"paging"])
    {
        NSDictionary* paging = [root objectForKey:@"paging"];
        if ([paging objectForKey:@"next"] && [paging objectForKey:@"previous"])
        {
            NSDictionary* properties = [WebUtility parseUrlParameters:[paging objectForKey:@"previous"] afterSeparator:@"?"];
            NSString* since = [properties objectForKey:@"since"];
            if (since != nil)
            {
                NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease];
                NSNumber* number = [formatter numberFromString:since];
                return number;                
            }
        }
    }
    return nil;
}

- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    [_data appendData:data];
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

- (NSString*) toHtml:(NSString *)string;
{
    NSMutableString* result = [NSMutableString stringWithString:string];
    
    if ([result rangeOfString:@"http://"].location != NSNotFound)
    {
        NSError* error = nil;
        NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"(\\b(https?):\\/\\/[-A-Z0-9+&@#\\/%?=~_|!:,.;]*[-A-Z0-9+&@#\\/%=~_|])" options:NSRegularExpressionCaseInsensitive error:&error];
        [regex replaceMatchesInString:result options:0 range:NSMakeRange(0, [result length]) withTemplate:@"<a href='$1'>$1</a>"];
        [regex release];
    }

    return result;
}


@end
