
#import "FeedController.h"

@implementation FeedController

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider feed:(NSDictionary*)feed detailViewController:(DetailViewController*)detailViewController;
{
    self = [super init];
    
    _serviceProvider = [serviceProvider retain];
    _feed = [feed retain];
    _detailViewController = [detailViewController retain];
    
    self.title = [_feed objectForKey:@"name"];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageWithSize:16 drawCircleWithSize:12 width:2 color:[UIColor whiteColor] fillColor:nil] style:UIBarButtonItemStylePlain target:self action:@selector(readAllClick)] autorelease];
    
    return self;
}

- (void) dealloc
{
    [_highlightedRichTextLabel release];
    [_items release];
    [_detailViewController release];
    [_feed release];
    [_serviceProvider release];
    [super dealloc];
}

- (RichText*) richTextForRow:(NSMutableDictionary*)item
{    
    RichText* richText = [item objectForKey:@"richText"];
    if (richText == nil)
    {
        richText = [[[RichText alloc] init] autorelease];
        [item setObject:richText forKey:@"richText"];
        
        NSString* message = [item objectForKey:@"message"];
        NSString* title = [item objectForKey:@"title"];
        NSString* content = [item objectForKey:@"content"];
        NSString* picture = [item objectForKey:@"picture"];
        
        if (![NSString isNullOrEmpty:message])
        {
            if (![NSString isNullOrEmpty:[item objectForKey:@"to"]])
            {
                message = [NSString stringWithFormat:NSLocalizedString(@"\"%@\" to %@.", nil), [item objectForKey:@"message"], [item objectForKey:@"to"]];
            }
            
            message = [WebUtility stripHtmlTags:message];
            message = [WebUtility htmlDecode:message];
            
            [richText setColor:[UIColor blackColor]];
            [richText setFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
            [richText addText:message];
            
            if (![NSString isNullOrEmpty:title] || ![NSString isNullOrEmpty:content])
            {
                [richText addSeparator:6];
            }
        }
        
        if (![NSString isNullOrEmpty:title])
        {
            title = [WebUtility stripHtmlTags:title];
            title = [WebUtility htmlDecode:title];
            
            [richText setColor:[UIColor blackColor]];
            [richText setFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]];
            [richText addText:title];
        }
        
        if (![NSString isNullOrEmpty:content])
        {
            content = [WebUtility stripHtmlTags:content];
            content = [WebUtility htmlDecode:content];
            content = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            [richText setColor:[UIColor grayColor]];
            [richText setFont:[UIFont systemFontOfSize:[UIFont systemFontSize] - 1]];
            [richText addText:content maxLines:3];
        }
        
        if (![NSString isNullOrEmpty:picture])
        {            
            ImageService* imageService = [_serviceProvider serviceWithName:@"ImageService"];
            [imageService loadImage:[NSURL URLWithString:picture] grayscale:NO delegate:self target:item];
        }
    }

    return richText;
}

- (void) showItem:(NSDictionary*)item
{
    NSString* link = [item objectForKey:@"link"];
    NSString* title = [WebUtility stripHtmlTags:[WebUtility htmlDecode:[item objectForKey:@"title"]]];
    if ([NSString isNullOrEmpty:title])
    {
        title = [WebUtility stripHtmlTags:[WebUtility htmlDecode:[item objectForKey:@"message"]]];
        if (![NSString isNullOrEmpty:title] && (title.length > 60))
        {
            title = [NSString stringWithFormat:@"%@...", [title substringToIndex:title.length]];
        }
    }
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:link]];
    
    WebViewController* webViewController = [[[WebViewController alloc] initWithRequest:request] autorelease];
    webViewController.navigationItem.title = title;
    if (_detailViewController)
    {
        [_detailViewController setViewController:webViewController];
    }
    else
    {
        [self.navigationController pushViewController:webViewController animated:YES];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_items == nil)
    {
        StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
        _items = [[storageService itemsForFeed:_feed] retain];
    }

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.957 alpha:1];

    if ((_items.count > 0) && (_detailViewController != nil))
    {
        [self showItem:[_items objectAtIndex:0]];
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.tableView reloadData];
}

- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_items count];   
}

- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSMutableDictionary* item = [_items objectAtIndex:indexPath.row];

    RichText* richText = [self richTextForRow:item];
    richText.width = self.tableView.frame.origin.x + self.tableView.frame.size.width - 25 - 2 - 33;
    richText.minHeight = 24;
    
    return richText.height;
}

- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    FeedItemCell* cell = [[[FeedItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FeedItemCell"] autorelease];

    UISwipeGestureRecognizer* swipeGestureRecognizer;
    
    swipeGestureRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)] autorelease];
    [swipeGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    [cell addGestureRecognizer:swipeGestureRecognizer];
    
    swipeGestureRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)] autorelease];
    [swipeGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [cell addGestureRecognizer:swipeGestureRecognizer];
    
    NSMutableDictionary* item = [_items objectAtIndex:indexPath.row];
    cell.richTextLabel.text = [self richTextForRow:item];
    cell.unread = [[item objectForKey:@"unread"] intValue] != 0;
    
    return cell;
}

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSMutableDictionary* item = [_items objectAtIndex:indexPath.row];
    [self showItem:item];

    [item setObject:[[[NSNumber alloc] initWithInt:0] autorelease] forKey:@"unread"];
 
    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
    [storageService updateItem:item unread:NO];

    FeedItemCell* cell = (FeedItemCell*) [tableView cellForRowAtIndexPath:indexPath];
    cell.unread = NO;

    if (_detailViewController == nil)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void) readAllClick
{
    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
    [storageService updateFeed:_feed unread:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) didSwipe:(UIGestureRecognizer*)gestureRecognizer;
{
    FeedItemCell* cell = (FeedItemCell*) gestureRecognizer.view;
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    NSMutableDictionary* item = [_items objectAtIndex:indexPath.row];   

    BOOL unread = [[item objectForKey:@"unread"] boolValue];
    [item setObject:[NSNumber numberWithBool:!unread] forKey:@"unread"];

    StorageService* storageService = [_serviceProvider serviceWithName:@"StorageService"];
    [storageService updateItem:item unread:!unread];

    [cell setUnread:!unread];

    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) didFinishLoadingImage:(UIImage*)image target:(NSObject*)target
{
    NSMutableDictionary* item = (NSMutableDictionary*) target;
    RichText* richText = [self richTextForRow:item];
    [richText addImage:image];

    NSInteger index = [_items indexOfObject:item];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event 
{
    [super touchesEnded:touches withEvent:event];

    if (_highlightedRichTextLabel) 
    {
        // get URL from highlighted element and open
    }
}

@end
