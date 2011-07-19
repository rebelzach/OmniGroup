// Copyright 2010-2011 The Omni Group. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniUI/OUIInspectorSegmentedControlButton.h>

#import <OmniUI/OUIDrawing.h>
#import <OmniBase/OmniBase.h>
#import <UIKit/UIImage.h>
#import <OmniUI/OUIInspector.h>

#import "OUIParameters.h"

RCS_ID("$Id$");

@interface OUIInspectorSegmentedControlButton (/*Private*/)
- (void)_updateBackgroundImages;
@end

@implementation OUIInspectorSegmentedControlButton

typedef struct {
    UIImage *normal;
    UIImage *selected;
} ImageInfo;

static ImageInfo BackgroundImages[3]; // One for each of OUIInspectorSegmentedControlButtonPosition
static ImageInfo DarkBackgroundImages[3];

static UIImage *_loadImage(NSString *imageName)
{
    UIImage *image = [UIImage imageNamed:imageName];
    OBASSERT(image);
    
    // These images should all be stretchable. The caps have to be the same width. The one uncapped px is used for stretching.
    const CGFloat capWidth = 6;
    OBASSERT(image.size.width == capWidth * 2 + 1);
    
    return [image stretchableImageWithLeftCapWidth:capWidth topCapHeight:0];
}

static void _loadImages(ImageInfo *info, NSString *normalName, NSString *selectedName)
{
    info->normal = [_loadImage(normalName) retain];
    OBASSERT(info->normal);
    
    info->selected = [_loadImage(selectedName) retain];
    OBASSERT(info->selected);
}

+ (void)initialize;
{
    OBINITIALIZE;
    
    _loadImages(&BackgroundImages[OUIInspectorSegmentedControlButtonPositionLeft], @"OUISegmentLeftEndNormal.png", @"OUISegmentLeftEndSelected.png");
    _loadImages(&BackgroundImages[OUIInspectorSegmentedControlButtonPositionRight], @"OUISegmentRightEndNormal.png", @"OUISegmentRightEndSelected.png");
    _loadImages(&BackgroundImages[OUIInspectorSegmentedControlButtonPositionCenter], @"OUISegmentMiddleNormal.png", @"OUISegmentMiddleSelected.png");
    
    _loadImages(&DarkBackgroundImages[OUIInspectorSegmentedControlButtonPositionLeft], @"OUIDarkSegmentLeftEndNormal.png", @"OUIDarkSegmentLeftEndSelected.png");
    _loadImages(&DarkBackgroundImages[OUIInspectorSegmentedControlButtonPositionRight], @"OUIDarkSegmentRightEndNormal.png", @"OUIDarkSegmentRightEndSelected.png");
    _loadImages(&DarkBackgroundImages[OUIInspectorSegmentedControlButtonPositionCenter], @"OUIDarkSegmentMiddleNormal.png", @"OUIDarkSegmentMiddleSelected.png");
}

static id _commonInit(OUIInspectorSegmentedControlButton *self)
{
    [self setTitleColor:[OUIInspector labelTextColor] forState:UIControlStateNormal];
    [self setTitleColor:[OUIInspector disabledLabelTextColor] forState:UIControlStateDisabled];
    [self setTitleShadowColor:OUIShadowColor(OUIShadowTypeDarkContentOnLightBackground) forState:UIControlStateNormal];
    self.titleLabel.shadowOffset = OUIShadowOffset(OUIShadowTypeDarkContentOnLightBackground);
    
    [self _updateBackgroundImages];
    return self;
}

- initWithFrame:(CGRect)frame;
{
    if (!(self = [super initWithFrame:frame]))
        return nil;
    return _commonInit(self);
}

- initWithCoder:(NSCoder *)coder;
{
    if (!(self = [super initWithCoder:coder]))
        return nil;
    return _commonInit(self);
}

- (void)dealloc;
{
    [_image release];
    [_representedObject release];
    [super dealloc];
}

@synthesize buttonPosition = _buttonPosition;
- (void)setButtonPosition:(OUIInspectorSegmentedControlButtonPosition)buttonPosition;
{
    OBASSERT_NONNEGATIVE(buttonPosition);
    OBPRECONDITION(buttonPosition < _OUIInspectorSegmentedControlButtonPositionCount);
    if (buttonPosition >= _OUIInspectorSegmentedControlButtonPositionCount)
        buttonPosition = OUIInspectorSegmentedControlButtonPositionCenter;

    if (_buttonPosition == buttonPosition)
        return;
    _buttonPosition = buttonPosition;
    [self _updateBackgroundImages];
}

@synthesize image = _image;
- (void)setImage:(UIImage *)image;
{
    if (_image == image)
        return;
    [_image release];
    _image = [image retain];
    
    if ([self dark])
        [self setImage:(image ? OUIMakeShadowedImage(image, OUIShadowTypeLightContentOnDarkBackground) : nil) forState:UIControlStateNormal];
    else
        [self setImage:(image ? OUIMakeShadowedImage(image, OUIShadowTypeDarkContentOnLightBackground) : nil) forState:UIControlStateNormal];
}

@synthesize representedObject = _representedObject;

- (void)addTarget:(id)target action:(SEL)action;
{
    [super addTarget:target action:action forControlEvents:UIControlEventTouchDown];
}

@synthesize dark = _dark;

- (void)setDark:(BOOL)flag;
{
    _dark = flag;
    [self _updateBackgroundImages];
}

#pragma mark -
#pragma mark Private

- (void)_updateBackgroundImages;
{
    OUIInspectorSegmentedControlButtonPosition buttonPosition = _buttonPosition;
    OBASSERT_NONNEGATIVE(buttonPosition);
    OBASSERT(buttonPosition < _OUIInspectorSegmentedControlButtonPositionCount);
    if (buttonPosition >= _OUIInspectorSegmentedControlButtonPositionCount)
        buttonPosition = OUIInspectorSegmentedControlButtonPositionCenter;
    
    ImageInfo *backgroundImages = (_dark) ? &DarkBackgroundImages[buttonPosition] : &BackgroundImages[buttonPosition];
    [self setBackgroundImage:backgroundImages->normal forState:UIControlStateNormal];
    [self setBackgroundImage:backgroundImages->selected forState:UIControlStateSelected];
}

@end
