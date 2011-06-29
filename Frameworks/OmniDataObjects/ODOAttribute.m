// Copyright 2008, 2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniDataObjects/ODOAttribute.h>

RCS_ID("$Id$")

#import <OmniDataObjects/ODOModel-Creation.h>
#import "ODOProperty-Internal.h"

@implementation ODOAttribute

- (void)dealloc;
{
    [_defaultValue release];
    [super dealloc];
}

- (ODOAttributeType)type;
{
    return _type;
}

- (NSObject <NSCopying> *)defaultValue;
{
    OBPRECONDITION(!_defaultValue || [_defaultValue isKindOfClass:_valueClass]);
    return _defaultValue;
}

- (Class)valueClass;
{
    OBPRECONDITION(_valueClass);
    return _valueClass;
}

@synthesize isPrimaryKey = _isPrimaryKey;

#pragma mark -
#pragma mark Debugging

#ifdef DEBUG
- (NSMutableDictionary *)debugDictionary;
{
    NSMutableDictionary *dict = [super debugDictionary];
    [dict setObject:[NSNumber numberWithInt:_type] forKey:@"type"];
    if (_defaultValue)
        [dict setObject:_defaultValue forKey:@"defaultValue"];
    return dict;
}
#endif

#pragma mark ODOModel creation

// No validation is done for non-DEBUG builds.  The Ruby generator is expected to have done it.
ODOAttribute *ODOAttributeCreate(NSString *name, BOOL optional, BOOL calculated, BOOL transient, SEL get, SEL set,
                                 ODOAttributeType type, Class valueClass, NSObject <NSCopying> *defaultValue, BOOL isPrimaryKey)
{
    OBPRECONDITION(type > ODOAttributeTypeInvalid);
    OBPRECONDITION(type < ODOAttributeTypeCount);
    OBPRECONDITION(valueClass);
    OBPRECONDITION([valueClass conformsToProtocol:@protocol(NSCopying)] || (valueClass == [NSObject class] && transient)); // Can use NSObject/transient w/o having the class itself require NSCopying.  The values will require it, though.
    
    ODOAttribute *attr = [[ODOAttribute alloc] init];
    attr->_isPrimaryKey = isPrimaryKey;

    struct _ODOPropertyFlags baseFlags;
    memset(&baseFlags, 0, sizeof(baseFlags));
    baseFlags.snapshotIndex = ODO_NON_SNAPSHOT_PROPERTY_INDEX; // start out not being in the snapshot properties; this'll get updated later if we are

    if (attr->_isPrimaryKey)
        // The primary key isn't in the snapshot, but has a special marker for that.
        baseFlags.snapshotIndex = ODO_PRIMARY_KEY_SNAPSHOT_INDEX;
    
    ODOPropertyInit(attr, name, baseFlags, optional, calculated, transient, get, set);

    attr->_type = type;
    attr->_valueClass = valueClass;
    attr->_defaultValue = [defaultValue copy];
    
    return attr;
}

@end
