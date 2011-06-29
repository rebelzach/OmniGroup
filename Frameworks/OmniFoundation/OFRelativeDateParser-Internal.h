// Copyright 2006-2008, 2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <OmniFoundation/OFRelativeDateParser.h>

// used by tests
typedef struct {
    NSUInteger day;
    NSUInteger month;
    NSUInteger year;
    NSString *separator;
} DatePosition;

typedef struct {
    NSInteger day;
    NSInteger month;
    NSInteger year;
} DateSet;

@interface OFRelativeDateParser (OFInternalAPI)
- (DatePosition)_dateElementOrderFromFormat:(NSString *)dateFormat;
@end
