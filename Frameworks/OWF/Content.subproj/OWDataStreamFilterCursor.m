// Copyright 2003-2005, 2010-2011 Omni Development, Inc. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OWDataStreamFilterCursor.h"

#import <Foundation/Foundation.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OFInvocation.h>
#import <OmniFoundation/OFMessageQueue.h>
#import "OWProcessor.h"

RCS_ID("$Id$");

@interface OWDataStreamFilterCursor (Private)
@end

@implementation OWDataStreamFilterCursor

// Init and dealloc

static NSException *OWDataStreamCursor_SeekException;

+ (void)initialize;
{
    OBINITIALIZE;

    OWDataStreamCursor_SeekException = [[NSException alloc] initWithName:OWDataStreamCursor_SeekExceptionName reason:OWDataStreamCursor_SeekExceptionName userInfo:nil];
}

- init;
{
    if (!(self = [super init]))
        return nil;

    haveStartedFilter = NO;
    canFillMoreBuffer = YES;

    return self;
}

- (void)dealloc;
{
    [bufferedData release];
    [super dealloc];
}


// API

- (void)processBegin
{
    OBPRECONDITION(!haveStartedFilter);

    haveStartedFilter = YES;
    bufferedData = [[NSMutableData allocWithZone:[self zone]] init];
    bufferedDataStart = 0;
    bufferedDataValidLength = 0;

    OBPOSTCONDITION(haveStartedFilter);
}

- (void)_processBegin
{
    if (abortException)
        [abortException raise];

    NS_DURING {
        OBPRECONDITION(!haveStartedFilter);
        [self processBegin];
        OBPOSTCONDITION(haveStartedFilter);
    } NS_HANDLER {
        [self abortWithException:localException];
        [localException raise];
    } NS_ENDHANDLER;

}

- (BOOL)enlargeBuffer
{
    OBFinishPorting; // 64->32 warnings -- if we even keep this framework
    return NO;
#if 0
    unsigned int atLeast;
    unsigned int oldValidLength;

    if (!haveStartedFilter)
        [self processBegin];
    if (abortException)
        [abortException raise];

    if (!canFillMoreBuffer)
        return NO;

    atLeast = bufferedDataValidLength + 1024;
    if ([bufferedData length] < atLeast)
        [bufferedData setLength:atLeast];

    oldValidLength = bufferedDataValidLength;
    do {
        [self fillBuffer:nil length:[bufferedData length] filledToIndex:&bufferedDataValidLength];
    } while (canFillMoreBuffer && bufferedDataValidLength == oldValidLength);

    return (bufferedDataValidLength != oldValidLength);
#endif
}

- (void)bufferBytes:(NSUInteger)count
{
    OBFinishPorting; // 64->32 warnings -- if we even keep this framework
#if 0
    if (bufferedDataStart + bufferedDataValidLength >= dataOffset + count)
        return;

    if (!haveStartedFilter)
        [self processBegin];
    if (abortException)
        [abortException raise];

    if (dataOffset < bufferedDataStart)
        [OWDataStreamCursor_SeekException raise];

    if (bufferedDataStart + bufferedDataValidLength == dataOffset) {
        bufferedDataValidLength = 0;
        bufferedDataStart = dataOffset;
    } else if (dataOffset - bufferedDataStart > 2 * (bufferedDataStart + bufferedDataValidLength - dataOffset)) {
        // heuristic: if we have more than twice as much data behind the cursor than in front of it, copy it down to the front of the buffer
        void *buf = [bufferedData mutableBytes];
        memmove(buf, buf + (dataOffset - bufferedDataStart),
               bufferedDataStart + bufferedDataValidLength - dataOffset);
        bufferedDataValidLength -= (dataOffset - bufferedDataStart);
        bufferedDataStart = dataOffset;
    }
    
    if ([bufferedData length] < ( (dataOffset + count) - (bufferedDataStart + bufferedDataValidLength) ))
        [bufferedData setLength:( (dataOffset + count) - (bufferedDataStart + bufferedDataValidLength) )];

    while (bufferedDataStart + bufferedDataValidLength < dataOffset + count) {
        if (!canFillMoreBuffer)
            [OWDataStreamCursor_UnderflowException raise];
        [self fillBuffer:nil length:[bufferedData length] filledToIndex:&bufferedDataValidLength];
    }
#endif
}

- (BOOL)haveBufferedBytes:(unsigned int)count
{
    return (bufferedDataStart + bufferedDataValidLength >= dataOffset + count);
}

- (NSUInteger)copyBytesToBuffer:(void *)buffer minimumBytes:(unsigned int)maximum maximumBytes:(unsigned int)minimum advance:(BOOL)shouldAdvance
{
    NSUInteger bytesPeeked;

    if (minimum > 0)
        [self bufferBytes:minimum];

    bytesPeeked = bufferedDataValidLength - ( dataOffset - bufferedDataStart );
    bytesPeeked = MIN(bytesPeeked, maximum);
    [bufferedData getBytes:buffer range:(NSRange){ ( dataOffset - bufferedDataStart ), bytesPeeked }];
    
    if (shouldAdvance)
        dataOffset += bytesPeeked;
    
    return bytesPeeked;
}


