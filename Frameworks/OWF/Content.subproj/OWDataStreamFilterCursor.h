// Copyright 2003-2005, 2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <OWF/OWDataStreamCursor.h>

@class NSMutableData;

@interface OWDataStreamFilterCursor : OWDataStreamCursor
{
    NSMutableData *bufferedData;
    NSUInteger bufferedDataStart, bufferedDataValidLength;
    BOOL canFillMoreBuffer, haveStartedFilter;
}

// API

// Subclass' responsibility.
- (void)processBegin;
- (void)fillBuffer:(void *)buffer length:(unsigned)bufferLength filledToIndex:(unsigned *)bufferFullp;

// A concrete subclass of OWDataStreamFilterCursor must provide implementations for the following methods:
//    -fillBuffer:length:filledToIndex:
//    -underlyingDataStream
//    -scheduleInQueue:invocation:
//
// In addition, it might want to extend -processBegin to perform its own setup.

OWF_EXTERN NSString *OWDataStreamCursor_SeekExceptionName;

@end
