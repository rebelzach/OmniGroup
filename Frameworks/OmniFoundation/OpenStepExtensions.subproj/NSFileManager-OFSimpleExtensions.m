// Copyright 1997-2008, 2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/NSFileManager-OFSimpleExtensions.h>

#import <OmniFoundation/NSDictionary-OFExtensions.h>
#import <sys/stat.h> // For statbuf, stat, mkdir

RCS_ID("$Id$")

@implementation NSFileManager (OFSimpleExtensions)

- (NSDictionary *)attributesOfItemAtPath:(NSString *)filePath traverseLink:(BOOL)traverseLink error:(NSError **)outError
{
#ifdef MAXSYMLINKS
    int links_followed = 0;
#endif
    
    for(;;) {
        NSDictionary *attributes = [self attributesOfItemAtPath:filePath error:outError];
        if (!attributes) // Error return
            return nil;
        
        if (traverseLink && [[attributes fileType] isEqualToString:NSFileTypeSymbolicLink]) {
#ifdef MAXSYMLINKS
            BOOL linkCountOK = (links_followed++ < MAXSYMLINKS);
            if (!linkCountOK) {
                if (outError)
                    *outError = [NSError errorWithDomain:NSPOSIXErrorDomain code:ELOOP userInfo:[NSDictionary dictionaryWithObject:filePath forKey:NSFilePathErrorKey]];
                return nil;
            }
#endif
            NSString *dest = [self destinationOfSymbolicLinkAtPath:filePath error:outError];
            if (!dest)
                return nil;
            if ([dest isAbsolutePath])
                filePath = dest;
            else
                filePath = [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:dest];
            continue;
        }
        
        return attributes;
    }
}

- (BOOL)directoryExistsAtPath:(NSString *)path traverseLink:(BOOL)traverseLink;
{
    NSDictionary *attributes = [self attributesOfItemAtPath:path traverseLink:traverseLink error:NULL];
    return attributes && [[attributes fileType] isEqualToString:NSFileTypeDirectory];
}                                                                                 

- (BOOL)directoryExistsAtPath:(NSString *)path;
{
    return [self directoryExistsAtPath:path traverseLink:NO];
}

- (BOOL)createPath:(NSString *)path attributes:(NSDictionary *)attributes error:(NSError **)outError;
// Creates any directories needed to be able to create a file at the specified path.  Raises an exception on failure.
{
    return [self createDirectoryAtPath:path withIntermediateDirectories:YES attributes:attributes error:outError];
}

- (BOOL)createPathToFile:(NSString *)path attributes:(NSDictionary *)attributes error:(NSError **)outError;
// Creates any directories needed to be able to create a file at the specified path.  Returns NO on failure.
{
    NSArray *pathComponents = [path pathComponents];
    NSUInteger componentCount = [pathComponents count];
    if (componentCount <= 1)
        return YES;
    
    return [self createPathComponents:[pathComponents subarrayWithRange:(NSRange){0, componentCount-1}] attributes:attributes error:outError];
}

- (BOOL)createPathComponents:(NSArray *)components attributes:(NSDictionary *)attributes error:(NSError **)outError
{
    if ([attributes count] == 0)
        attributes = nil;
    
    NSUInteger dirCount = [components count];
    NSMutableArray *trimmedPaths = [[NSMutableArray alloc] initWithCapacity:dirCount];
    
    [trimmedPaths autorelease];
    
    NSString *finalPath = [NSString pathWithComponents:components];
    
    NSMutableArray *trim = [[NSMutableArray alloc] initWithArray:components];
    NSError *error = nil;
    for (NSUInteger trimCount = 0; trimCount < dirCount && !error; trimCount ++) {
        struct stat statbuf;
        
        OBINVARIANT([trim count] == (dirCount - trimCount));
        NSString *trimmedPath = [NSString pathWithComponents:trim];
        const char *path = [trimmedPath fileSystemRepresentation];
        if (stat(path, &statbuf)) {
            int err = errno;
            if (err == ENOENT) {
                [trimmedPaths addObject:trimmedPath];
                [trim removeLastObject];
                // continue
            } else {
                OBErrorWithErrnoObjectsAndKeys(&error, err, "stat", trimmedPath,
                                               NSLocalizedStringFromTableInBundle(@"Could not create directory", @"OmniFoundation", OMNI_BUNDLE, @"Error message when stat() fails when trying to create a directory tree"),
                                               finalPath, NSFilePathErrorKey, nil);
                
            }
        } else if ((statbuf.st_mode & S_IFMT) != S_IFDIR) {
            OBErrorWithErrnoObjectsAndKeys(&error, ENOTDIR, "mkdir", trimmedPath,
                                           NSLocalizedStringFromTableInBundle(@"Could not create directory", @"OmniFoundation", OMNI_BUNDLE, @"Error message when mkdir() will fail because there's a file in the way"),
                                           finalPath, NSFilePathErrorKey, nil);
        } else {
            break;
        }
    }
    [trim release];
    
    if (error) {
        if (outError)
            *outError = error;
        return NO;
    }
    
    mode_t mode;
    mode = 0777; // umask typically does the right thing
    if (attributes && [attributes objectForKey:NSFilePosixPermissions]) {
        mode = [attributes unsignedIntForKey:NSFilePosixPermissions];
        if ([attributes count] == 1)
            attributes = nil;
    }
    
    while ([trimmedPaths count]) {
        NSString *pathString = [trimmedPaths lastObject];
        const char *path = [pathString fileSystemRepresentation];
        if (mkdir(path, mode) != 0) {
            int err = errno;
            OBErrorWithErrnoObjectsAndKeys(outError, err, "mkdir", pathString,
                                           NSLocalizedStringFromTableInBundle(@"Could not create directory", @"OmniFoundation", OMNI_BUNDLE, @"Error message when mkdir() fails"),
                                           finalPath, NSFilePathErrorKey, nil);
            return NO;
        }
        
        if (attributes)
            [self setAttributes:attributes ofItemAtPath:pathString error:NULL];
        
        [trimmedPaths removeLastObject];
    }
    
    return YES;
}

#pragma mark -
#pragma mark Changing file access/update timestamps.

- (void)touchFile:(NSString *)filePath;
{
    NSDictionary *attributes;
    
    attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSDate date], NSFileModificationDate, nil];
    [self setAttributes:attributes ofItemAtPath:filePath error:NULL];
    [attributes release];
}

@end
