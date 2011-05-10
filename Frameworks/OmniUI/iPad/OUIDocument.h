// Copyright 2010-2011 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <OmniFoundation/OFObject.h>
#import <OmniUI/OUIDocumentProtocol.h>

@class OUIDocumentProxy, OUIUndoIndicator, OUIDocumentViewController;
@protocol OUIDocumentViewController;

@interface OUIDocument : OFObject <OUIDocument>
{
@private
    OUIDocumentProxy *_proxy;
    NSURL *_url;
    
    NSUndoManager *_undoManager;
    UIViewController <OUIDocumentViewController> *_viewController;
    OUIUndoIndicator *_undoIndicator;
    
    NSTimer *_saveTimer;
    BOOL _hasUndoGroupOpen;
    BOOL _hasDoneAutosave;
}

- initWithExistingDocumentProxy:(OUIDocumentProxy *)proxy error:(NSError **)outError;
- initEmptyDocumentToBeSavedToURL:(NSURL *)url error:(NSError **)outError;

@property(readonly) NSURL *url;
@property(readonly) NSUndoManager *undoManager;
@property(readonly) UIViewController *viewController;

- (BOOL)saveAsNewDocumentToURL:(NSURL *)url error:(NSError **)outError;

- (void)finishUndoGroup;
- (IBAction)undo:(id)sender;

- (BOOL)hasUnsavedChanges;
- (BOOL)saveForClosing:(NSError **)outError;
- (void)scheduleAutosave; // Will happen automatically for undoable changes, but for view stat changes that you want to be saved, you can call this.

// Subclass responsibility

/*
 self.proxy, self.url and self.undoManager will be set appropriately when this is called. If proxy is nil, this is a new document. The URL will be set no matter what.
 */
- (BOOL)loadDocumentContents:(NSError **)outError;
- (UIViewController *)makeViewController;
- (BOOL)saveToURL:(NSURL *)url isAutosave:(BOOL)isAutosave error:(NSError **)outError;

// Optional subclass methods
- (void)willFinishUndoGroup;
- (BOOL)shouldUndo;
- (void)didUndo;
- (UIView *)viewToMakeFirstResponderWhenInspectorCloses;

@end
