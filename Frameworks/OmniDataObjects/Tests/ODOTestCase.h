// Copyright 2008-2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#define STEnableDeprecatedAssertionMacros
#import "OFTestCase.h"

#import <OmniBase/rcsid.h>
#import <OmniBase/OBUtilities.h>
#import <OmniBase/NSError-OBExtensions.h>

#import "ODOTestCaseModel.h"

@interface ODOTestCase : OFTestCase
{
    NSString *_databasePath;
    ODODatabase *_database;
    NSUndoManager *_undoManager;
    ODOEditingContext *_editingContext;
}

- (void)closeUndoGroup;
- (BOOL)save:(NSError **)outError;

@end

@interface ODOTestCaseObject : ODOObject
@end

@interface ODOTestCaseMaster : ODOTestCaseObject
@end
#import "ODOTestCaseMaster-ODOTestCaseProperties.h"
@interface ODOTestCaseDetail : ODOTestCaseObject
@end
#import "ODOTestCaseDetail-ODOTestCaseProperties.h"
@interface ODOTestCaseAllAttributeTypes : ODOTestCaseObject
@end
#import "ODOTestCaseAllAttributeTypes-ODOTestCaseProperties.h"

@interface ODOTestCaseLeftHand : ODOTestCaseObject
@end
#import "ODOTestCaseLeftHand-ODOTestCaseProperties.h"

@interface ODOTestCaseRightHand : ODOTestCaseObject
@end
#import "ODOTestCaseRightHand-ODOTestCaseProperties.h"

@interface ODOTestCaseLeftHandRequired : ODOTestCaseObject
@end
#import "ODOTestCaseLeftHandRequired-ODOTestCaseProperties.h"

@interface ODOTestCaseRightHandRequired : ODOTestCaseObject
@end
#import "ODOTestCaseRightHandRequired-ODOTestCaseProperties.h"

static inline id _insertTestObject(ODOEditingContext *ctx, Class cls, NSString *entityName, NSString *pk)
{
    OBPRECONDITION(ctx);
    OBPRECONDITION(cls);
    OBPRECONDITION(entityName);
    ODOObject *object = [[cls alloc] initWithEditingContext:ctx entity:[ODOTestCaseModel() entityNamed:entityName] primaryKey:pk];
    [ctx insertObject:object];
    [object release];
    return object;
}
#define INSERT_TEST_OBJECT(cls, name) cls *name = _insertTestObject(_editingContext, [cls class], cls ## EntityName, (NSString *)CFSTR(#name)); OB_UNUSED_VALUE(name)
#define MASTER(x) INSERT_TEST_OBJECT(ODOTestCaseMaster, x)

static inline ODOTestCaseDetail *_insertDetail(ODOEditingContext *ctx, NSString *pk, ODOTestCaseMaster *master)
{
    ODOTestCaseDetail *detail = [[ODOTestCaseDetail alloc] initWithEditingContext:ctx entity:[ODOTestCaseModel() entityNamed:ODOTestCaseDetailEntityName] primaryKey:pk];
    [ctx insertObject:detail];
    [detail release];
    
    if (master)
        detail.master = master;
    
    return detail;
}
#define DETAIL(x,master) ODOTestCaseDetail *x = _insertDetail(_editingContext, (NSString *)CFSTR(#x), master); OB_UNUSED_VALUE(x)

#define NoMaster (nil)

