// Copyright 1997-2006, 2011 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <AppKit/NSUserDefaultsController.h>
#import <OmniFoundation/OFPreference.h> // Lots of subclasses don't import OmniFoundation.h

@class NSArray, NSMutableArray, NSDictionary, NSNotification, NSString;
@class NSBox, NSTextField, NSView;
@class OAPreferenceClientRecord, OAPreferenceController;

#import <AppKit/NSNibDeclarations.h> // For IBOutlet

@interface OAPreferenceClient : NSUserDefaultsController
{
@private
    IBOutlet NSView *controlBox;
    IBOutlet NSView *initialFirstResponder;
    IBOutlet NSView *lastKeyView;
    
    OAPreferenceController *_nonretained_controller;
    NSString *_title;
    NSMutableArray *_preferences;
}

- initWithPreferenceClientRecord:(OAPreferenceClientRecord *)clientRecord controller:(OAPreferenceController *)controller;
- initWithTitle:(NSString *)newTitle defaultsArray:(NSArray *)newDefaultsArray controller:(OAPreferenceController *)controller;

@property(readonly, nonatomic) NSString *title;
@property(readonly, nonatomic) OAPreferenceController *controller;

@property(readonly, nonatomic) NSView *controlBox;
@property(readonly, nonatomic) NSView *initialFirstResponder;
@property(readonly, nonatomic) NSView *lastKeyView;

- (void)resetFloatValueToDefaultNamed:(NSString *)defaultName inTextField:(NSTextField *)textField;
- (void)resetIntValueToDefaultNamed:(NSString *)defaultName inTextField:(NSTextField *)textField;

// This is an action, so don't change its type
- (IBAction)restoreDefaults:(id)sender;
- (void)restoreDefaultsNoPrompt;
- (BOOL)haveAnyDefaultsChanged;

// The default implementations of these methods do nothing:  each subclass is expected to implement them.
- (void)updateUI;
- (void)setValueForSender:(id)sender;
- (void)willBecomeCurrentPreferenceClient;
- (void)didBecomeCurrentPreferenceClient;
- (void)resignCurrentPreferenceClient;
    
// These are public so they can be subclassed.
- (void)valuesHaveChanged;
- (void)controlTextDidEndEditing:(NSNotification *)notification;

// NSNibAwaking informal protocol
// Be sure to call super if you subclass this.
- (void)awakeFromNib;

@end
