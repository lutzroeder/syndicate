
#import <UIKit/UIKit.h>
#import "RichTextLabel.h"

@interface FeedItemCell : UITableViewCell
{
    @private
    RichTextLabel* _richTextLabel;
}

- (RichTextLabel*) richTextLabel;
- (void) setUnread:(BOOL)unread;

@end
