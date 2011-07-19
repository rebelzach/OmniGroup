// Copyright 2010-2011 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniFoundation/OFFileWrapper.h>

#if OFFILEWRAPPER_ENABLED

#import <Foundation/NSKeyedArchiver.h>
#import <OmniBase/assertions.h>
#import <OmniFoundation/NSDictionary-OFExtensions.h>
#import <OmniFoundation/NSMutableDictionary-OFExtensions.h>
#import <OmniFoundation/OFNull.h>
#import <OmniFoundation/OFStringScanner.h>

RCS_ID("$Id$");

@interface OFFileWrapper ()
+ (NSString *)_preferredFilenameFromFilename:(NSString *)filename;
@end

@implementation OFFileWrapper

static NSString *OFFileWrapperConflictMarker = @"__#$!@%!#__";

- (id)initWithURL:(NSURL *)url options:(OFFileWrapperReadingOptions)options error:(NSError **)outError;
{
    OBPRECONDITION(options == 0); // we don't handle any options

    if (!(self = [super init]))
        return nil;

    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *path = [[url absoluteURL] path];
    
    _filename = [[path lastPathComponent] copy];
    _preferredFilename = [[OFFileWrapper _preferredFilenameFromFilename:_filename] copy];
    
    _fileAttributes = [[manager attributesOfItemAtPath:path error:outError] copy];
    if (!_fileAttributes) {
        [self release];
        return nil;
    }
    
    NSString *fileType = [_fileAttributes fileType];
    if (OFISEQUAL(fileType, NSFileTypeDirectory)) {
        NSArray *contents = [manager contentsOfDirectoryAtPath:path error:outError];
        if (!contents) {
            [self release];
            return nil;
        }

        _fileWrappers = [[NSMutableDictionary alloc] init];
        for (NSString *file in contents) {
            OFFileWrapper *childWrapper = [[OFFileWrapper alloc] initWithURL:[NSURL fileURLWithPath:[path stringByAppendingPathComponent:file]] options:options error:outError];
            if (!childWrapper) {
                [self release];
                return nil;
            }
            
            [_fileWrappers setObject:childWrapper forKey:file];
            [childWrapper release];
        }
        
        return self;
    }
    
    if (OFISEQUAL(fileType, NSFileTypeRegular)) {
        _contents = [[NSData alloc] initWithContentsOfURL:url options:0 error:outError];
        if (!_contents) {
            [self release];
            return nil;
        }
        
        return self;
    }

    if (OFISEQUAL(fileType, NSFileTypeSymbolicLink)) {
        _symbolicLinkDestination = [manager destinationOfSymbolicLinkAtPath:path error:outError];
        if (_symbolicLinkDestination == nil) {
            [self release];
            return nil;
        }

        return self;
    }
    
    NSLog(@"Not handling file type %@", fileType);
    OBFinishPorting;
    return nil;
}

- (id)initDirectoryWithFileWrappers:(NSDictionary *)childrenByPreferredName;
{
    if (!(self = [super init]))
        return nil;

    // NSFileWrapper will automatically propagate the preferred names to the child wrappers "if any file wrapper in the directory doesn't have a preferred filename". It isn't clear what happens if you pass in a dictionary like { "a" = <wrapper preferredName="b">; }.  We'll assert this isn't the case and override it.
    // It isn't clear at what point NSFileWrapper updates its dictionary if you change the preferred file name on a wrapper. Scary.
    
    _fileWrappers = [[NSMutableDictionary alloc] initWithDictionary:childrenByPreferredName];
    
    for (NSString *preferredName in _fileWrappers) {
        // Should be a single component.
        OBASSERT(![NSString isEmptyString:preferredName]);
        OBASSERT([[preferredName pathComponents] count] == 1);
        OBASSERT(![preferredName isAbsolutePath]);
        
        OFFileWrapper *childWrapper = [childrenByPreferredName objectForKey:preferredName];
        OBASSERT([childWrapper.preferredFilename isEqualToString:preferredName]);
        childWrapper.preferredFilename = preferredName;
    }

    return self;
}

- (id)initRegularFileWithContents:(NSData *)contents;
{
    OBPRECONDITION(contents != nil);
    
    if (!(self = [super init]))
        return nil;
    
    _contents = [contents copy];

    return self;
}

- (id)initSymbolicLinkWithDestination:(NSString *)path;
{
    OBPRECONDITION(path != nil);
    
    if (!(self = [super init]))
        return nil;
    
    _symbolicLinkDestination = [path copy];
    
    return self;
}

- (void)dealloc;
{
    [_fileWrappers release];
    [_contents release];
    [_symbolicLinkDestination release];
    [_fileAttributes release];
    [_preferredFilename release];
    [_filename release];
    [super dealloc];
}

