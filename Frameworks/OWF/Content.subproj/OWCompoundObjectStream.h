// Copyright 1999-2005, 2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <OWF/OWAbstractObjectStream.h>

@class OWObjectStreamCursor;

@interface OWCompoundObjectStream : OWAbstractObjectStream
{
    OWAbstractObjectStream *framingStream;
    OWAbstractObjectStream *interjectedStream;

    unsigned int interjectedAtIndex;
}

/* a convenience method */
+ (OWObjectStreamCursor *)cursorAtCursor:(OWObjectStreamCursor *)aCursor beforeStream:(OWAbstractObjectStream *)interjectMe;

/* designated initializer */
- initWithStream:(OWAbstractObjectStream *)aStream interjectingStream:(OWAbstractObjectStream *)anotherStream atIndex:(unsigned int)index;

/* raises an exception if aStream is not a (possibly indirect) member of this compound object stream */
- (NSUInteger)translateIndex:(NSUInteger)index fromStream:(OWAbstractObjectStream *)aStream;

@end
