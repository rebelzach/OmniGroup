// Copyright 2009-2010 The Omni Group. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <QuartzCore/CAAnimation.h>

@interface OQFlipSwapViewAnimation : CABasicAnimation
{
@private
    CALayer *_targetLayer;
    NSWindow *_window;
}

+ (void)replaceView:(NSView *)oldView withView:(NSView *)newView setFirstResponder:(NSResponder *)newFirstResponder;

@end
