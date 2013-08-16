
#import "TwitterSync.h"

@implementation TwitterSync

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider account:(Account*)account
{
    self = [super init];
    _serviceProvider = [serviceProvider retain];
    _accountStore = [[ACAccountStore alloc] init];

    _state = account;
    return self;
}

- (void) dealloc
{
    [self resetSync];
    _state = nil;
	[_account release];
    [_accountStore release];
    [_serviceProvider release];
    [super dealloc];
}

- (void) start:(id<AsyncDelegate>)delegate
{
    [_delegate release];
    _delegate = [delegate retain];
    
    [self resetSync];
    
    _actions = [[NSMutableArray alloc] init];
    [_actions addObject:[NSValue valueWithPointer:@selector(findAccount)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(deleteReadItems)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(setupFriendsTimeline)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(setupConnection)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(startConnection)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(endConnection)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(setupMentions)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(setupConnection)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(startConnection)]];
    [_actions addObject:[NSValue valueWithPointer:@selector(endConnection)]];
    
    [self nextAction];
}

- (void) cancel
{
    [self resetSync];
    
    [_delegate asyncDidCancel];

    [_delegate release];
    _delegate = nil;
}

- (void) resetConnection
{
    if (_request != nil)
    {
        // TODO cancel [_request cancel];
        [_request release];
        _request = nil;
    }
   
    [_data release];
    _data = nil;    
}

- (void) resetSync
{
    [self resetConnection];

    [_status release];
    _status = nil;
    [_since release];
    _since = nil;
    [_max release];
    _max = nil;    
    [_actions release];
    _actions = nil;
}

- (NSDate*) parseDate:(NSString*)string
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
    NSDate* date = [dateFormatter dateFromString:string];
    [dateFormatter release];
    return date;
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
    
    if ([result rangeOfString:@"@"].location != NSNotFound)
    {
        NSError* error = nil;
        NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"@([A-Za-z0-9\\-_&;]+)" options:NSRegularExpressionCaseInsensitive error:&error];
        [regex replaceMatchesInString:result options:0 range:NSMakeRange(0, [result length]) withTemplate:@"<a href='http://www.twitter.com/$1'>@$1</a>"];
        [regex release];        
    }
    
    if ([result rangeOfString:@"#"].location != NSNotFound)
    {
        NSError* error = nil;
        NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"#([A-Za-z0-9\\-_&;]+)" options:NSRegularExpressionCaseInsensitive error:&error];
        [regex replaceMatchesInString:result options:0 range:NSMakeRange(0, [result length]) withTemplate:@"<a href='http://www.twitter.com/search?q=%23$1'>#$1</a>"];
        [regex release];        
    }
    
    return result;
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

- (void) findAccount
{
	ACAccountType* accountType = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [_accountStore requestAccessToAccountsWithType:accountType options:NULL completion:^(BOOL granted, NSError* error) {
		
		if (error)
		{
			[_delegate asyncDidFailWithError:error];
		}
		else if (granted)
		{
			NSArray* accounts = [_accountStore accountsWithAccountType:accountType];
			for (ACAccount* account in accounts)
			{
				if ([account.username isEqualToString:[_state objectForKey:@"username"]])
				{
					_account = [account retain];
					break;
				}
			}
			
			[self nextAction];
		}
    }];
}

- (void) deleteReadItems
{
    [_delegate asyncProgressChanged:0.1];
    
    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
    [storageService deleteReadItemsForAccount:_state.identifier];
    
    [self nextAction];
}

- (void) setupFriendsTimeline
{
    _progress = 0.3;
    _progressMax = 0.7;

    [_url release];
    _url = [@"https://api.twitter.com/1.1/statuses/home_timeline.json?count=100" retain];
    [_key release];
    _key = [@"lastSyncFriendsTimeline" retain];

    [self nextAction];
}

- (void) setupMentions
{
    _progress = 0.7;
    _progressMax = 0.9;

    [_url release];
    _url = [@"https://api.twitter.com/1.1/statuses/mentions_timeline.json?count=100" retain];
    [_key release];
    _key = [@"lastSyncMentions" retain];

    [self nextAction];
}

