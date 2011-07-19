// Copyright 2006-2011 Omni Development, Inc. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <OmniFoundation/OFFileWrapper.h>

@interface OFFileWrapper (OAExtensions)
+ (OFFileWrapper *)fileWrapperWithFilename:(NSString *)filename contents:(NSData *)data;
#if !defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE
- (NSString *)fileType:(BOOL *)isHFSType;
#endif
- (void)addFileWrapperMovingAsidePreviousWrapper:(OFFileWrapper *)wrapper;
@end


