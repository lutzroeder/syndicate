
#import "Account.h"

@implementation Account

- (id) init
{
    self = [super init];

    _state = [[NSMutableDictionary alloc] init];

    [self setObject:NSStringFromClass(self.class) forKey:@"identifier"];

    return self;
}

- (void) dealloc
{
    [self removeObjectForKey:@"identifier"];
    [_grayscaleImage release];
    [_image release];
    [_state release];
    [super dealloc];
}

- (id) objectForKey:(NSString*)key
{
    return [_state objectForKey:key];
}

- (void) setObject:(id)value forKey:(NSString*)key
{
    [_state setObject:value forKey:key];
}

- (void) removeObjectForKey:(NSString*)key
{
    [_state removeObjectForKey:key];
}

- (NSEnumerator*) keyEnumerator
{
    return [_state keyEnumerator];
}

- (NSString*) identifier
{
    return [self objectForKey:@"identifier"];
}

- (UIImage*) image
{
    if (_image == nil)
    {
        _image = [[UIImage imageNamed:NSStringFromClass(self.class)] retain];
    }
    return _image;
}

- (UIImage*) grayscaleImage
{
    if (_grayscaleImage == nil)
    {
        _grayscaleImage = [[UIImage grayscaleImage:self.image] retain];
    }
    return _grayscaleImage;
}

- (NSString*) name
{
    return nil;
}

- (id <Async>) authenticate 
{
    return nil;
}

- (id <Async>) synchronize
{
    return nil;
}

- (BOOL) handleOpenURL:(NSURL*)url
{
    return NO;
}

- (NSString*) contentToHtml:(NSString*)string
{
    return string;
}

@end