- (void) setupConnection
{
    _count = 0;
    [_status release];
    [_since release];
    [_max release];    

    NSString* status = [_state objectForKey:_key];
    if (status)
    {
        _status = [[NSNumber alloc] initWithLongLong:[status longLongValue]];        
        _count = 1000;
    }
    else
    {
        _status = [[NSNumber alloc] initWithLongLong:0];
        _count = 100;
    }

    _since = [[NSNumber alloc] initWithLongLong:[_status longLongValue]];
    _max = nil;

    [self nextAction];
}

- (void) startConnection
{
    [_delegate asyncProgressChanged:_progress];
    _progress += (_progressMax - _progress) / 8.0;
    
    [self resetConnection];

	NSMutableDictionary* params = [NSMutableDictionary dictionary];

	NSMutableString* url = [NSMutableString string];
    [url appendString:_url];
    if ([_since longLongValue] > 0)
    {
        [url appendFormat:@"&since_id=%@", [_since stringValue]];
    }
    if (_max != nil)
    {
        [url appendFormat:@"&max_id=%@", [[NSNumber numberWithLongLong:([_max longLongValue] - 1)] stringValue]];
    }
	
	_data = [[NSMutableData alloc] init];
	
	_request = [[SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:url] parameters:params] retain];
	_request.account = _account;
	[_request performRequestWithHandler:^(NSData* responseData, NSHTTPURLResponse* urlResponse, NSError* error) {

		dispatch_async(dispatch_get_main_queue(), ^{
			NSInteger statusCode = [urlResponse statusCode];
			if (statusCode != 200)
			{
				[self resetSync];
				[_delegate asyncDidFailWithError:[WebUtility errorForHttpStatusCode:statusCode]];
			}
			else if (error)
			{
				NSError* underlyingError = [error.userInfo objectForKey:@"NSUnderlyingError"];
				[_delegate asyncDidFailWithError:((underlyingError != nil) ? underlyingError : error)];
			}
			else
			{
				[_data appendData:responseData];
				[self nextAction];
			}
		});
	}];
}

