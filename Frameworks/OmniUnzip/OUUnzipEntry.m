// Copyright 2008, 2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniUnzip/OUUnzipEntry.h>

#import <OmniFoundation/NSString-OFSimpleMatching.h>

RCS_ID("$Id$");

@implementation OUUnzipEntry

- initWithName:(NSString *)name fileType:(NSString *)fileType date:(NSDate *)date positionInFile:(unsigned long)positionInFile fileNumber:(unsigned long)fileNumber compressionMethod:(unsigned long)compressionMethod compressedSize:(size_t)compressedSize uncompressedSize:(size_t)uncompressedSize crc:(unsigned long)crc;
{
    OBPRECONDITION([name length] > 0);
    OBPRECONDITION(positionInFile > 0); // would be the zip header...
    
    _name = [name copy];
    _fileType = [fileType copy];
    _date = [date copy];
    _positionInFile = positionInFile;
    _fileNumber = fileNumber;
    _compressionMethod = compressionMethod;
    _compressedSize = compressedSize;
    _uncompressedSize = uncompressedSize;
    _crc = crc;
    
    return self;
}

- (void)dealloc;
{
    [_name release];
    [_fileType release];
    [_date release];
    [super dealloc];
}

- (NSString *)name;
{
    return _name;
}

- (NSString *)fileType;
{
    return _fileType;
}

- (NSDate *)date;
{
    return _date;
}

- (unsigned long)positionInFile;
{
    return _positionInFile;
}

- (unsigned long)fileNumber;
{
    return _fileNumber;
}

- (unsigned long)compressionMethod;
{
    return _compressionMethod;
}

- (size_t)compressedSize;
{
    return _compressedSize;
}

- (size_t)uncompressedSize;
{
    return _uncompressedSize;
}

- (unsigned long)crc;
{
    return _crc;
}

- (NSString *)shortDescription;
{
    return [NSString stringWithFormat:@"<%@:%p '%@' offset:%d file number:%d>", NSStringFromClass([self class]), self, _name, _positionInFile, _fileNumber];
}

@end
