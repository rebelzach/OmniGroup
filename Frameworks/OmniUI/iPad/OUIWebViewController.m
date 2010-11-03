// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniUI/OUIWebViewController.h>

#import <MessageUI/MessageUI.h>
#import <OmniUI/OUIAppController.h>

RCS_ID("$Id$")

@interface OUIWebViewController () <MFMailComposeViewControllerDelegate>
@end

@implementation OUIWebViewController

- (void)loadView 
{
    UIWebView *webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)] autorelease];
    webView.delegate = self;
    webView.scalesPageToFit = YES;
    webView.dataDetectorTypes = UIDataDetectorTypeAll;

#if 0
    // Transparent?
    webView.opaque = NO;
    webView.backgroundColor = [UIColor clearColor];
#endif

    _backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Back", @"OmniUI", OMNI_BUNDLE, @"Web view nagivation button for going back in history.")
                                                   style:UIBarButtonItemStyleBordered target:self action:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = _backButton;

    self.view = webView;
}

- (void)dealloc;
{
    UIWebView *webView = (UIWebView *)self.view;
    webView.delegate = nil;
    [_backButton release];
    [super dealloc];
}

- (IBAction)openInSafari:(id)sender;
{
    [[UIApplication sharedApplication] openURL:[self URL]];
}

- (IBAction)goBack:(id)sender;
{
    UIWebView *webView = (UIWebView *)self.view;
    [webView goBack];
    _backButton.enabled = webView.canGoBack;
}

- (IBAction)close:(id)sender;
{
    [[[OUIAppController controller] topViewController] dismissModalViewControllerAnimated:YES];
}

- (void)_updateBarButtonItemForURL:(NSURL *)aURL;
{
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close:)] autorelease];
}

- (void)setURL:(NSURL *)aURL;
{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:aURL];
    [(UIWebView *)self.view loadRequest:request];
    [request autorelease];
    [self _updateBarButtonItemForURL:aURL];
}

- (NSURL *)URL;
{
    return [[(UIWebView *)self.view request] URL];
}

- (UIWebView *)webView;
{
    return (UIWebView *)self.view;
}

- (void)loadData:(NSData *)data ofType:(NSString *)mimeType;
{
    [(UIWebView *)self.view loadData:data MIMEType:mimeType textEncodingName:@"utf-8" baseURL:nil];
}

- (NSArray *)saveState;
{
    return nil;
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;
{
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
#ifdef DEBUG_kc
        NSLog(@"WebView link: %@", [request URL]);
#endif
	NSString *scheme = [[[request URL] scheme] lowercaseString];
	
	if ([scheme isEqualToString:@"mailto"]) {
	    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
	    controller.mailComposeDelegate = self;
	    [controller setToRecipients:[NSArray arrayWithObject:[[request URL] resourceSpecifier]]];
	    [self presentModalViewController:controller animated:YES];
	    [controller release];
            return NO; // Don't load this in the WebView
        } else {
            if ([OUIAppController canHandleURLScheme:scheme] && [[[UIApplication sharedApplication] delegate] application:nil handleOpenURL:[request URL]])
                return NO; // Don't load this in the WebView
        }
    }

    // Go ahead and load this in the WebView
    [self _updateBarButtonItemForURL:[request URL]];

    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView;
{
    _backButton.enabled = webView.canGoBack;
}

#pragma mark -
#pragma mark UIViewController subclass

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
{
    return YES;
}

@end
