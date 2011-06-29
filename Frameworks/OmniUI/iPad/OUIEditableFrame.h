// Copyright 2010-2011 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <OmniUI/OUIScalingView.h>
#import <CoreText/CoreText.h>
#import <OmniUI/OUIInspector.h>
#import <OmniUI/OUIEditableFrameDelegate.h>
#import <OmniUI/OUILoupeOverlaySubject.h>
#import <OmniUI/OUITextLayout.h>
#import <OmniAppKit/OATextStorage.h>

@class NSMutableAttributedString;

@class OUEFTextPosition, OUEFTextRange, OUITextCursorOverlay, OUILoupeOverlay;
@class OUIEditableFrame, OUITextThumb;

@class CALayer, CAShapeLayer;

@interface OUIEditableFrame : OUIScalingView <UIKeyInput, UITextInputTraits, UITextInput, OATextStorageDelegate, OUIInspectorDelegate, OUILoupeOverlaySubject>
{
@private
    /* The data model: a text storage and a selection range. */
    OATextStorage *_content;
    OUEFTextRange *selection;
    NSUInteger generation;
    NSDictionary *_typingAttributes;
    NSRange markedRange;
    OUITextLayoutSpanBackgroundFilter _backgroundSpanFilter;
    
    /* Attributes for strings that don't specify */
    CTFontRef defaultFont;
    UIColor *textColor;
    CTParagraphStyleRef defaultParagraphStyle;
    
    /* UI settings */
    UIColor *_insertionPointSelectionColor;
    UIColor *_rangeSelectionColor;
    NSDictionary *markedTextStyle; // Supplied by UIKit.
    UIColor *_markedRangeBackgroundColor, *_markedRangeBorderColor;
    CGFloat _markedRangeBorderThickness;
    NSDictionary *_linkTextAttributes;
    id <OUIEditableFrameDelegate> delegate;
    CGSize layoutSize;
    UIEdgeInsets _minimumTextInset;
    UIEdgeInsets _currentTextInset;
    UIKeyboardType keyboardType;
    UITextGranularity tapSelectionGranularity;
    BOOL _autoCorrectDoubleSpaceToPeriodAtSentenceEnd;
    UITextAutocorrectionType _autocorrectionType;
    UITextAutocapitalizationType _autocapitalizationType;

    /* The cached typeset frame. */
    /* Note that 'immutableContent' contains an additional trailing newline which we hide from people who read/write our attributedText property */
    NSAttributedString *immutableContent;
    CTFramesetterRef framesetter;
    CTFrameRef drawnFrame;
    CGSize _usedSize;
    CGPoint layoutOrigin; // The location in rendering coordinates of the origin of the text layout coordinate system
    CGFloat _firstLineCenterTarget;
    
    // These are the regions of our view which are affected by the current selection or marked range
    CGRect selectionDirtyRect, markedTextDirtyRect;
    
    struct {
        // Our current state
        unsigned textNeedsUpdate:1;
        unsigned solidCaret:1;
        unsigned showingEditMenu:1;
        
        // Cached information about our OUIEditableFrameDelegate
        unsigned delegateRespondsToLayoutChanged:1;
        unsigned delegateRespondsToContentsChanged:1;
        unsigned delegateRespondsToCanShowContextMenu:1;
        unsigned delegateRespondsToShouldInsertText:1;
        unsigned delegateRespondsToShouldDeleteBackwardsFromIndex:1;
        unsigned delegateRespondsToSelectionChanged:1;
        
        // Features which can be enabled or disabled
        unsigned showSelectionThumbs:1;  // Effectively disables range selection
        unsigned showsInspector:1;       // Whether the inspector is offered
        unsigned shouldTryToCenterFirstLine:1; // Whether to attempt to center the first line at _firstLineCenterTarget

        unsigned isEditing:1; // We allow being 'editing' while not first responder.
        
        // Information about our content
        unsigned immutableContentHasAttributeTransforms:1;     // False if our -attributedText isn't a simple subrange of immutableContent
        unsigned mayHaveBackgroundRanges:1;                    // True unless we know we don't have any ... .
    } flags;
    
    // Range selection adjustment and display
    OUITextThumb *startThumb, *endThumb;
    OUITextCursorOverlay *_cursorOverlay;
    unsigned short _caretSolidity;
    NSTimer *_solidityTimer;
    OUILoupeOverlay *_loupe;
    OUIInspector *_textInspector; // TODO: This probably shouldn't live on the editor.
    
    UIMenuController *_selectionContextMenu;
    
    /* Gesture recognizers: we hold on to these so we can enable and disable them when we gain/lose first responder status */
    UIGestureRecognizer *focusRecognizer;
#define EF_NUM_ACTION_RECOGNIZERS 4
    UIGestureRecognizer *actionRecognizers[EF_NUM_ACTION_RECOGNIZERS];
    
    /* A system-provided input delegate is assigned when the system is interested in input changes. */
    id <UITextInputDelegate> inputDelegate;
    UITextInputStringTokenizer *tokenizer;
  
    UIView *inputAccessoryView;
    UIView *backingView_;
}

