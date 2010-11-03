// Copyright 2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OACloseButtonOverlay.h"
#import "NSWindowController-OAExtensions.h"

RCS_ID("$Id$");

@implementation OACloseButtonOverlay

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
{
    return YES;
}

- (void)drawRect:(NSRect)rect;
{
    NSWindow *window = [self window];
    NSWindowController *windowController = [window windowController];
    if (![windowController conformsToProtocol:@protocol(OAMetadataTracking)])
        return;
    
    if ([(id <OAMetadataTracking>)windowController hasUnsavedMetadata] && ![window isDocumentEdited]) {
        [[NSColor colorWithCalibratedWhite:0.0f alpha:[window isKeyWindow] ? 0.6f : 0.3f] set];
        
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMidX(_bounds), NSMidY(_bounds) + 1.0f) radius:2.5f startAngle:0.0f endAngle:360.0f clockwise:NO];
        [path setLineWidth:1.5f];
        [path stroke];
    }
}

@end
