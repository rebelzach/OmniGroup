// Copyright 2006-2011 Omni Development, Inc. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/NSFileWrapper-OAExtensions.h>

#import <Foundation/NSDictionary.h>
#import <OmniFoundation/NSString-OFSimpleMatching.h>
#import <OmniFoundation/OFNull.h>
#import <OmniBase/rcsid.h>
#import <OmniBase/assertions.h>

RCS_ID("$Id$");

@implementation OFFileWrapper (OAExtensions)

+ (OFFileWrapper *)fileWrapperWithFilename:(NSString *)filename contents:(NSData *)data;
{
    OFFileWrapper *fileWrapper = [[OFFileWrapper alloc] initRegularFileWithContents:data];
    fileWrapper.filename = filename;
    fileWrapper.preferredFilename = filename;
    return [fileWrapper autorelease];
}

#if !defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE
- (NSString *)fileType:(BOOL *)isHFSType;
{
    NSString *fileType;
    NSDictionary *attributes = [self fileAttributes];
    OSType hfsType = [attributes fileHFSTypeCode];
    if (hfsType) {
        fileType = NSFileTypeForHFSTypeCode(hfsType);
        if (isHFSType)
            *isHFSType = YES;
    } else {
        // No HFS type, try to look at the extension
        NSString *path = [self filename];
        if ([NSString isEmptyString:path] || ![[NSFileManager defaultManager] fileExistsAtPath:path])
            path = [self preferredFilename];
        OBASSERT(![NSString isEmptyString:path]);
        fileType = [path pathExtension];
        if ([NSString isEmptyString:fileType])
            fileType = @"";
        if (isHFSType)
            *isHFSType = NO;
    }
    return fileType;
}
#endif

// This adds the argument to the receiver.  But, if the receiver already has a file wrapper for the preferred file name of the argument, this method attempts to move the old value aside (thus hopefully yielding the name to the argument wrapper).
- (void)addFileWrapperMovingAsidePreviousWrapper:(OFFileWrapper *)wrapper;
{
    NSString *name = [wrapper preferredFilename];
    OBASSERT(![NSString isEmptyString:name]);
    
    NSDictionary *wrappers = [self fileWrappers];
    OFFileWrapper *oldWrapper = [wrappers objectForKey:name];
    if (oldWrapper) {
        [[oldWrapper retain] autorelease];
        [self removeFileWrapper:oldWrapper];
        [self addFileWrapper:wrapper];
        [self addFileWrapper:oldWrapper];
	
        OBASSERT(OFNOTEQUAL([self keyForFileWrapper:oldWrapper], name));
    } else {
        [self addFileWrapper:wrapper];
    }
    
    OBPOSTCONDITION(OFISEQUAL([self keyForFileWrapper:wrapper], name));
}

@end
