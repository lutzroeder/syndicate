
#import "FeedCell.h"

@implementation FeedCell

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    self.textLabel.backgroundColor = [UIColor clearColor];
    _counterTextLabel = [[BadgeLabel alloc] init];
    _counterTextLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
    _counterTextLabel.fillColor = [UIColor colorWithRed:139/255.0 green:152/255.0 blue:179/255.0 alpha:1];
    _counterTextLabel.highlightedFillColor = [UIColor whiteColor];
    _counterTextLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:_counterTextLabel];
    
    return self;
}

- (void) dealloc
{
    [_counterTextLabel release];
    [super dealloc];
}

- (BadgeLabel*) counterTextLabel
{
    return _counterTextLabel;
}

- (void) setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    float badgeWidth = 0;
    if (![NSString isNullOrEmpty:_counterTextLabel.text])
    {
        badgeWidth = [_counterTextLabel.text sizeWithFont:_counterTextLabel.font].width + 10;
        if (badgeWidth < 30)
        {
            badgeWidth = 30;
        }
    }

    CGRect bounds = self.contentView.bounds;
    _counterTextLabel.frame = CGRectMake(bounds.size.width - badgeWidth - 10, (float) round((bounds.size.height - 21) / 2), badgeWidth, 20);

    CGFloat textWidth = (badgeWidth > 0) ? (_counterTextLabel.frame.origin.x - 10 - 48) : (bounds.size.width - 12 - 48);
    self.textLabel.frame = CGRectMake(48, self.textLabel.frame.origin.y, textWidth, self.textLabel.frame.size.height);
    
    CGFloat imageSize = 30;
    self.imageView.frame = CGRectMake((bounds.size.height - imageSize) / 2, (bounds.size.height - imageSize) / 2, imageSize, imageSize);
}

@end
