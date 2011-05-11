// Copyright 2010-2011 The Omni Group. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <CoreGraphics/CoreGraphics.h>

@class UIImage, UILabel;

extern UIImage *OUIImageByFlippingHorizontally(UIImage *image);

#ifdef DEBUG
extern void OUILogAncestorViews(UIView *view);
#endif

// Convenience for UIGraphicsBegin/EndImageContext for resolution independent drawing
extern void OUIGraphicsBeginImageContext(CGSize size);
extern void OUIGraphicsEndImageContext(void); 

// For segmented contorls, stepper buttons, etc.

typedef enum {
    OUIShadowTypeLightContentOnDarkBackground,
    OUIShadowTypeDarkContentOnLightBackground,
} OUIShadowType;

extern CGSize OUIShadowOffset(OUIShadowType type);
extern UIColor *OUIShadowColor(OUIShadowType type);

extern CGRect OUIShadowContentRectForRect(CGRect rect, OUIShadowType type);

extern void OUIBeginShadowing(CGContextRef ctx, OUIShadowType type);
extern void OUIBeginControlImageShadow(CGContextRef ctx, OUIShadowType type);
extern void OUIEndControlImageShadow(CGContextRef ctx);
extern UIImage *OUIMakeShadowedImage(UIImage *image, OUIShadowType type);

extern void OUISetShadowOnLabel(UILabel *label, OUIShadowType type);

extern void OUIDrawTransparentColorBackground(CGContextRef ctx, CGRect rect, CGSize phase);
extern void OUIDrawPatternBackground(CGContextRef ctx, NSString *imageName, CGRect rect, CGSize phase);
