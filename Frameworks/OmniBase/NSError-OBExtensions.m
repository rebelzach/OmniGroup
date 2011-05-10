// Copyright 2005-2009 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniBase/NSError-OBExtensions.h>

#import <OmniBase/rcsid.h>
#import <OmniBase/assertions.h>
#import <OmniBase/OBUtilities.h>

#import <Foundation/NSUserDefaults.h>

#if !defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE
#import <Security/Authorization.h> // for errAuthorizationCanceled
#endif

RCS_ID("$Id$");

// This might be useful for non-debug builds too.  These are only included in our errors, not Cocoa's, but if we use OBChainError when our code fails due to a Mac OS X framework call failing, we'll get information there.
#if 0 && defined(DEBUG)
    #define INCLUDE_BACKTRACE_IN_ERRORS 1
#else
    #define INCLUDE_BACKTRACE_IN_ERRORS 0
#endif

#if INCLUDE_BACKTRACE_IN_ERRORS
    #include <execinfo.h>  // For backtrace()
    static NSString * const OBBacktraceAddressesErrorKey = @"com.omnigroup.framework.OmniBase.ErrorDomain.BacktraceAddresses";
    static NSString * const OBBacktraceNamesErrorKey = @"com.omnigroup.framework.OmniBase.ErrorDomain.Backtrace";
#endif

static id (*original_initWithDomainCodeUserInfo)(NSError *self, SEL _cmd, NSString *domain, NSInteger code, NSDictionary *dict) = NULL;

@implementation NSError (OBExtensions)

- (id)logging_initWithDomain:(NSString *)domain code:(NSInteger)code userInfo:(NSDictionary *)dict;
{
    self = original_initWithDomainCodeUserInfo(self, _cmd, domain, code, dict);
    if (self)
        NSLog(@"Error created: %@", [self toPropertyList]);
    return self;
}

+ (void)performPosing;
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"OBLogErrorCreations"]) {
        original_initWithDomainCodeUserInfo = (typeof(original_initWithDomainCodeUserInfo))OBReplaceMethodImplementationWithSelector(self, @selector(initWithDomain:code:userInfo:), @selector(logging_initWithDomain:code:userInfo:));
    }
}

- (NSError *)underlyingErrorWithDomain:(NSString *)domain;
{
    NSError *error = self;
    while (error) {
	if ([[error domain] isEqualToString:domain])
	    return error;
	error = [[error userInfo] objectForKey:NSUnderlyingErrorKey];
    }
    return nil;
}

- (NSError *)underlyingErrorWithDomain:(NSString *)domain code:(NSInteger)code;
{
    NSError *error = self;
    while (error) {
	if ([[error domain] isEqualToString:domain] && [error code] == code)
	    return error;
	error = [[error userInfo] objectForKey:NSUnderlyingErrorKey];
    }
    return nil;
}

// Returns YES if the error or any of its underlying errors has the indicated domain and code.
- (BOOL)hasUnderlyingErrorDomain:(NSString *)domain code:(NSInteger)code;
{
    return ([self underlyingErrorWithDomain:domain code:code] != nil);
}

- (BOOL)causedByUserCancelling;
{    
    if ([self hasUnderlyingErrorDomain:NSCocoaErrorDomain code:NSUserCancelledError])
        return YES;
    
#if !defined(TARGET_OS_IPHONE) || !TARGET_OS_IPHONE
    if ([self hasUnderlyingErrorDomain:NSOSStatusErrorDomain code:errAuthorizationCanceled])
        return YES;
#endif
    
    return NO;
}

static void _mapPlistValueToUserInfoEntry(const void *key, const void *value, void *context)
{
    NSString *keyString = (NSString *)key;
    id valueObject = (id)value;
    NSMutableDictionary *mappedUserInfo = (NSMutableDictionary *)context;
    
    // This is lossy, but once something is plist-ified, we can't be sure where it came from.
    if ([keyString isEqualToString:NSUnderlyingErrorKey])
        valueObject = [[[NSError alloc] initWithPropertyList:valueObject] autorelease];
    else if ([keyString isEqualToString:NSRecoveryAttempterErrorKey] && [valueObject isKindOfClass:[NSString class]])
        return; // We can't turn an NSString back into a valid -recoveryAttempter object

    [mappedUserInfo setObject:valueObject forKey:keyString];
}

