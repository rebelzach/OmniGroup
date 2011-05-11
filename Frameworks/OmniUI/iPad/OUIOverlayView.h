// Copyright 2010-2011 The Omni Group. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <UIKit/UIView.h>

typedef enum {
    OUIOverlayViewAlignmentUpCenter = 0,
    OUIOverlayViewAlignmentMidCenter = 1,
    OUIOverlayViewAlignmentDownCenter = 2,
} OUIOverlayViewAlignment;

#define OUIOverlayViewDistanceFromTopEdge 10
#define OUIOverlayViewDistanceFromHorizontalEdge 10

#define OUIOverlayViewPerpendicularDistanceFromTwoTouches 100

@class OUITextLayout;
@interface OUIOverlayView : UIView
{
@private
    NSString *_text;
    NSAttributedString *_attributedText;
    UIImage *_image;
    CGSize _borderSize;
    NSTimeInterval _messageDisplayInterval;
    
    NSTimer *_overlayTimer;
    CGSize _cachedSuggestedSize;
    
    BOOL shouldHide;
    
    OUITextLayout *_textLayout;
}

// Convenience methods for creating temporary overlays.  Pass 0 as the displayInterval to use the default delay.
+ (OUIOverlayView *)sharedTemporaryOverlay;
+ (void)displayTemporaryOverlayInView:(UIView *)view withString:(NSString *)string avoidingTouchPoint:(CGPoint)touchPoint;
+ (void)displayTemporaryOverlayInView:(UIView *)view withString:(NSString *)string centeredAtPoint:(CGPoint)touchPoint displayInterval:(NSTimeInterval)displayInterval;
+ (void)displayTemporaryOverlayInView:(UIView *)view withString:(NSString *)string centeredAbovePoint:(CGPoint)touchPoint displayInterval:(NSTimeInterval)displayInterval;
+ (void)displayTemporaryOverlayInView:(UIView *)view withString:(NSString *)string positionedForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer displayInterval:(NSTimeInterval)displayInterval;
+ (void)displayTemporaryOverlayInView:(UIView *)view withString:(NSString *)string alignment:(OUIOverlayViewAlignment)alignment displayInterval:(NSTimeInterval)displayInterval;

- (void)displayTemporarilyInView:(UIView *)view;
- (void)displayInView:(UIView *)view;
- (void)hide;
- (void)hideAnimated:(BOOL)animated;

- (CGSize)suggestedSize;
- (void)useSuggestedSize;

- (void)resetDefaults;

@property(assign,nonatomic) NSString *text;     // not retained - sets up NSAttributedString with default font and color
@property(retain,nonatomic) NSAttributedString *attributedText;
@property(retain,nonatomic) UIImage *image;
@property(assign,nonatomic) CGSize borderSize;
@property(assign,nonatomic) NSTimeInterval messageDisplayInterval;  // seconds
@property(readonly, nonatomic) BOOL isVisible;

- (void)avoidTouchPoint:(CGPoint)touchPoint withinBounds:(CGRect)superBounds;
- (void)centerAtPoint:(CGPoint)touchPoint withOffset:(CGPoint)offset withinBounds:(CGRect)superBounds;
- (void)centerAbovePoint:(CGPoint)touchPoint withinBounds:(CGRect)superBounds;
- (void)useAlignment:(OUIOverlayViewAlignment)alignment withinBounds:(CGRect)superBounds;

- (void)centerAtPositionForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer inView:(UIView *)view;

@end
