
#import "FeedItemCell.h"
#import "UIImage.h"

@implementation FeedItemCell

static UIImage* _unreadImage = nil;
static UIImage* _highlightedUnreadImage = nil;

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

    if (_unreadImage == nil)
    {
        _unreadImage = [[UIImage imageNamed:@"Unread"] retain];
    }

    if (_highlightedUnreadImage == nil)
    {
        _highlightedUnreadImage = [[UIImage highlightedImage:_unreadImage] retain];
    }

    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.imageView.image = _unreadImage;
    self.imageView.highlightedImage = _highlightedUnreadImage;
    
    _richTextLabel = [[RichTextLabel alloc] init];    
    [self.contentView addSubview:_richTextLabel];
    
    return self;
}

- (void) dealloc
{
    [_richTextLabel release];
    [super dealloc];
}

- (void)layoutSubviews 
{
    [super layoutSubviews];
    _richTextLabel.frame = CGRectMake(30, 0, self.contentView.bounds.size.width - 30, self.contentView.bounds.size.height);
}

- (RichTextLabel*) richTextLabel
{
    return _richTextLabel;
}

- (void) setUnread:(BOOL)unread
{
    self.imageView.hidden = !unread;
}

@end
