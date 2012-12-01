
#import <UIKit/UIKit.h>
#import "BadgeLabel.h"
#import "NSString.h"

@interface FeedCell : UITableViewCell
{
    @private
    BadgeLabel* _counterTextLabel;
}

- (BadgeLabel*) counterTextLabel;

@end