- initWithPropertyList:(NSDictionary *)propertyList;
{
    NSString *domain = [propertyList objectForKey:@"domain"];
    NSNumber *code = [propertyList objectForKey:@"code"];
    
    OBASSERT(domain);
    OBASSERT(code);
    
    NSDictionary *userInfo = [propertyList objectForKey:@"userInfo"];
    if (userInfo) {
        NSMutableDictionary *mappedUserInfo = [NSMutableDictionary dictionary];
        CFDictionaryApplyFunction((CFDictionaryRef)userInfo, _mapPlistValueToUserInfoEntry, mappedUserInfo);
        userInfo = mappedUserInfo;
    }
    
    return [self initWithDomain:domain code:[code intValue] userInfo:userInfo];
}

static void _addMappedUserInfoValueToArray(const void *value, void *context);
static void _addMapppedUserInfoValueToDictionary(const void *key, const void *value, void *context);

static id _mapUserInfoValueToPlistValue(const void *value)
{
    id valueObject = (id)value;

    if (!valueObject)
        return @"<nil>";
    
    // Handle some specific non-plist values
    if ([valueObject isKindOfClass:[NSError class]])
        return [(NSError *)valueObject toPropertyList];
    
    if ([valueObject isKindOfClass:[NSURL class]])
        return [valueObject absoluteString];
    
    // Handle containers explicitly since they might contain non-plist values
    if ([valueObject isKindOfClass:[NSArray class]]) {
        NSMutableArray *mapped = [NSMutableArray array];
        CFArrayApplyFunction((CFArrayRef)valueObject, CFRangeMake(0, [valueObject count]), _addMappedUserInfoValueToArray, mapped);
        return mapped;
    }
    if ([valueObject isKindOfClass:[NSSet class]]) {
        // Map sets to arrays.
        NSMutableArray *mapped = [NSMutableArray array];
        CFSetApplyFunction((CFSetRef)valueObject, _addMappedUserInfoValueToArray, mapped);
        return mapped;
    }
    if ([valueObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *mapped = [NSMutableDictionary dictionary];
        CFDictionaryApplyFunction((CFDictionaryRef)valueObject, _addMapppedUserInfoValueToDictionary, mapped);
        return mapped;
    }
    
    // We can only bring along plist-able values (so, for example, no NSRecoveryAttempterErrorKey).
    if (![NSPropertyListSerialization propertyList:valueObject isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
#ifdef DEBUG
        NSLog(@"'%@' of class '%@' is not a property list value.", valueObject, [valueObject class]);
#endif
        return [valueObject description];
    }
    
    return valueObject;
}

static void _addMappedUserInfoValueToArray(const void *value, void *context)
{
    id valueObject = _mapUserInfoValueToPlistValue(value);
    OBASSERT(valueObject); // mapping returns something for nil
    [(NSMutableArray *)context addObject:valueObject];
}

static void _addMapppedUserInfoValueToDictionary(const void *key, const void *value, void *context)
{
    NSString *keyString = (NSString *)key;
    id valueObject = (id)value;
    NSMutableDictionary *mappedUserInfo = (NSMutableDictionary *)context;

#if INCLUDE_BACKTRACE_IN_ERRORS
    if ([keyString isEqualToString:OBBacktraceAddressesErrorKey]) {
        // Transform this to symbol names when actually interested in it.
        NSData *frameData = valueObject;
        const void* const* frames = [frameData bytes];
        int frameCount = [frameData length] / sizeof(frames[0]);
        char **names = backtrace_symbols((void* const* )frames, frameCount);
        if (names) {
            NSMutableArray *namesArray = [NSMutableArray array];
            for (int nameIndex = 0; nameIndex < frameCount; nameIndex++)
                [namesArray addObject:[NSString stringWithCString:names[nameIndex] encoding:NSUTF8StringEncoding]];
            free(names);
            
            [mappedUserInfo setObject:namesArray forKey:OBBacktraceNamesErrorKey];
            return;
        }
    }
#endif

    valueObject = _mapUserInfoValueToPlistValue(valueObject);
    [mappedUserInfo setObject:valueObject forKey:keyString];
}

- (NSDictionary *)toPropertyList;
{
    NSMutableDictionary *plist = [NSMutableDictionary dictionary];
    
    [plist setObject:[self domain] forKey:@"domain"];
    [plist setObject:[NSNumber numberWithInteger:[self code]] forKey:@"code"];
    
    NSDictionary *userInfo = [self userInfo];
    if (userInfo)
        [plist setObject:_mapUserInfoValueToPlistValue(userInfo) forKey:@"userInfo"];
    
    return plist;
}

@end

