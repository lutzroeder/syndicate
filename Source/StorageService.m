
#import "StorageService.h"

@implementation StorageService

- (id) init
{
    NSFileManager* fileManager = [NSFileManager defaultManager];

    NSURL* baseUrl = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL* url = [baseUrl URLByAppendingPathComponent:@"Syndicate"];

    self = [super initWithFileURL:url];
    
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    [options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
    [options setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
    /* if([fileManager respondsToSelector:@selector(URLForUbiquityContainerIdentifier:)])
    {
        NSURL* cloudUrl = [fileManager URLForUbiquityContainerIdentifier:nil];
        if (cloudUrl != nil)
        {
            NSLog(@"URLForUbiquityContainerIdentifier:%@", cloudUrl);
            [options setObject:@"com.lutzroeder.Syndicate" forKey:NSPersistentStoreUbiquitousContentNameKey];
            [options setObject:[cloudUrl URLByAppendingPathComponent:@"Logs"] forKey:NSPersistentStoreUbiquitousContentURLKey];
        }
    }*/

    self.persistentStoreOptions = options;
    self.managedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentContentsChanged:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:self.managedObjectContext.persistentStoreCoordinator];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentStateChanged:) name:UIDocumentStateChangedNotification object:self];

    if ([fileManager fileExistsAtPath:self.fileURL.path])
    {
        [self addSkipBackupAttributeToItemAtURL:self.fileURL];
        [self openWithCompletionHandler:^(BOOL success) {
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"StorageStart" object:self userInfo:nil]];
        }];
    }
    else if (self.documentState == UIDocumentStateClosed)
    {
        [self saveToURL:self.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            [self addSkipBackupAttributeToItemAtURL:self.fileURL];
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"StorageStart" object:self userInfo:nil]];
        }];
    }
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:self.managedObjectContext.persistentStoreCoordinator];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDocumentStateChangedNotification object:self];
    [super dealloc];
}

- (void) addSkipBackupAttributeToItemAtURL:(NSURL*)url
{
    assert([[NSFileManager defaultManager] fileExistsAtPath:url.path]);
    NSError *error = nil;
    BOOL success = [url setResourceValue: [NSNumber numberWithBool:YES] forKey: NSURLIsExcludedFromBackupKey error: &error];
    assert(success);
}

- (void) documentContentsChanged:(NSNotification*)notification
{
    [self.managedObjectContext performBlock:^{
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"StorageRefresh" object:self userInfo:nil]];
    }];
}

- (void) documentStateChanged:(NSNotification*)notification
{
    if (self.documentState & UIDocumentStateInConflict) 
    {
        NSArray *conflictingVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:self.fileURL];
        for (NSFileVersion* version in conflictingVersions)
        {
            version.resolved = YES;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSFileCoordinator* coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            NSError* error;
            [coordinator coordinateWritingItemAtURL:self.fileURL options:NSFileCoordinatorWritingForDeleting error:&error byAccessor:^(NSURL *newURL) {
                [NSFileVersion removeOtherVersionsOfItemAtURL:self.fileURL error:NULL];
            }];
            [coordinator release];
            if (error)
            {
                NSLog(@"FAIL [StorageService documentStateChanged:] %@ (%@)", error.localizedDescription, error.localizedFailureReason);
            }
        });
    } 
    else if (self.documentState & UIDocumentStateSavingError) 
    {
        // try again?
    }
}

- (void) save
{
    if ((self.managedObjectContext != nil) && [self.managedObjectContext hasChanges])
    {        
        [self saveToURL:self.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            if (!success)
            {
                NSLog(@"FAIL [StorageService save] %@", self.managedObjectContext);
                abort();
            }
        }];
    }
}

