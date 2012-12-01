
#import <Foundation/Foundation.h>
#import "Account.h"

@interface AccountTypeService : NSObject
{
    @private
    NSMutableArray* _accountTypes;
}

- (void) addAccountType:(NSString*)accountType;
- (void) removeAccountType:(NSString*)accountType;

- (NSArray*) accountTypes;

@end
