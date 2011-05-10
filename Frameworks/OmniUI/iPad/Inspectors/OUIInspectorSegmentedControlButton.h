// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <UIKit/UIButton.h>

typedef enum {
    OUIInspectorSegmentedControlButtonPositionLeft,
    OUIInspectorSegmentedControlButtonPositionCenter,
    OUIInspectorSegmentedControlButtonPositionRight,
    _OUIInspectorSegmentedControlButtonPositionCount
} OUIInspectorSegmentedControlButtonPosition;

@interface OUIInspectorSegmentedControlButton : UIButton
{
@private
    OUIInspectorSegmentedControlButtonPosition _buttonPosition;
    UIImage *_image;
    id _representedObject;
}

@property(assign,nonatomic) OUIInspectorSegmentedControlButtonPosition buttonPosition;
@property(retain,nonatomic) UIImage *image;
@property(retain,nonatomic) id representedObject;

- (void)addTarget:(id)target action:(SEL)action; // Convenience; sends action on touch-down.

@end
