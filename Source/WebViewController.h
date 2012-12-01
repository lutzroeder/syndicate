
#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>
#import "NSString.h"

@interface WebViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>
{
    UIWebView* _webView;
    NSURLRequest* _request;
 
    UIToolbar* _actionToolbar;
    UIBarButtonItem* _navigationButton;
    UIBarButtonItem* _backButton;
    UIBarButtonItem* _forwardButton;
    UIBarButtonItem* _refreshButton;
    UIBarButtonItem* _stopButton;
    UIBarButtonItem* _actionButton;

    UIActivityIndicatorView* _activityIndicatorView;
    UIBarButtonItem* _activityIndicatorButton;
    
    UIView* _errorView;
    UILabel* _errorLabel;
}

- (id) initWithRequest:(NSURLRequest*)request;

- (void) backClick;
- (void) forwardClick;
- (void) refreshClick;
- (void) stopClick;
- (void) actionClick;

@end
