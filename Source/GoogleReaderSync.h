
#import <Foundation/Foundation.h>
#import "ServiceProvider.h"
#import "Async.h"
#import "Account.h"
#import "WebUtility.h"
#import "StorageService.h"
#import "NSString.h"

@interface GoogleReaderSync : NSObject <NSURLConnectionDelegate, Async>
{
    @private
    id<ServiceProvider> _serviceProvider;
    Account* _account;
    NSString* _clientId;
    NSString* _clientSecret;
    id<AsyncDelegate> _delegate;

    NSMutableArray* _actions;

    NSURLConnection* _connection;
    NSMutableData* _data;
    
    NSMutableArray* _readServerItems;
    NSMutableArray* _readClientItems;
    float _progress;
    NSString* _accessToken;
    NSString* _authorization;
    NSString* _continuation;
    NSString* _token;
}

- (id) initWithServiceProvider:(id<ServiceProvider>)serviceProvider account:(Account*)account clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret;

- (void) resetConnection;
- (void) resetSync;

- (void) nextAction;

- (void) beginAuthentication;
- (void) endAuthentication;
- (void) createReadItems;
- (void) beginDownloadReadingList;
- (void) endDownloadReadingList;
- (void) beginGetToken;
- (void) endGetToken;
- (void) beginUploadReadState;
- (void) endUploadReadState;
- (void) updateReadState;

@end
