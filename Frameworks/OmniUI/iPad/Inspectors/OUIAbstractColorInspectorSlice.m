// Copyright 2010-2011 The Omni Group. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniUI/OUIAbstractColorInspectorSlice.h>

#import <OmniUI/OUIColorInspectorPane.h>
#import <OmniUI/OUIInspector.h>
#import <OmniUI/OUIInspectorSelectionValue.h>
#import <OmniUI/OUIStackedSlicesInspectorPane.h>
#import <OmniQuartz/OQColor.h>

RCS_ID("$Id$");

@implementation OUIAbstractColorInspectorSlice

- (void)dealloc;
{
    [_selectionValue release];
    [_defaultColor release];
    [super dealloc];
}

- (OQColor *)colorForObject:(id)object;
{
    OBRequestConcreteImplementation(self, _cmd);
    return nil;
}

- (void)setColor:(OQColor *)color forObject:(id)object;
{
    OBRequestConcreteImplementation(self, _cmd);
}

#pragma mark -
#pragma mark OUIInspectorSlice subclass

- (IBAction)showDetails:(id)sender;
{    
    if (!self.detailPane) {
        OUIColorInspectorPane *pane = [[OUIColorInspectorPane alloc] init];
        pane.title = self.title;
        self.detailPane = pane;
        [pane release];
    }
    
    [super showDetails:sender];
}

- (void)updateInterfaceFromInspectedObjects:(OUIInspectorUpdateReason)reason;
{
    NSMutableArray *colors = [NSMutableArray array];
    
    // Find a single color, obeying color spaces, that all the objects have.
#ifdef NS_BLOCKS_AVAILABLE
    [self eachAppropriateObjectForInspection:^(id object){
        OQColor *objectColor = [self colorForObject:object];
        if (objectColor)
            [colors addObject:objectColor];
    }];
#else
    OBFinishPortingLater("Make the trunk 4.x only");
    NSArray *appropriateObjects = self.appropriateObjectsForInspection;
    for (id object in appropriateObjects) {
        OQColor *objectColor = [self colorForObject:object];
        if (objectColor)
            [colors addObject:objectColor];
    }
#endif
    
    OUIInspectorSelectionValue *selectionValue = [[OUIInspectorSelectionValue alloc] initWithValues:colors];
    
    // Compare the two colors in RGBA space, but keep the old single color's color space. This allow us to map to RGBA for text (where we store the RGBA in a CGColorRef for CoreText's benefit) but not lose the color space in our color picking UI, mapping all HSV colors with S or V of zero to black or white (and losing the H component).  See <bug://bugs/59912> (Hue slider jumps around)
    if (OFNOTEQUAL([selectionValue.firstValue colorUsingColorSpace:OQColorSpaceRGB], [_selectionValue.firstValue colorUsingColorSpace:OQColorSpaceRGB])) {
        [_selectionValue release];
        _selectionValue = selectionValue; // take reference from above
    } else
        [selectionValue release];
    
    // Don't check off swatches as selected unless there is only one color selected. Otherwise, we could have the main swatch list have one checkmark when there is really another selected color that just isn't in the list being shown.
    
    [super updateInterfaceFromInspectedObjects:reason];
}

#pragma mark -
#pragma mark OUIColorInspectorPaneParentSlice

@synthesize allowsNone = _allowsNone;
@synthesize defaultColor = _defaultColor;

@synthesize selectionValue = _selectionValue;

- (void)changeColor:(id)sender;
{
    OBPRECONDITION([sender conformsToProtocol:@protocol(OUIColorValue)]);
    id <OUIColorValue> colorValue = sender;
    
    OQColor *color = colorValue.color;
    
    //NSLog(@"setting color %@, continuous %d", [colorValue.color shortDescription], colorValue.isContinuousColorChange);
    
    BOOL isContinuousChange = colorValue.isContinuousColorChange;
    
    OUIInspector *inspector = self.inspector;
    NSArray *appropriateObjects = self.appropriateObjectsForInspection;
    
    if (isContinuousChange && !_inContinuousChange) {
        //NSLog(@"will begin");
        _inContinuousChange = YES;
        [inspector willBeginChangingInspectedObjects];
    }
    
    [inspector beginChangeGroup];
    {
        for (id object in appropriateObjects)
            [self setColor:color forObject:object];
    }
    [inspector endChangeGroup];
    
    // Pre-populate our selected color before querying back from the objects. This will allow us to keep the original colorspace if the colors are equivalent enough.
    // Do this before calling -updateInterfaceFromInspectedObjects: or -didEndChangingInspectedObjects (which will also update the interface) since that'll read the current selectionValue.
    [_selectionValue release];
    _selectionValue = [[OUIInspectorSelectionValue alloc] initWithValue:color];
    
    if (!isContinuousChange) {
        //NSLog(@"will end");
        _inContinuousChange = NO;
        [inspector didEndChangingInspectedObjects];
    } else if (inspector.topVisiblePane == self.containingPane) {
        // -didEndChangingInspectedObjects will update the interface for us
        // Only need to update if we are the visible inspector (not our detail). Otherwise we'll update when the detail closes.
        [self updateInterfaceFromInspectedObjects:OUIInspectorUpdateReasonObjectsEdited];
    }
}

@end

