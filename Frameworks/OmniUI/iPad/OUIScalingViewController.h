// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <UIKit/UIViewController.h>

@class OUIScalingScrollView;
@protocol UIScrollViewDelegate;

@interface OUIScalingViewController : UIViewController <UIScrollViewDelegate>
{
@private
    OUIScalingScrollView *_scrollView;
    BOOL _isZooming;
}

@property(nonatomic,retain) IBOutlet UIScrollView *scrollView;

// UIScrollViewDelegate methods that we implement, so subclasses can know whether to call super
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view;
- (void)scrollViewDidZoom:(UIScrollView *)scrollView;
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale;

// Mostly internal methods. Need to work more on a good public subclass API for this class
- (void)adjustScaleBy:(CGFloat)scale;
- (void)adjustScaleTo:(CGFloat)effectiveScale;
- (CGFloat)fullScreenScale;
- (void)adjustContentInset;
- (void)sizeInitialViewSizeFromCanvasSize;

// Subclasses
@property(readonly,nonatomic) CGSize canvasSize; // Return CGSizeZero if you don't know yet (and then make sure you call -sizeInitialViewSizeFromCanvasSize when you can answer)

@end