- (void) endConnection
{
	[_delegate asyncProgressChanged:_progress];
    _progress += (_progressMax - _progress) / 8.0;
   
    NSString* response = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
    if ([response hasPrefix:@"<!DOCTYPE html PUBLIC"])
    {
        [self resetConnection];

        NSString* description = NSLocalizedString(@"Twitter unknown error.", nil);
        if ([response rangeOfString:@"<title>Twitter / Over capacity</title>"].location != NSNotFound)
        {
            description = NSLocalizedString(@"Twitter is over capacity.", nil);
        }

        NSError* error = [NSError errorWithDomain:@"TwitterSync" code:0 userInfo:[NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey]];
        [_delegate asyncDidFailWithError:error];
    }
    else
    {
        NSError* error = nil;
        NSObject* json = [NSJSONSerialization JSONObjectWithData:_data options:0 error:&error];
        [self resetConnection];
        if (error != nil)
        {
            [_delegate asyncDidFailWithError:error];
        }
        else if (json != nil)
        {
            if ([json isKindOfClass:[NSDictionary class]])
            {
                NSDictionary* root = (NSDictionary*) json;
                if ([root objectForKey:@"request"] && [root objectForKey:@"error"])
                {
                    NSError* error = [NSError errorWithDomain:@"TwitterSync" code:0 userInfo:[NSDictionary dictionaryWithObject:[root objectForKey:@"error"] forKey:NSLocalizedDescriptionKey]];
                    [_delegate asyncDidFailWithError:error];
                }
				else if ([root objectForKey:@"errors"] && ([[root objectForKey:@"errors"] count] > 0))
				{
					NSDictionary* entry = [[root objectForKey:@"errors"] objectAtIndex:0];
                    NSError* error = [NSError errorWithDomain:@"TwitterSync" code:0 userInfo:[NSDictionary dictionaryWithObject:[entry objectForKey:@"message"] forKey:NSLocalizedDescriptionKey]];
                    [_delegate asyncDidFailWithError:error];
				}
            }
                 
            if ([json isKindOfClass:[NSArray class]])
            {
                NSArray* root = (NSArray*) json;
                for (int i = 0; i < [root count]; i++)
                {
                    NSDictionary* source = [root objectAtIndex:i];

                    NSString* feed = [[[source objectForKey:@"user"] objectForKey:@"id"] stringValue];
                    NSString* name = [[source objectForKey:@"user"] objectForKey:@"name"];
                    NSString* image = [[source objectForKey:@"user"] objectForKey:@"profile_image_url"];
                    NSString* screenName = [[source objectForKey:@"user"] objectForKey:@"screen_name"];
                    NSString* message = [source objectForKey:@"text"];
                    NSDate* date = [self parseDate:[source objectForKey:@"created_at"]];
                    NSNumber* identifier = [source objectForKey:@"id"];
                    NSString* link = [NSString stringWithFormat:@"http://www.twitter.com/%@/status/%@", screenName, identifier];
                    NSString* from = name;
                    NSString* fromLink = [NSString stringWithFormat:@"http://www.twitter.com/%@", screenName];

                    if ([source objectForKey:@"retweeted_status"])
                    {
                        from = [[[source objectForKey:@"retweeted_status"] objectForKey:@"user"] objectForKey:@"name"];
                        fromLink = [NSString stringWithFormat:@"http://www.twitter.com/%@", [[[source objectForKey:@"retweeted_status"] objectForKey:@"user"] objectForKey:@"screen_name"]];
                    }
                    
                    if ([_key isEqualToString:@"lastSyncMentions"])
                    {
                        feed = [NSString stringWithFormat:@"@%@", [_state objectForKey:@"username"]];
                        name = feed;
                        image = @"";
                    }
                    
                    message = [self toHtml:message];

                    NSMutableDictionary* target = [[NSMutableDictionary alloc] init];
                    [target setObject:_state.identifier forKey:@"account"];
                    [target setObject:feed forKey:@"feed"];
                    [target setObject:name forKey:@"name"];
                    [target setObject:[identifier stringValue] forKey:@"identifier"];
                    [target setObject:image forKey:@"image"];
                    [target setObject:link forKey:@"link"];
                    [target setObject:from forKey:@"from"];
                    [target setObject:fromLink forKey:@"fromLink"];
                    [target setObject:@"" forKey:@"picture"];
                    [target setObject:@"" forKey:@"title"];
                    [target setObject:@"" forKey:@"content"];
                    [target setObject:message forKey:@"message"];
                    [target setObject:@"" forKey:@"to"];
                    [target setObject:@"" forKey:@"toLink"];
                    [target setObject:date forKey:@"date"];
                    [target setObject:[NSNumber numberWithBool:YES] forKey:@"unread"];

                    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
                    [storageService replaceItem:target];                
                    [target release];
                    
                    if ([identifier longLongValue] > [_status longLongValue])
                    {
                        [_status release];
                        _status = [[NSNumber alloc] initWithLongLong:[identifier longLongValue]];
                    }
                    if ((_max == nil) || ([identifier longLongValue] < [_max longLongValue]))
                    {
                        [_max release];
                        _max = [[NSNumber alloc] initWithLongLong:[identifier longLongValue]];
                    }
                }
                
                _count -= [root count];
                if ((_count > 0) && ([root count] > 0) && ((_max == nil) || ([_max longLongValue] > [_since longLongValue])) && ([_since longLongValue] > 0))
                {
                    [_actions insertObject:[NSValue valueWithPointer:@selector(startConnection)] atIndex:0];
                    [_actions insertObject:[NSValue valueWithPointer:@selector(endConnection)] atIndex:1];
                }
                else
                {
                    [_state setObject:_status forKey:_key];

                    [_status release];
                    _status = nil;
                    [_since release];
                    _since = nil;
                    [_max release];
                    _max = nil;
                }
                
                [self nextAction];
            }
        }
    }

    [response release];
}

@end