- (NSString*) quote:(NSString*)string
{
    return [string stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
}

- (NSArray*) fetchEntity:(NSString*)entity predicate:(NSPredicate*)predicate
{
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    [fetchRequest setPredicate:predicate];
    NSArray* result = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    [fetchRequest release];
    return result;
}

- (void) setValue:(NSObject*)value forKey:(NSString*)key inEntitiy:(NSManagedObject*)entity
{
    NSObject* current = [entity valueForKey:key];
    if ((current == nil) || ![current isEqual:value])
    {
        [entity setValue:value forKey:key];
    }
}

- (void) replaceItem:(NSDictionary*)item
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(account == '%@') AND (feed == '%@') AND (identifier == '%@')", [self quote:[item objectForKey:@"account"]], [self quote:[item objectForKey:@"feed"]], [self quote:[item objectForKey:@"identifier"]]]];
    NSArray* result = [self fetchEntity:@"FeedItem" predicate:predicate];

    NSEntityDescription* entitiy = [[self.managedObjectModel entitiesByName] objectForKey:@"FeedItem"];     
    NSManagedObject* target = (result.count == 1) ? [[result objectAtIndex:0] retain] : [[NSManagedObject alloc] initWithEntity:entitiy insertIntoManagedObjectContext:self.managedObjectContext];
    [self setValue:[item objectForKey:@"account"] forKey:@"account" inEntitiy:target];
    [self setValue:[item objectForKey:@"feed"] forKey:@"feed" inEntitiy:target];
    [self setValue:[item objectForKey:@"name"] forKey:@"name" inEntitiy:target];
    [self setValue:[item objectForKey:@"identifier"] forKey:@"identifier" inEntitiy:target];
    [self setValue:[item objectForKey:@"image"] forKey:@"image" inEntitiy:target];
    [self setValue:[item objectForKey:@"link"] forKey:@"link" inEntitiy:target];
    [self setValue:[item objectForKey:@"from"] forKey:@"from" inEntitiy:target];
    [self setValue:[item objectForKey:@"fromLink"] forKey:@"fromLink" inEntitiy:target];
    [self setValue:[item objectForKey:@"to"] forKey:@"to" inEntitiy:target];
    [self setValue:[item objectForKey:@"toLink"] forKey:@"toLink" inEntitiy:target];
    [self setValue:[item objectForKey:@"title"] forKey:@"title" inEntitiy:target];
    [self setValue:[item objectForKey:@"content"] forKey:@"content" inEntitiy:target];
    [self setValue:[item objectForKey:@"date"] forKey:@"date" inEntitiy:target];
    [self setValue:[item objectForKey:@"message"] forKey:@"message" inEntitiy:target];
    [self setValue:[item objectForKey:@"picture"] forKey:@"picture" inEntitiy:target];
    [self setValue:[item objectForKey:@"unread"] forKey:@"unread" inEntitiy:target];
    [target release];
}

- (NSArray*) feeds
{
    NSMutableDictionary* group = [NSMutableDictionary dictionary];

    NSArray* result = [self fetchEntity:@"FeedItem" predicate:nil];
    if ((result != nil) && (result.count > 0))
    {
        for (NSManagedObject* item in result)
        {
            NSMutableDictionary* key = [NSMutableDictionary dictionary];
            [key setObject:[item valueForKey:@"account"] forKey:@"account"];
            [key setObject:[item valueForKey:@"feed"] forKey:@"feed"];
            [key setObject:[item valueForKey:@"name"] forKey:@"name"];
            
            NSString* image = [item valueForKey:@"image"];
            [key setObject:(image ? image : @"") forKey:@"image"];

            NSNumber* count = [group objectForKey:key];
            if (count == nil)
            {
                count = [NSNumber numberWithInt:0];
            }
            
            if ([[item valueForKey:@"unread"] boolValue])
            {
                count = [NSNumber numberWithInt:[count intValue] + 1];
            }

            [group setObject:count forKey:key];
        }
    }
        
    NSMutableArray* feeds = [NSMutableArray arrayWithCapacity:group.count];
    for (NSMutableDictionary* key in group.allKeys) 
    {
        NSMutableDictionary* item = [NSMutableDictionary dictionary];
        [item setObject:[key objectForKey:@"account"] forKey:@"account"];
        [item setObject:[key objectForKey:@"feed"] forKey:@"feed"];
        [item setObject:[key objectForKey:@"name"] forKey:@"name"];
        [item setObject:[key objectForKey:@"image"] forKey:@"image"];
        [item setObject:[NSNumber numberWithInt:[[group objectForKey:key] intValue]] forKey:@"unread"];

        [feeds addObject:item];
    }

    return [feeds sortedArrayUsingComparator:^(id feed1, id feed2) { 
        NSString* name1 = [feed1 objectForKey:@"name"];
        NSString* name2 = [feed2 objectForKey:@"name"];
        NSComparisonResult result = [name1 compare:name2 options:NSCaseInsensitiveSearch]; 
        if (result == NSOrderedSame)
        {
            NSString* account1 = [feed1 objectForKey:@"account"];
            NSString* account2 = [feed2 objectForKey:@"account"];
            result = [account1 compare:account2 options:NSCaseInsensitiveSearch];
        }
        return result;
    }];
}