@property (nonatomic, readwrite, retain) UIView *inputAccessoryView;
@property (nonatomic, retain) UIView *backingView;

+ (Class)textStorageClass; // Controls the class used to create the built-in text storage

@property (nonatomic, retain) OATextStorage *textStorage; // Set this if you want have your text storage directly edited. Otherwise, you can use 'attributedText' to replace the contents of the built-in text storage.

@property (nonatomic, readwrite, retain) UIColor *selectionColor;
@property (nonatomic, copy) NSDictionary *typingAttributes;
@property (nonatomic, copy) NSAttributedString *attributedText;
@property (nonatomic, assign) id <OUIEditableFrameDelegate> delegate;

@property (nonatomic, copy) OUITextLayoutSpanBackgroundFilter backgroundSpanFilter;

@property (nonatomic, assign) UIEdgeInsets textInset; // In text space (so it scales up too).
@property (nonatomic) CGSize textLayoutSize; // In text space, not UIView coordinates.
@property (nonatomic, readonly) CGSize textUsedSize; // In text space. textInset is added to this.
@property (nonatomic, readonly) CGSize viewUsedSize; // Same as -textUsedSpace, but accounting for effective scale to UIView space.
@property (nonatomic, assign) BOOL shouldTryToCenterFirstLine;
@property (nonatomic, assign) CGFloat firstLineCenterTarget;

- (BOOL)endEditing;

@property (nonatomic, readwrite, retain) UIColor *textColor;                   /* Applied to any runs lacking kCTForegroundColorAttributeName */
@property (nonatomic, readwrite) CTFontRef defaultCTFont;                      /* Applied to any runs lacking kCTFontAttributeName */
@property (nonatomic, readwrite) CTParagraphStyleRef defaultCTParagraphStyle;  /* Applied to any runs lacking kCTParagraphStyleAttributeName */

@property (nonatomic, copy) NSDictionary *linkTextAttributes;

@property (nonatomic) BOOL autoCorrectDoubleSpaceToPeriodAtSentenceEnd;
@property (nonatomic) UITextAutocorrectionType autocorrectionType;  // defaults to UITextAutocorrectionTypeNo
@property (nonatomic) UITextAutocapitalizationType autocapitalizationType; // defaults to UITextAutocapitalizationTypeNone
@property (nonatomic) UITextGranularity tapSelectionGranularity;
@property (nonatomic, readwrite) BOOL showingEditMenu;

- (void)setupCustomMenuItemsForMenuController:(UIMenuController *)menuController;

- (OUEFTextRange *)rangeOfLineContainingPosition:(OUEFTextPosition *)posn;
- (UITextRange *)selectionRangeForPoint:(CGPoint)p granularity:(UITextGranularity)granularity;
- (UITextRange *)selectionRangeForPoint:(CGPoint)p wordSelection:(BOOL)selectWords;
- (UITextPosition *)tappedPositionForPoint:(CGPoint)point;
- (id)attribute:(NSString *)attributeName atPosition:(UITextPosition *)position effectiveRange:(UITextRange **)outRange;

- (CGRect)boundsOfRange:(UITextRange *)range; // May return CGRectZero

/* These are the interface from the thumbs to our selection machinery */
- (void)thumbBegan:(OUITextThumb *)thumb;
- (void)thumbMoved:(OUITextThumb *)thumb targetPosition:(CGPoint)pt;
- (void)thumbEnded:(OUITextThumb *)thumb normally:(BOOL)normalEnd;

/* These are the interface from the inspectable spans */
- (NSDictionary *)attributesInRange:(UITextRange *)r;
- (id <NSObject>)attribute:(NSString *)attr inRange:(UITextRange *)r;
- (void)setValue:(id)value forAttribute:(NSString *)attr inRange:(UITextRange *)r;

- (BOOL)hasTouchesForEvent:(UIEvent *)event;
- (BOOL)hasTouchByGestureRecognizer:(UIGestureRecognizer *)recognizer;

// Controls whether the text style inspector is offered in the selection context menu. Not recommended since adjusting the text attributes can change text layout and make the position of inspector look bad.
@property(nonatomic,assign) BOOL showsInspector OB_DEPRECATED_ATTRIBUTE;

- (NSArray *)inspectableTextSpans;    // returns set of OUEFTextSpans 
- (void)inspectSelectedTextFromBarButtonItem:(UIBarButtonItem *)barButtonItem;

- (NSRange)characterRangeForTextRange:(UITextRange *)textRange;

// Optional OUIInspectorDelegate methods that we implement (so subclasses can call super)
- (NSArray *)inspector:(OUIInspector *)inspector makeAvailableSlicesForStackedSlicesPane:(OUIStackedSlicesInspectorPane *)pane;
- (void)inspectorDidDismiss:(OUIInspector *)inspector;


@property (nonatomic, readwrite, retain) UIColor *markedRangeBorderColor;
@property (nonatomic, readwrite, retain) UIColor *markedRangeBackgroundColor;
@property (nonatomic, readwrite, assign) CGFloat markedRangeBorderThickness;

@end

