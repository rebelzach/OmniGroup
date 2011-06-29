// Copyright 2008, 2010-2011 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <OmniFoundation/OFObject.h>

@interface OUZipArchive : OFObject
{
@private
    NSString *_path;
    struct TagzipFile__ *_zip;
}

+ (BOOL)createZipFile:(NSString *)zipPath fromFilesAtPaths:(NSArray *)paths error:(NSError **)outError;
+ (BOOL)createZipFile:(NSString *)zipPath fromFileWrappers:(NSArray *)fileWrappers error:(NSError **)outError;

- initWithPath:(NSString *)path error:(NSError **)outError;

- (BOOL)appendEntryNamed:(NSString *)name fileType:(NSString *)fileType contents:(NSData *)contents raw:(BOOL)raw compressionMethod:(unsigned long)comparessionMethod uncompressedSize:(size_t)uncompressedSize crc:(unsigned long)crc date:(NSDate *)date error:(NSError **)outError;
- (BOOL)appendEntryNamed:(NSString *)name fileType:(NSString *)fileType contents:(NSData *)contents date:(NSDate *)date error:(NSError **)outError;

- (BOOL)close:(NSError **)outError;

@end
