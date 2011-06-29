// Copyright 1997-2006, 2008, 2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <AppKit/NSWindow.h>

#import <Foundation/NSGeometry.h> // for NSPoint
#import <Foundation/NSDate.h> // for NSTimeInterval

#import <OmniBase/OBUtilities.h>

@interface NSWindow (OAExtensions)

+ (NSArray *)windowsInZOrder;

- (NSPoint)frameTopLeftPoint;

- (BOOL)isBecomingKey;
- (BOOL)shouldDrawAsKey;

- (void)addConstructionWarning;

- (CGPoint)convertBaseToCGScreen:(NSPoint)windowPoint;

@end