- (void)readBytes:(unsigned int)count intoBuffer:(void *)buffer
{
    [self bufferBytes:count];
    [bufferedData getBytes:buffer range:(NSRange){ ( dataOffset - bufferedDataStart ), count }];
    dataOffset += count;
}

- (void)peekBytes:(unsigned int)count intoBuffer:(void *)buffer
{
    [self bufferBytes:count];
    [bufferedData getBytes:buffer range:(NSRange){ ( dataOffset - bufferedDataStart ), count }];
}

- (NSUInteger)peekUnderlyingBuffer:(void **)returnedBufferPtr
{
    NSUInteger availableUnreadBytes;
    
    if ([self isAtEOF])
        return 0;
        
    [self bufferBytes:1];

    OBINVARIANT(dataOffset >= bufferedDataStart);
    availableUnreadBytes = bufferedDataStart + bufferedDataValidLength - dataOffset;
    *returnedBufferPtr = (void *)[bufferedData bytes] + ( dataOffset - bufferedDataStart );
    return availableUnreadBytes;
}

- (NSUInteger)dataLength
{
    while ([self enlargeBuffer])
        ;

    return bufferedDataStart + bufferedDataValidLength;
}

- (BOOL)isAtEOF
{
    if (!haveStartedFilter)
        [self processBegin];

    if (bufferedDataStart + bufferedDataValidLength > dataOffset)
        return NO;
    if (!canFillMoreBuffer)
        return YES;

    return ![self enlargeBuffer];
}

- (BOOL)haveFinishedReadingData
{
    if (!haveStartedFilter)
        [self processBegin];

    if (bufferedDataStart + bufferedDataValidLength > dataOffset)
        return NO;
    if (!canFillMoreBuffer)
        return YES;

    return NO;
}

- (NSData *)peekBytesOrUntilEOF:(unsigned int)count
{
    OBFinishPorting; // 64->32 warnings -- if we even keep this framework
#if 0
    unsigned availableUnreadBytes;
    NSRange peekRange;
    
    while (![self haveBufferedBytes:count]) {
        if (![self enlargeBuffer])
            break;
    }

    availableUnreadBytes = bufferedDataStart + bufferedDataValidLength - dataOffset;
    peekRange.location = bufferedDataStart - dataOffset;
    peekRange.length = MIN(count, availableUnreadBytes);
    return [bufferedData subdataWithRange:peekRange];
#endif
}

- (NSData *)readAllData
{
    OBFinishPorting; // 64->32 warnings -- if we even keep this framework
#if 0
    NSData *result;
    unsigned int oldBytesInBuffer;

    if (dataOffset < bufferedDataStart)
        [OWDataStreamCursor_SeekException raise];
    if (abortException)
        [abortException raise];

    if (bufferedDataStart + bufferedDataValidLength == dataOffset) {
        bufferedDataValidLength = 0;
        bufferedDataStart = dataOffset;
    }
    
    while ([self enlargeBuffer])
        ;


    OBASSERT(dataOffset >= bufferedDataStart); // Otherwise, we raise the seek exception above
    oldBytesInBuffer = dataOffset - bufferedDataStart;

    if (bufferedDataValidLength == oldBytesInBuffer)
        return nil; // We have no more data

    result = [bufferedData subdataWithRange:NSMakeRange(oldBytesInBuffer, bufferedDataValidLength - oldBytesInBuffer)];
    [bufferedData release];
    bufferedData = [[NSMutableData alloc] initWithCapacity:0];
    bufferedDataStart += bufferedDataValidLength;
    bufferedDataValidLength = 0;
    dataOffset = bufferedDataStart;
    
    return result;
#endif
}

- (void)fillBuffer:(void *)buffer length:(unsigned)bufferLength filledToIndex:(unsigned *)bufferFullp
{
    OBRequestConcreteImplementation(self, _cmd);
}

- (void)_bufferInThreadAndThenScheduleInQueue:(OFMessageQueue *)aQueue invocation:(OFInvocation *)anInvocation
{
    NS_DURING {
        [self bufferBytes:1];
    } NS_HANDLER {
#ifdef DEBUG
        NSLog(@"%@, recording exception: %@", NSStringFromSelector(_cmd), localException);
#endif
        [self abortWithException:localException];
    } NS_ENDHANDLER;
    
    if (aQueue)
        [aQueue addQueueEntry:anInvocation];
    else
        [anInvocation invoke];
}

- (void)scheduleInQueue:(OFMessageQueue *)aQueue invocation:(OFInvocation *)anInvocation
{
    if ([self haveBufferedBytes:1]) {
        // We have some buffered data, so perform the invocation right now.
        if (aQueue)
            [aQueue addQueueEntry:anInvocation];
        else
            [anInvocation invoke];
    } else {
        // We don't have any data buffered, so buffer some in another thread
        [[OWProcessor processorQueue] queueSelector:@selector(_bufferInThreadAndThenScheduleInQueue:invocation:) forObject:self withObject:aQueue withObject:anInvocation];
    }
}

@end

NSString *OWDataStreamCursor_SeekExceptionName = @"OWDataStreamCursor Seek Exception";

