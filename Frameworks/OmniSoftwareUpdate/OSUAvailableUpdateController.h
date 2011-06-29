// Copyright 2007-2008, 2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <AppKit/NSWindowController.h>

@class NSArrayController, NSButton, NSImageView, NSProgressIndicator, NSSplitView, NSTableView, NSTextField;
@class WebView;
@class OSUItem;

extern NSString * const OSUAvailableUpdateControllerAvailableItemsBinding;
extern NSString * const OSUAvailableUpdateControllerCheckInProgressBinding;

@interface OSUAvailableUpdateController : NSWindowController
{
    // Outlets
    IBOutlet NSArrayController *_availableItemController;
    IBOutlet NSTextField *_titleTextField;
    IBOutlet NSTextField *_messageTextField;
    IBOutlet NSProgressIndicator *_spinner;
    IBOutlet NSSplitView *_itemsAndReleaseNotesSplitView;
    IBOutlet NSTableView *_itemTableView;
    IBOutlet WebView *_releaseNotesWebView;
    IBOutlet NSImageView *_appIconImageView;
    IBOutlet NSButton *_installButton;
    IBOutlet NSButton *_cancelButton;
    
    IBOutlet NSView *_itemAlertPane;
    IBOutlet NSTextField *_itemAlertMessage;
    
    BOOL _displayingWarningPane;

    // KVC
    NSArray *_itemSortDescriptors;
    NSPredicate *_itemFilterPredicate;
    NSArray *_availableItems;
    NSIndexSet *_selectedItemIndexes;
    OSUItem *_selectedItem;
    BOOL _loadingReleaseNotes;
    BOOL _checkInProgress;
}

+ (OSUAvailableUpdateController *)availableUpdateController:(BOOL)shouldCreate;

- (IBAction)installSelectedItem:(id)sender;
- (IBAction)ignoreSelectedItem:(id)sender;
- (IBAction)ignoreCertainTracks:(id)sender;

// KVC
- (OSUItem *)selectedItem;
- (NSString *)ignoreTrackItemTitle;

@end