- (NSArray*) itemsForFeed:(NSDictionary*)feed
{
    NSMutableArray* items = [NSMutableArray array];

    NSPredicate* predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(account == '%@') AND (feed == '%@') AND (name == '%@') AND (image == '%@')", [self quote:[feed objectForKey:@"account"]], [self quote:[feed objectForKey:@"feed"]], [self quote:[feed objectForKey:@"name"]], [self quote:[feed objectForKey:@"image"]]]];
    NSArray* result = [self fetchEntity:@"FeedItem" predicate:predicate];
    if ((result != nil) && (result.count > 0))
    {
        for (NSManagedObject* source in result)
        {
            NSMutableDictionary* target = [NSMutableDictionary dictionary];
            [target setObject:[feed objectForKey:@"account"] forKey:@"account"];
            [target setObject:[feed objectForKey:@"feed"] forKey:@"feed"];
            [target setObject:[feed objectForKey:@"name"] forKey:@"name"];
            [target setObject:[source valueForKey:@"identifier"] forKey:@"identifier"];
            [target setObject:[source valueForKey:@"image"] forKey:@"image"];
            [target setObject:[source valueForKey:@"link"] forKey:@"link"];
            [target setObject:[source valueForKey:@"from"] forKey:@"from"];
            [target setObject:[source valueForKey:@"fromLink"] forKey:@"fromLink"];
            [target setObject:[source valueForKey:@"to"] forKey:@"to"];
            [target setObject:[source valueForKey:@"toLink"] forKey:@"toLink"];
            [target setObject:[source valueForKey:@"title"] forKey:@"title"];
            [target setObject:[source valueForKey:@"content"] forKey:@"content"];
            [target setObject:[source valueForKey:@"message"] forKey:@"message"];
            [target setObject:[source valueForKey:@"picture"] forKey:@"picture"];
            [target setObject:[source valueForKey:@"date"] forKey:@"date"];
            [target setObject:[source valueForKey:@"unread"] forKey:@"unread"];
            [items addObject:target];            
        }
    }

    return [items sortedArrayUsingComparator:^(id item1, id item2) { 
        NSDate* date1 = [item1 objectForKey:@"date"];
        NSDate* date2 = [item2 objectForKey:@"date"];
        return [date2 compare:date1];
    }];}

- (void) deleteReadItemsForAccount:(NSString*)account
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(account == '%@') AND (unread == NO)", [self quote:account]]];
    NSArray* result = [self fetchEntity:@"FeedItem" predicate:predicate];
    if ((result != nil) && (result.count > 0))
    {
        for (NSManagedObject* item in result)
        {
            [self.managedObjectContext deleteObject:item];
        }
    }
}

- (void) deleteItems:(NSArray*)identifiers forAccount:(NSString*)account
{
    if ([identifiers count] > 0)
    {
        for (NSString* identifier in identifiers)
        {
            NSPredicate* predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(account == '%@') AND (identifier == '%@')", [self quote:account], [self quote:identifier]]];
            NSArray* result = [self fetchEntity:@"FeedItem" predicate:predicate];
            if (result != nil)
            {
                for (NSManagedObject* item in result)
                {
                    [self.managedObjectContext deleteObject:item];
                }
            }
        }
    }
}

