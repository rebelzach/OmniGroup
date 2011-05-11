// Copyright 2010-2011 The Omni Group. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OUIRGBColorPicker.h"

#import <OmniUI/OUIColorComponentSlider.h>
#import <OmniQuartz/OQColor.h>

RCS_ID("$Id$");

@implementation OUIRGBColorPicker

#pragma mark -
#pragma mark OUIComponentColorPicker

- (NSString *)identifier;
{
    return @"rgb";
}

- (OQColorSpace)colorSpace;
{
    return OQColorSpaceRGB;
}

- (NSArray *)makeComponentSliders;
{
    NSMutableArray *sliders = [NSMutableArray array];
    
    OUIColorComponentSlider *red = [OUIColorComponentSlider slider];
    red.range = 255;
    red.formatString = NSLocalizedStringWithDefaultValue(@"<red title+value>", @"OUIInspectors", OMNI_BUNDLE, @"Red: %d", @"title format for color component slider");
    [sliders addObject:red];
    
    OUIColorComponentSlider *green = [OUIColorComponentSlider slider];
    green.range = 255;
    green.formatString = NSLocalizedStringWithDefaultValue(@"<green title+value>", @"OUIInspectors", OMNI_BUNDLE, @"Green: %d", @"title format for color component slider");
    [sliders addObject:green];
    
    OUIColorComponentSlider *blue = [OUIColorComponentSlider slider];
    blue.range = 255;
    blue.formatString = NSLocalizedStringWithDefaultValue(@"<blue title+value>", @"OUIInspectors", OMNI_BUNDLE, @"Blue: %d", @"title format for color component slider");
    [sliders addObject:blue];
    
    OUIColorComponentSlider *alpha = [OUIColorComponentSlider slider];
    alpha.range = 100;
    alpha.formatString = NSLocalizedStringWithDefaultValue(@"<alpha title+value>", @"OUIInspectors", OMNI_BUNDLE, @"Opacity: %d%%", @"title format for color component slider");
    alpha.representsAlpha = YES;
    [sliders addObject:alpha];
    
    return sliders;
}

- (void)extractComponents:(CGFloat *)components fromColor:(OQColor *)color;
{
    OQLinearRGBA rgba = [color toRGBA];
    components[0] = rgba.r;
    components[1] = rgba.g;
    components[2] = rgba.b;
    components[3] = rgba.a;
}

- (OQColor *)makeColorWithComponents:(const CGFloat *)components;
{
    return [OQColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:components[3]];
}

static OQLinearRGBA _convertRGBAToRGBA(const CGFloat *input)
{
    OQLinearRGBA rgba;
    rgba.r = input[0];
    rgba.g = input[1];
    rgba.b = input[2];
    rgba.a = input[3];
    return rgba;
}

- (OUIComponentColorPickerConvertToRGB)rgbaComponentConverter;
{
    return _convertRGBAToRGBA;
}

@end
