// Copyright 2003-2005, 2007-2008, 2010-2011 Omni Development, Inc. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OACompositeColorProfile.h"
#import "OAColorProfile.h"
#import "NSColor-ColorSyncExtensions.h"
#import <AppKit/AppKit.h>
#import <OmniAppKit/OAFeatures.h>
#import <OmniBase/assertions.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Id$");

@implementation OACompositeColorProfile

- initWithProfiles:(NSArray *)someProfiles;
{
    if (!(self = [super init]))
        return nil;
    
    profiles = [someProfiles copy];
    
    return self;
}

- (void)dealloc;
{
    [profiles release];
    [super dealloc];
}

- (NSString *)description;
{
    return [profiles description];
}

#pragma mark OAColorProfile subclass

- (BOOL)_hasRGBSpace;
{
    return [[profiles objectAtIndex:0] _hasRGBSpace];
}

- (BOOL)_hasCMYKSpace;
{
    return [[profiles objectAtIndex:0] _hasCMYKSpace];
}

- (BOOL)_hasGraySpace;
{
    return [[profiles objectAtIndex:0] _hasGraySpace];
}

#if OA_USE_COLOR_MANAGER
- (CMWorldRef)_colorWorldForOutput:(OAColorProfile *)aProfile componentSelector:(SEL)componentSelector;
{
    CMWorldRef result;
    NSUInteger profileIndex, profileCount = [profiles count];
    NCMConcatProfileSet *profileSet = alloca(sizeof(NCMConcatProfileSet) + sizeof(NCMConcatProfileSpec) * (profileCount + 1));
    bzero(profileSet, sizeof(NCMConcatProfileSet) + sizeof(NCMConcatProfileSpec) * (profileCount + 1));
    
    profileSet->cmm = 0; // Use default CMM
    profileSet->flags = 0;
    profileSet->flagsMask = 0;
    
    OBASSERT(strcmp(@encode(typeof(profileSet->profileCount)), @encode(UInt32)) == 0);
    OBASSERT(profileCount < UINT_MAX);
    profileSet->profileCount = (UInt32)profileCount + 1;
    
    for (profileIndex = 0; profileIndex <= profileCount; profileIndex++) {
        OAColorProfile *profile = ( profileIndex < profileCount ) ? [profiles objectAtIndex:profileIndex] : aProfile;
        profileSet->profileSpecs[profileIndex].renderingIntent = kUseProfileIntent;
        profileSet->profileSpecs[profileIndex].transformTag = kPCSToDevice;
        profileSet->profileSpecs[profileIndex].profile = (CMProfileRef)[profile performSelector:componentSelector];
    }

    NCWConcatColorWorld(&result, profileSet, NULL, NULL);
    return result;
}
#endif

- (void *)_rgbConversionWorldForOutput:(OAColorProfile *)aProfile;
{
#if OA_USE_COLOR_MANAGER
    CMWorldRef *colorWorld = (CMWorldRef *)[self _cachedRGBColorWorldForOutput:aProfile];

    if (!*colorWorld)  
        *colorWorld = [self _colorWorldForOutput:aProfile componentSelector:@selector(_rgbProfile)];
    return *colorWorld;
#else
    OBFinishPorting;
#endif
}

- (void *)_cmykConversionWorldForOutput:(OAColorProfile *)aProfile;
{
#if OA_USE_COLOR_MANAGER
    CMWorldRef *colorWorld = (CMWorldRef *)[self _cachedCMYKColorWorldForOutput:aProfile];

    if (!*colorWorld)  
        *colorWorld = [self _colorWorldForOutput:aProfile componentSelector:@selector(_cmykProfile)];
    return *colorWorld;
#else
    OBFinishPorting;
#endif
}

- (void *)_grayConversionWorldForOutput:(OAColorProfile *)aProfile;
{
#if OA_USE_COLOR_MANAGER
    CMWorldRef *colorWorld = (CMWorldRef *)[self _cachedGrayColorWorldForOutput:aProfile];

    if (!*colorWorld)  
        *colorWorld = [self _colorWorldForOutput:aProfile componentSelector:@selector(_grayProfile)];
    return *colorWorld;
#else
    OBFinishPorting;
#endif
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone;
{
    OBPRECONDITION(!isMutable); // Superclass does something funky otherwise.
    return [self retain];
}

@end