- (void) deleteAccount:(NSString*)account
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(account == '%@')", [self quote:account]]];
    NSArray* result = [self fetchEntity:@"FeedItem" predicate:predicate];
    if ((result != nil) && (result.count > 0))
    {
        for (NSManagedObject* item in result)
        {
            [self.managedObjectContext deleteObject:item];
        }        

        [self save];
    }
}

- (void) deleteUnusedAccounts:(NSArray*)accounts
{
    NSMutableString* condition = [NSMutableString string];
    for (NSString* account in accounts)
    {
        if (condition.length > 0)
        {
            [condition appendString:@" AND "];
        }
        [condition appendFormat:@"(account != '%@')", account];
    }

    NSPredicate* predicate = (condition.length > 0) ? [NSPredicate predicateWithFormat:condition] : nil;
    NSArray* result = [self fetchEntity:@"FeedItem" predicate:predicate];
    if ((result != nil) && (result.count > 0))
    {
        for (NSManagedObject* item in result)
        {
            [self.managedObjectContext deleteObject:item];
        }        

        [self save];
    }
}

- (void) updateItem:(NSDictionary*)item unread:(BOOL)unread
{
    NSMutableString* condition = [NSMutableString stringWithFormat:@"(account='%@') AND (identifier='%@')", [self quote:[item objectForKey:@"account"]], [self quote:[item objectForKey:@"identifier"]]];
    if (([item objectForKey:@"Feed"] != nil) && ([item objectForKey:@"Name"] != nil))
    {
        [condition appendFormat:@" AND (feed == '%@') AND (name == '%@')", [self quote:[item objectForKey:@"feed"]], [self quote:[item objectForKey:@"name"]]];
    }

    NSPredicate* predicate = [NSPredicate predicateWithFormat:condition];
    NSArray* result = [self fetchEntity:@"FeedItem" predicate:predicate];
    if ((result != nil) && (result.count > 0))
    {
        for (NSManagedObject* item in result)
        {
            [item setValue:[NSNumber numberWithBool:unread] forKey:@"unread"];
        }        
    }
}

- (void) updateFeed:(NSDictionary*)feed unread:(BOOL)unread
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(account == '%@') AND (feed == '%@') AND (name == '%@')", [self quote:[feed objectForKey:@"account"]], [self quote:[feed objectForKey:@"feed"]], [self quote:[feed objectForKey:@"name"]]]];
    NSArray* result = [self fetchEntity:@"FeedItem" predicate:predicate];
    if ((result != nil) && (result.count > 0))
    {
        for (NSManagedObject* item in result)
        {
            [item setValue:[NSNumber numberWithBool:unread] forKey:@"unread"];
        }
    }
}

- (NSArray*) itemsForAccount:(NSString*)account unread:(BOOL)unread
{
    NSMutableArray* items = [[NSMutableArray alloc] init];

    NSPredicate* predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(account == '%@') AND (unread == %@)", [self quote:account], unread ? @"YES" : @"NO"]];
    NSArray* result = [self fetchEntity:@"FeedItem" predicate:predicate];
    if ((result != nil) && (result.count > 0))
    {
        for (NSManagedObject* item in result)
        {
            [items addObject:[item valueForKey:@"identifier"]];
        }
    }

    return [items autorelease];
}

- (NSInteger) unreadCountForFeed:(NSDictionary*)feed
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(account == '%@') AND (feed == '%@') AND (name == '%@')", [self quote:[feed objectForKey:@"account"]], [self quote:[feed objectForKey:@"feed"]], [self quote:[feed objectForKey:@"name"]]]];
    NSArray* result = [self fetchEntity:@"FeedItem" predicate:predicate];
    return (result == nil) ? 0 : result.count;
}

- (void) handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
    NSLog(@"FAIL [StorageService handleError:userInteractionPermitted:] %@", error);
}

@end
