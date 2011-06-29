// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <OmniFoundation/OFObject.h>

@class NSArray, NSDictionary, NSString;

@interface OUIPaletteTheme : OFObject
{
@private
    NSString *_identifier;
    NSString *_displayName;
    NSArray *_colors;
}

+ (NSArray *)defaultThemes;

- initWithDictionary:(NSDictionary *)dict stringTable:(NSString *)stringTable bundle:(NSBundle *)bundle;

@property(readonly) NSString *identifier;
@property(readonly) NSString *displayName;
@property(readonly) NSArray *colors;

@end
