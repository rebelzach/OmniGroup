// Copyright 2008, 2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <OmniDataObjects/ODOPredicate.h>

@class ODOEntity;

@interface NSPredicate (ODO_SQL)
- (BOOL)_appendSQL:(NSMutableString *)sql entity:(ODOEntity *)entity constants:(NSMutableArray *)constants error:(NSError **)outError;
@end
@interface NSExpression (ODO_SQL)
- (BOOL)_appendSQL:(NSMutableString *)sql entity:(ODOEntity *)entity constants:(NSMutableArray *)constants error:(NSError **)outError;
@end

__private_extern__ const char * const ODOComparisonPredicateStartsWithFunctionName;
__private_extern__ const char * const ODOComparisonPredicateContainsFunctionName;