static void _updateWrapperNamesFromURL(OFFileWrapper *self)
{
    // We should be a directory
    OBPRECONDITION(self->_fileWrappers);
    
    for (NSString *childKey in self->_fileWrappers) {
        OFFileWrapper *childWrapper = [self->_fileWrappers objectForKey:childKey];
        
        childWrapper.filename = childKey;
        
        if (childWrapper->_fileWrappers)
            _updateWrapperNamesFromURL(childWrapper);
    }
}

- (BOOL)writeToURL:(NSURL *)url options:(OFFileWrapperWritingOptions)options originalContentsURL:(NSURL *)originalContentsURL error:(NSError **)outError;
{
    OBPRECONDITION((options & ~(OFFileWrapperWritingAtomic|OFFileWrapperWritingWithNameUpdating)) == 0); // Only two defined flags
    OBPRECONDITION((options & OFFileWrapperWritingAtomic) == 0); // assuming higher level APIs will do this
    OBPRECONDITION(url);

    // Only update file names from the top level, on success.
    BOOL updateFilenames = (options & OFFileWrapperWritingWithNameUpdating) != 0;
    options &= ~OFFileWrapperWritingWithNameUpdating;
    
    // In testing, NSFileWrapper won't allow overwriting of a destination unless the source and destination are both flat files. So, we'll not intentionally allow this at all.
    url = [url absoluteURL];

    if (_contents) {
        if (![[NSFileManager defaultManager] createFileAtPath:[url path] contents:_contents attributes:_fileAttributes])
            return NO;
    } else if (_fileWrappers) {
        NSString *path = [url path];
        
        if (![[NSFileManager defaultManager] createDirectoryAtPath:[url path] withIntermediateDirectories:NO attributes:_fileAttributes error:outError])
            return NO;

        for (NSString *childKey in _fileWrappers) {
            OFFileWrapper *childWrapper = [_fileWrappers objectForKey:childKey];
            OBASSERT([childWrapper filename] == nil || [childKey isEqualToString:[childWrapper filename]]);
            
            NSURL *originalChildURL = nil;
            if (originalContentsURL)
                originalChildURL = [NSURL fileURLWithPath:[[originalContentsURL path] stringByAppendingPathComponent:childKey]];
            
            if (![childWrapper writeToURL:[NSURL fileURLWithPath:[path stringByAppendingPathComponent:childKey]]
                                  options:options
                      originalContentsURL:originalChildURL
                                    error:outError])
                return NO;
        }
    } else if (_symbolicLinkDestination) {
        if (![[NSFileManager defaultManager] createSymbolicLinkAtPath:[url path] withDestinationPath:_symbolicLinkDestination error:outError])
            return NO;
    } else {
        OBRequestConcreteImplementation(self, _cmd); // Not supporting character special files, for example.
    }
    
    [_preferredFilename release];
    _preferredFilename = [[[url path] lastPathComponent] copy];
    [_filename release];
    _filename = [_preferredFilename copy];

    if (_fileWrappers && updateFilenames) {
        // On success, update the child file wrappers file names too.
        // Might need to build some mapping of actual names written as we recurse if we allow conflicting preferred file names and uniquing on write.
        _updateWrapperNamesFromURL(self);
    }
    
    return YES;
}

- (NSDictionary *)fileAttributes;
{
    return _fileAttributes;
}

- (BOOL)isRegularFile;
{
    return _contents != nil;
}

- (BOOL)isDirectory;
{
    return _fileWrappers != nil;
}

- (BOOL)isSymbolicLink;
{
    return _symbolicLinkDestination != nil;
}

@synthesize filename = _filename;

- (NSData *)regularFileContents;
{
    OBPRECONDITION(_contents); // Don't ask this unless it is a file. Real class might even raise.
    return _contents;
}

- (NSDictionary *)fileWrappers;
{
    OBPRECONDITION(_fileWrappers); // Don't ask this unless it is a directory. Real class might even raise.
    return _fileWrappers;
}

- (NSString *)symbolicLinkDestination;
{
    OBPRECONDITION(_symbolicLinkDestination);
    return _symbolicLinkDestination;
}

@synthesize preferredFilename = _preferredFilename;

