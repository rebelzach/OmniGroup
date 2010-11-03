// Copyright 2008-2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "ODOTestCase.h"

RCS_ID("$Id$")

@interface ODOUndoTests : ODOTestCase
@end

@implementation ODOUndoTests

- (void)testUndo;
{
    NSError *error = nil;
    
    MASTER(master);

    OBShouldNotError([self save:&error]);
    
    DETAIL(detail, master);
    
    OBShouldNotError([self save:&error]);
    
    // Should undo the insertion of the detail and relationship between it and the master
    [_undoManager undo];
    should([_undoManager groupingLevel] == 0);

    should([master.details count] == 0);
}

// These ends up checking that the snapshots recorded in the undo manager don't end up resurrecting deleted objects when we undo a delete by doing an 'insert with snapshot'
- (void)testUndoOfDeleteWithToOneRelationship;
{
    NSError *error = nil;
    
    MASTER(master);
    ODOObjectID *masterID = [[[master objectID] copy] autorelease];

    DETAIL(detail, master);
    ODOObjectID *detailID = [[[detail objectID] copy] autorelease];

    OBShouldNotError([self save:&error]);
    
    // Now, delete the master, which should cascade to the detail
    OBShouldNotError([_editingContext deleteObject:master error:&error]);
    should([detail isDeleted]);
    
    // Close the group and finalize the deletion by saving, making the objects invalidated
    OBShouldNotError([self save:&error]);
    
    // Undo the delete; there should now be two objects registered with the right object IDs.
    [_undoManager undo];
    should([_undoManager groupingLevel] == 0);
    
    should([[_editingContext registeredObjectByID] count] == 2);
    should([_editingContext objectRegisteredForID:masterID] != nil);
    should([_editingContext objectRegisteredForID:detailID] != nil);
}

- (void)testClearingEmptyToManyAfterRedo_unconnected;
{    
    MASTER(master);
    ODOObjectID *masterID = [[master objectID] copy];

    [self closeUndoGroup];
    [_undoManager undo];
    
    [_undoManager redo];
    
    // Re-find master after it got deleted and reinserted
    master = (ODOTestCaseMaster *)[_editingContext objectRegisteredForID:masterID];
    [masterID release];
    should(master != nil);
    
    // Crashed prior to the fix
    should([master isInserted]);
    should(master.details != nil);
    should([master.details count] == 0);
}

@end

