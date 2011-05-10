// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <UIKit/UIViewController.h>

#import <OmniUI/OUIDocumentPickerView.h>
#import <OmniUI/OUIReplaceDocumentAlert.h>

@class OFSetBinding;
@class OUIDocumentProxy, OUIDocumentPickerView;
@protocol OUIDocumentPickerDelegate;

@interface OUIDocumentPicker : UIViewController <UIGestureRecognizerDelegate, OUIDocumentPickerViewDelegate, UIDocumentInteractionControllerDelegate, UITextFieldDelegate, OUIReplaceDocumentAlertDelegate>
{
@private
    id <OUIDocumentPickerDelegate> _nonretained_delegate;
    
    OUIDocumentPickerView *_previewScrollView;
    UIButton *_titleLabel;
    UILabel *_dateLabel;
    UIView *_buttonGroupView;
    UIButton *_favoriteButton;
    UIButton *_exportButton;
    UIButton *_newDocumentButton;
    UIButton *_deleteButton;
    UITextField *_titleEditingField;
    
    NSString *_directory;
    NSSet *_proxies;
    OFSetBinding *_proxiesBinding;
    id _proxyTappedTarget;
    SEL _proxyTappedAction;
    NSMutableArray *_actionSheetActions;
    
    OUIDocumentProxy *_selectedProxyBeforeOrientationChange;
    NSURL *_editingProxyURL;
    
    UIActionSheet *_nonretainedActionSheet;
    BOOL _editingTitle;
    BOOL _keyboardIsShowing;
    BOOL _isRevealingNewDocument;
    BOOL _isInnerController;
    
    OUIReplaceDocumentAlert *_replaceDocumentAlert;
    
    BOOL _loadingFromNib;
}

+ (NSString *)userDocumentsDirectory;
+ (NSString *)sampleDocumentsDirectory;
+ (void)copySampleDocumentsToUserDocuments;

+ (NSString *)pathToSampleDocumentNamed:(NSString *)name ofType:(NSString *)fileType;
+ (NSString *)availablePathInDirectory:(NSString *)dir baseName:(NSString *)baseName extension:(NSString *)extension counter:(NSUInteger *)ioCounter;

- (OUIDocumentProxy *)proxyByInstantiatingSampleDocumentNamed:(NSString *)name ofType:(NSString *)fileType;

@property(assign,nonatomic) IBOutlet id <OUIDocumentPickerDelegate> delegate;

@property(retain) IBOutlet OUIDocumentPickerView *previewScrollView;
@property(retain) IBOutlet UIButton *titleLabel;
@property(retain) IBOutlet UILabel *dateLabel;
@property(retain) IBOutlet UIView *buttonGroupView;
@property(retain) IBOutlet UIButton *favoriteButton;
@property(retain) IBOutlet UIButton *exportButton;
@property(retain) IBOutlet UIButton *newDocumentButton;
@property(retain) IBOutlet UIButton *deleteButton;

@property(readonly) UITextField *titleEditingField;
@property(copy,nonatomic) NSString *directory;
@property(retain) id proxyTappedTarget;
@property(assign) SEL proxyTappedAction;

@property(assign) BOOL editingTitle;

- (void)rescanDocuments;
- (void)rescanDocumentsScrollingToURL:(NSURL *)targetURL;
- (void)rescanDocumentsScrollingToURL:(NSURL *)targetURL animated:(BOOL)animated;
- (BOOL)hasDocuments;

- (void)revealAndActivateNewDocumentAtURL:(NSURL *)newDocumentURL;

- (OUIDocumentProxy *)selectedProxy;
- (OUIDocumentProxy *)proxyWithURL:(NSURL *)url;
- (OUIDocumentProxy *)proxyNamed:(NSString *)documentName;
- (BOOL)canEditProxy:(OUIDocumentProxy *)proxy;
- (BOOL)deleteDocumentWithoutPrompt:(OUIDocumentProxy *)proxy error:(NSError **)outError;
- (NSURL *)renameProxy:(OUIDocumentProxy *)proxy toName:(NSString *)name type:(NSString *)documentUTI;

@property(readonly,nonatomic) NSString *documentTypeForNewFiles;

- (NSURL *)urlForNewDocumentOfType:(NSString *)documentUTI;
- (NSURL *)urlForNewDocumentWithName:(NSString *)name ofType:(NSString *)documentUTI;
- (void)addDocumentFromURL:(NSURL *)url;

- (void)scrollToProxy:(OUIDocumentProxy *)proxy animated:(BOOL)animated;
- (void)showButtonsAfterEditing;

- (BOOL)okayToOpenMenu;

- (IBAction)favorite:(id)sender;
- (IBAction)newDocumentMenu:(id)sender;
- (IBAction)newDocument:(id)sender;
- (IBAction)duplicateDocument:(id)sender;
- (IBAction)deleteDocument:(id)sender;
- (IBAction)export:(id)sender;
- (IBAction)emailDocument:(id)sender;
- (void)emailPDF:(id)sender;
- (void)emailPNG:(id)sender;
- (IBAction)editTitle:(id)sender;
@end
