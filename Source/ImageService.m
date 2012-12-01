
#import "ImageService.h"

@implementation ImageService

- (id) init
{
    self = [super init];
    
    _imageViewTable = [[NSMutableDictionary alloc] init];
    _dataTable = [[NSMutableDictionary alloc] init];
    
    _imageTable = [[NSMutableDictionary alloc] init];
    _grayscaleImageTable = [[NSMutableDictionary alloc] init];

    return self;
}

- (void) dealloc
{
    [_imageViewTable release];
    [_dataTable release];
    [_imageTable release];
    [_grayscaleImageTable release];
    [super dealloc];
}

- (void) loadImage:(NSURL*)url grayscale:(BOOL)grayscale delegate:(id<ImageDelegate>)delegate target:(NSObject*)target;
{
    @synchronized (_imageTable)
    {
        UIImage* image = [_imageTable objectForKey:url];
        UIImage* grayscaleImage = [_grayscaleImageTable objectForKey:url];
        NSMutableArray* imageViewList = [_imageViewTable objectForKey:url];

        if (!grayscale && (image != nil))
        {
            [delegate didFinishLoadingImage:image target:target];
        }
        else if (grayscale && (grayscaleImage != nil))
        {
            [delegate didFinishLoadingImage:grayscaleImage target:target];
        }
        else if (imageViewList != nil)
        {
            NSMutableDictionary* entry = [NSMutableDictionary dictionary];
            [entry setObject:(grayscale ? @"grayscale" : @"none") forKey:@"mode"];
            [entry setObject:delegate forKey:@"delegate"];
            [entry setObject:target forKey:@"target"];
            [imageViewList addObject:entry];
        }
        else
        {
            NSMutableDictionary* entry = [NSMutableDictionary dictionary];
            [entry setObject:(grayscale ? @"grayscale" : @"none") forKey:@"mode"];
            [entry setObject:delegate forKey:@"delegate"];
            [entry setObject:target forKey:@"target"];

            NSURLRequest* request = [NSURLRequest requestWithURL:url];                                 
            NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
            [_dataTable setObject:[[[NSMutableData alloc] init] autorelease] forKey:url];
            [_imageViewTable setObject:[NSMutableArray arrayWithObject:entry] forKey:url];
            [connection start];
        }
    }
}


- (void) connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    NSMutableData* mutableData = [_dataTable objectForKey:connection.originalRequest.URL];
    if (mutableData != nil)
    {
        [mutableData appendData:data];
    }
}

- (void) connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)response
{
    if ([response statusCode] != 200)
    {
        [_dataTable removeObjectForKey:connection.originalRequest.URL];
        [_imageViewTable removeObjectForKey:connection.originalRequest.URL];
        [connection cancel];
    }
}

- (void) connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    [_dataTable removeObjectForKey:connection.originalRequest.URL];
    [_imageViewTable removeObjectForKey:connection.originalRequest.URL];
    [connection cancel];
}

- (void) connectionDidFinishLoading:(NSURLConnection*)connection
{
    @synchronized(_imageTable)
    {
        NSURL* url = connection.originalRequest.URL;
        
        NSMutableData* data = [_dataTable objectForKey:url];
        if ((data != nil) && (data.length > 0))
        {
            UIImage* image = [UIImage imageWithData:data];
            [_imageTable setObject:image forKey:url];
            UIImage* grayscaleImage = [UIImage grayscaleImage:image];
            [_grayscaleImageTable setObject:grayscaleImage forKey:url];

            NSMutableArray* imageViewList = [_imageViewTable objectForKey:url];
            for (NSDictionary* entry in imageViewList)
            {
                id<ImageDelegate> delegate = [entry objectForKey:@"delegate"];
                NSObject* target = [entry objectForKey:@"target"];
                NSString* mode = [entry objectForKey:@"mode"];
                if ([@"grayscale" isEqualToString:mode])
                {
                    [delegate didFinishLoadingImage:grayscaleImage target:target];
                }
                else if ([@"none" isEqualToString:mode])
                {
                    [delegate didFinishLoadingImage:image target:target];                
                }
            }
        }

        [_dataTable removeObjectForKey:url];
        [_imageViewTable removeObjectForKey:url];
    }
}

@end
