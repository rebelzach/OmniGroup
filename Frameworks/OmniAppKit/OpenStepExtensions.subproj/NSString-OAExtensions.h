// Copyright 1997-2005, 2007-2008, 2010-2011 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <Foundation/NSString.h>

#import <Carbon/Carbon.h> // For ThemeFontID, TruncCode
#import <Foundation/NSGeometry.h> // For NSRect

@class NSColor, NSFont, NSImage, NSTableColumn, NSTableView;

@interface NSString (OAExtensions)

+ (NSString *)stringForKeyEquivalent:(NSString *)equivalent andModifierMask:(NSUInteger)mask;
// Used for displaying a file size in a tableview, which automatically abbreviates when the column gets too narrow.
//+ (NSString *)possiblyAbbreviatedStringForBytes:(unsigned long long)bytes inTableView:(NSTableView *)tableView tableColumn:(NSTableColumn *)tableColumn;

// String drawing
- (void)drawWithFontAttributes:(NSDictionary *)attributes alignment:(int)alignment verticallyCenter:(BOOL)verticallyCenter inRectangle:(NSRect)rectangle;
- (void)drawWithFont:(NSFont *)font color:(NSColor *)color alignment:(int)alignment verticallyCenter:(BOOL)verticallyCenter inRectangle:(NSRect)rectangle;
- (void)drawWithFontAttributes:(NSDictionary *)attributes alignment:(int)alignment rectangle:(NSRect)rectangle;
- (void)drawWithFont:(NSFont *)font color:(NSColor *)color alignment:(int)alignment rectangle:(NSRect)rectangle;

@end
