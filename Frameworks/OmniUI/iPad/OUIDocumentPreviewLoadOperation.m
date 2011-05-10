// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OUIDocumentPreviewLoadOperation.h"

#import <OmniUI/OUIDocumentProxy.h>
#import <OmniUI/OUIDocumentProxyView.h>

RCS_ID("$Id$");

@implementation OUIDocumentPreviewLoadOperation

- initWithProxy:(OUIDocumentProxy *)proxy size:(CGSize)size;
{
    if (!(self = [super init]))
        return nil;
    
    _proxy = [proxy retain];
    _size = size;
    
    return self;
}

- (void)dealloc;
{
    [_proxy release];
    [super dealloc];
}

- (void)main;
{
    OBPRECONDITION(![NSThread isMainThread]);
    
    NSError *error = nil;
        
#if 0 && defined(DEBUG)
    sleep(1);
#endif
    
    id <OUIDocumentPreview> preview = [[_proxy class] makePreviewFromURL:_proxy.url size:_size error:&error];
    if (!preview) {
        NSLog(@"Unable to load preview from %@: %@", _proxy.url, [error toPropertyList]);
        [_proxy performSelectorOnMainThread:@selector(previewDidLoad:) withObject:error waitUntilDone:NO];
        return;
    }
    
    [_proxy performSelectorOnMainThread:@selector(previewDidLoad:) withObject:preview waitUntilDone:NO];
}

@end
