
#import <Foundation/Foundation.h>

@interface WebUtility : NSObject

+ (NSString*) htmlEncode:(NSString*)string;
+ (NSString*) htmlDecode:(NSString*)string;
+ (NSString*) urlEncode:(NSString*)string;
+ (NSString*) urlDecode:(NSString*)string;
+ (NSString*) stripHtmlTags:(NSString*)string;
+ (NSString*) base64Encode:(NSData*)data;
+ (NSError*) errorForHttpStatusCode:(NSInteger)statusCode;
+ (NSDictionary*) parseUrlParameters:(NSString*)string afterSeparator:(NSString*)separator;

@end
