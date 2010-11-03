// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <OWF/OWDataStreamProcessor.h>

@class OWDataStream;

@interface OWMultipartDataStreamProcessor : OWDataStreamProcessor
{
    unsigned char *delimiter;
    unsigned int delimiterLength, inputBufferSize;
    unsigned int delimiterSkipTable[256];
}

// This method is overridden by concrete subclasses
- (void)processDataStreamPart:(OWDataStream *)aDataStream headers:(OWHeaderDictionary *)partHeaders;

@end
