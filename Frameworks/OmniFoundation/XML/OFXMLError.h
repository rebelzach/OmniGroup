// Copyright 2003-2005, 2007-2010 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.
//
// $Id$

#import <libxml/parser.h>
#import <libxml/xmlerror.h>
#import <OmniBase/objc.h>

@class NSError;

// Returns nil if the error should be ignored.
__private_extern__ NSError *OFXMLCreateError(xmlErrorPtr error) NS_RETURNS_RETAINED;
