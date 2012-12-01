
#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <CoreData/CoreData.h>

@interface StorageService : UIManagedDocument
{
}

- (void) save;

- (void) replaceItem:(NSDictionary*)item;
- (void) deleteReadItemsForAccount:(NSString*)account;
- (void) deleteItems:(NSArray*)identifiers forAccount:(NSString*)account;
- (void) deleteAccount:(NSString*)account;
- (void) deleteUnusedAccounts:(NSArray*)accounts;
- (void) updateItem:(NSDictionary*)item unread:(BOOL)unread;
- (void) updateFeed:(NSDictionary*)feed unread:(BOOL)unread;
- (NSArray*) itemsForAccount:(NSString*)account unread:(BOOL)unread;
- (NSArray*) feeds;
- (NSArray*) itemsForFeed:(NSDictionary*)feed;
- (NSInteger) unreadCountForFeed:(NSDictionary*)feed;

- (void) documentContentsChanged:(NSNotification*)notification;
- (void) documentStateChanged:(NSNotification*)notification;

@end