- (NSString *)addFileWrapper:(OFFileWrapper *)child;
{
    // NSFileWrapper docs:
    // This method raises NSInternalInconsistencyException if the receiver is not a directory file wrapper.
    // This method raises NSInvalidArgumentException if the child file wrapper doesn’t have a preferred name.
            
            
    if (!_fileWrappers)
        [NSException raise:NSInternalInconsistencyException reason:@"Attempted to add a child wrapper to a non-directory parent."];
    
    NSString *childPreferredFilename = child.preferredFilename;
    if (!childPreferredFilename)
        [NSException raise:NSInvalidArgumentException reason:@"Child doesn't have a preferred filename."];
        
    // Unique filenames
    NSString *filename = childPreferredFilename;
    if ([_fileWrappers objectForKey:filename] != nil) {
        NSUInteger conflictIndex = 0;
        do {
            conflictIndex++;
            filename = [NSString stringWithFormat:@"%u%@%@", conflictIndex, OFFileWrapperConflictMarker, childPreferredFilename];
        } while ([_fileWrappers objectForKey:filename] != nil);
        child.filename = filename;
    }

    [_fileWrappers setObject:child forKey:filename];

    return filename;
}

- (void)removeFileWrapper:(OFFileWrapper *)child;
{
    OBFinishPorting;
}

- (NSString *)keyForFileWrapper:(OFFileWrapper *)child;
{
    // "This method raises NSInternalInconsistencyException if the receiver is not a directory file wrapper."
    if (!_fileWrappers)
        [NSException raise:NSInternalInconsistencyException reason:@"-keyForFileWrapper: called on non-directory wrapper."];
        
    NSString *key = [_fileWrappers keyForObjectEqualTo:child];
    OBASSERT(key); // Don't ask unless it really is our child
    
    return key;
}

- (BOOL)matchesContentsOfURL:(NSURL *)url;
{
    OBFinishPorting;
}

#pragma mark -
#pragma mark Serialization

- (void)encodeWithCoder:(NSCoder *)coder;
{
    [coder encodeObject:_fileAttributes forKey:@"fileAttributes"];
    [coder encodeObject:_preferredFilename forKey:@"preferredFilename"];
    [coder encodeObject:_filename forKey:@"filename"];
    [coder encodeObject:_fileWrappers forKey:@"fileWrappers"];
    [coder encodeObject:_contents forKey:@"contents"];
    [coder encodeObject:_symbolicLinkDestination forKey:@"symbolicLinkDestination"];
}

- (id)initWithCoder:(NSCoder *)coder;
{
    if (!(self = [super init]))
        return nil;
    
    _fileAttributes = [[coder decodeObjectForKey:@"fileAttributes"] retain];
    _preferredFilename = [[coder decodeObjectForKey:@"preferredFilename"] retain];
    _filename = [[coder decodeObjectForKey:@"filename"] retain];
    _fileWrappers = [[coder decodeObjectForKey:@"fileWrappers"] retain];
    _contents = [[coder decodeObjectForKey:@"contents"] retain];
    _symbolicLinkDestination = [[coder decodeObjectForKey:@"symbolicLinkDestination"] retain];

    return self;
}

- (NSData *)serializedRepresentation;
{
    return [NSKeyedArchiver archivedDataWithRootObject:self];
}

- (id)initWithSerializedRepresentation:(NSData *)serializedRepresentation;
{
    if (!(self = [super init]))
        return nil;
    [self release];
    return [[NSKeyedUnarchiver unarchiveObjectWithData:serializedRepresentation] retain];
}

#pragma mark -
#pragma mark Convenience methods

- (NSString *)addRegularFileWithContents:(NSData *)data preferredFilename:(NSString *)fileName;
{
    OFFileWrapper *childWrapper = [[OFFileWrapper alloc] initRegularFileWithContents:data];
    childWrapper.preferredFilename = fileName;
    NSString *uniqueName = [self addFileWrapper:childWrapper];
    [childWrapper release];
    return uniqueName;
}

#pragma mark -
#pragma mark Private

+ (NSString *)_preferredFilenameFromFilename:(NSString *)filename;
{
    static OFCharacterSet *numericSet = nil;
    if (numericSet == nil)
        numericSet = [[OFCharacterSet alloc] initWithString:@"0123456789"];

    NSString *preferredFilename = filename;
    OFStringScanner *scanner = [[OFStringScanner alloc] initWithString:filename];
    if ([scanner scanUnsignedIntegerMaximumDigits:10] != 0 && scannerReadString(scanner, OFFileWrapperConflictMarker))
        preferredFilename = [scanner readRemainingBufferedCharacters];
    [scanner release];
    return preferredFilename;
}

#pragma mark -
#pragma mark Debugging

#ifdef DEBUG

- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *debugDictionary = [super debugDictionary];
    [debugDictionary setObject:_filename forKey:@"filename" defaultObject:nil];
    [debugDictionary setObject:_preferredFilename forKey:@"preferredFilename" defaultObject:nil];
    [debugDictionary setObject:_fileWrappers forKey:@"fileWrappers" defaultObject:nil];
    return debugDictionary;
}

#endif

@end

#endif
