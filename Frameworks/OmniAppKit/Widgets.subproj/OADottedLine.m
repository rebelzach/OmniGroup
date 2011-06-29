// Copyright 2001-2005,2008, 2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OADottedLine.h"

#import <Cocoa/Cocoa.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Id$");

@implementation OADottedLine

- (void)drawRect:(NSRect)rect {
    NSBezierPath *dottedLinePath;
    const CGFloat lineDash[2] = {1.0f, 2.0f};

    [[NSColor grayColor] set];
    dottedLinePath = [NSBezierPath bezierPath];
    if ([self bounds].size.width <= [self bounds].size.height) {
        [dottedLinePath moveToPoint:NSMakePoint(NSMinX(_bounds) + 0.5f, NSMinY(_bounds) + 3.0f)];
        [dottedLinePath lineToPoint:NSMakePoint(NSMinX(_bounds) + 0.5f, NSMaxY(_bounds) - 3.0f)];
    } else {
        [dottedLinePath moveToPoint:NSMakePoint(NSMinX(_bounds) + 3.0f, NSMinY(_bounds) + 0.5f)];
        [dottedLinePath lineToPoint:NSMakePoint(NSMaxX(_bounds) - 3.0f, NSMinY(_bounds) + 0.5f)];
    }
    [dottedLinePath setLineWidth:1.0f];
    [dottedLinePath setLineDash:lineDash count:2 phase:0];
    [dottedLinePath stroke];
}

@end
