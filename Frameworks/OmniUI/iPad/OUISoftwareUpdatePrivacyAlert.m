// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OUISoftwareUpdatePrivacyAlert.h"

#if OUI_SOFTWARE_UPDATE_CHECK

RCS_ID("$Id$");

@implementation OUISoftwareUpdatePrivacyAlert

- initWithDelegate:(id <OUISoftwareUpdatePrivacyAlertDelegate>)delegate;
{
    if (!(self = [super init]))
        return nil;
    
    _nonretained_delegate = delegate;
    
    return self;
}

- (void)dealloc;
{
    [_alertView release];
    [super dealloc];
}

- (void)show;
{
    NSString *messageFormat = NSLocalizedStringFromTableInBundle(@"Allow %@ to periodically report information about your hardware model and iOS version?\nThis will allow us to know which configurations are the most important to support. You can change your answer later in preferences by MUMBLE MUMBLE MUMBLE.", @"OmniUI", OMNI_BUNDLE, @"OmniSoftwareUpdate privacy notice message format");
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleNameKey];
    NSString *message = [NSString stringWithFormat:messageFormat, appName];
    
    _alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Omni Software Update", @"OmniUI", OMNI_BUNDLE, @"OmniSoftwareUpdate privacy notice alert title")
                                            message:message delegate:self
                                  cancelButtonTitle:NSLocalizedStringFromTableInBundle(@"Don't Report", @"OmniUI", OMNI_BUNDLE, @"OmniSoftwareUpdate privacy notice button title")
                                  otherButtonTitles:NSLocalizedStringFromTableInBundle(@"Send Reports", @"OmniUI", OMNI_BUNDLE, @"OmniSoftwareUpdate privacy notice button title"), nil];
    [_alertView show];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
{
    OBPRECONDITION(alertView == _alertView);
    
    BOOL allowReports = (buttonIndex == 1);
    
    [_nonretained_delegate softwareUpdatePrivacyAlert:self completedWithAllowingReports:allowReports];
}

@end

#endif
