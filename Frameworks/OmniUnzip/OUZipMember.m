// Copyright 2008, 2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniUnzip/OUZipMember.h>

#import <OmniUnzip/OUZipFileMember.h>
#import <OmniUnzip/OUZipDirectoryMember.h>
#import <OmniUnzip/OUZipLinkMember.h>

#if !defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE
#import <AppKit/NSFileWrapper.h>
#endif

RCS_ID("$Id$");

@implementation OUZipMember

#if !defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE
- initWithFileWrapper:(NSFileWrapper *)fileWrapper;
{
    // This shouldn't be called on a concrete class.  That would imply the caller knew the type of the file wrapper, which it shouldn't bother with.
    OBPRECONDITION([self class] == [OUZipMember class]);
    OBPRECONDITION(![NSString isEmptyString:[fileWrapper preferredFilename]]);
    
    if ([fileWrapper isRegularFile]) {
        [self release];
        return [[OUZipFileMember alloc] initWithName:[fileWrapper preferredFilename] date:[[fileWrapper fileAttributes] fileModificationDate] contents:[fileWrapper regularFileContents]];
    } else if ([fileWrapper isSymbolicLink]) {
        [self release];
        return [[OUZipLinkMember alloc] initWithName:[fileWrapper preferredFilename] date:[[fileWrapper fileAttributes] fileModificationDate] destination:[fileWrapper symbolicLinkDestination]];
    } else if ([fileWrapper isDirectory]) {
        [self release];

        OUZipDirectoryMember *directory = [[OUZipDirectoryMember alloc] initWithName:[fileWrapper preferredFilename] date:[[fileWrapper fileAttributes] fileModificationDate] children:nil archive:YES];
        NSDictionary *childWrappers = [fileWrapper fileWrappers];
        NSArray *childKeys = [[childWrappers allKeys] sortedArrayUsingSelector:@selector(compare:)];
        
        for (NSString *childKey in childKeys) {
            NSFileWrapper *childWrapper = [childWrappers objectForKey:childKey];
            OBASSERT([childKey isEqualToString:[childWrapper preferredFilename]]); // Otherwise our child names might not be guaranteed to be unique
            OUZipMember *child = [[OUZipMember alloc] initWithFileWrapper:childWrapper];
            [directory addChild:child];
            [child release];
        }
        return directory;
    }
    
    OBRequestConcreteImplementation(self, _cmd);
    return nil;
}

// Returns a new autoreleased file wrapper; won't return the same wrapper on multiple calls
- (NSFileWrapper *)fileWrapperRepresentation;
{
    OBRequestConcreteImplementation(self, _cmd);
    return nil;
}

#endif

- initWithPath:(NSString *)path fileManager:(NSFileManager *)fileManager;
{
    // This shouldn't be called on a concrete class.  That would imply the caller knew the type of the file wrapper, which it shouldn't bother with.
    OBPRECONDITION([self class] == [OUZipMember class]);
    OBPRECONDITION(![NSString isEmptyString:[path lastPathComponent]]);

    [self release]; self = nil; // We won't be returning an abstract class
    OB_UNUSED_VALUE(self);
    
    NSString *preferredFilename = [path lastPathComponent];
    
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:NULL];
    if (!fileAttributes)
        return nil;
        
    if ([[fileAttributes fileType] isEqualToString:NSFileTypeRegular]) {
        return [[OUZipFileMember alloc] initWithName:preferredFilename date:[fileAttributes fileModificationDate] mappedFilePath:path];
    } else if ([[fileAttributes fileType] isEqualToString:NSFileTypeSymbolicLink]) {
        NSString *destination = [fileManager destinationOfSymbolicLinkAtPath:path error:NULL];
        if (!destination)
            return nil;
        return [[OUZipLinkMember alloc] initWithName:preferredFilename date:[fileAttributes fileModificationDate] destination:destination];
    } else if ([[fileAttributes fileType] isEqualToString:NSFileTypeDirectory]) {
        OUZipDirectoryMember *directory = [[OUZipDirectoryMember alloc] initWithName:preferredFilename date:[fileAttributes fileModificationDate] children:nil archive:YES];
        NSArray *childNames = [fileManager contentsOfDirectoryAtPath:path error:NULL];
        NSUInteger childIndex, childCount = [childNames count];
        for (childIndex = 0; childIndex < childCount; childIndex++) {
            NSString *childName = [childNames objectAtIndex:childIndex];
            NSString *childPath = [path stringByAppendingPathComponent:childName];
            OUZipMember *child = [[OUZipMember alloc] initWithPath:childPath fileManager:fileManager];
            if (child == nil)
                continue;
            [directory addChild:child];
            [child release];
        }
        return directory;
    } else {
        // Silently skip file types we don't know how to archive (sockets, character special, block special, and unknown)
        return nil;
    }
}

- initWithName:(NSString *)name date:(NSDate *)date;
{
    // TODO: Convert some of these to error/exceptions
    OBPRECONDITION(![NSString isEmptyString:name]);
    OBPRECONDITION([self class] != [OUZipMember class]);
    
    _name = [name copy];
    _date = [date copy];

    return self;
}

- (void)dealloc;
{
    [_name release];
    [_date release];
    [super dealloc];
}

- (NSString *)name;
{
    return _name;
}

- (NSDate *)date;
{
    return _date;
}

- (BOOL)appendToZipArchive:(OUZipArchive *)zip fileNamePrefix:(NSString *)fileNamePrefix error:(NSError **)outError;
{
    OBRequestConcreteImplementation(self, _cmd);
    return NO;
}

- (NSComparisonResult)localizedCaseInsensitiveCompareByName:(OUZipMember *)otherMember;
{
    return [_name localizedCaseInsensitiveCompare:[otherMember name]];
}

@end
