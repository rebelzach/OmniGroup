// Copyright 2001-2011 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OSUPreferenceClient.h"

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <OmniBase/OmniBase.h>
#import <OmniFoundation/OmniFoundation.h>
#import <OmniAppKit/OmniAppKit.h>
#import <mach-o/arch.h>
#import <WebKit/WebKit.h>

#import "OSUPreferences.h"
#import "OSUController.h"
#import "OSUChecker.h"
#import "OSUItem.h"
#import "OSUCheckOperation.h"

RCS_ID("$Id$");

typedef enum { Daily, Weekly, Monthly } CheckFrequencyMark;

@interface OSUPreferenceClient (Private)
- (void)_systemConfigurationSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@implementation OSUPreferenceClient

- (void)awakeFromNib;
{
    // Format the informational message in the window based on the original format string stored in the nib
    NSString *format = [infoTextField stringValue];
    NSString *processName = [[NSProcessInfo processInfo] processName];
    NSString *value = [NSString stringWithFormat:format, processName, processName];
    [infoTextField setStringValue:value];

    [super awakeFromNib];
}    

- (void)willBecomeCurrentPreferenceClient;
{
    if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
        [self queueSelector:@selector(checkNow:) withObject:nil];
}

- (void)updateUI;
{
    NSInteger checkFrequencyInDays, itemIndexToSelect;
    
    [enableButton setState:[[OSUPreferences automaticSoftwareUpdateCheckEnabled] boolValue]];
    checkFrequencyInDays = [[OSUPreferences checkInterval] integerValue] / 24;

    if (checkFrequencyInDays > 27)
        itemIndexToSelect = [frequencyPopup indexOfItemWithTag:Monthly];
    else if (checkFrequencyInDays > 6)
        itemIndexToSelect = [frequencyPopup indexOfItemWithTag:Weekly];
    else
        itemIndexToSelect = [frequencyPopup indexOfItemWithTag:Daily];
    [frequencyPopup selectItemAtIndex:itemIndexToSelect];

    [includeHardwareButton setState:[[OSUPreferences includeHardwareDetails] boolValue]];
}

- (IBAction)setValueForSender:(id)sender;
{
    if (sender == enableButton) {
        [[OSUPreferences automaticSoftwareUpdateCheckEnabled] setBoolValue:[enableButton state]];
    } else if (sender == frequencyPopup) {
        int checkFrequencyInHours;
        
        switch ([[sender selectedItem] tag]) {
            case Daily:
                checkFrequencyInHours = 24;
                break;
            default:
            case Weekly:
                checkFrequencyInHours = 24 * 7;
                break;
            case Monthly:
                checkFrequencyInHours = 24 * 28; // lunar months! or would some average days per month figure be better?
                break;
        }
        [[OSUPreferences checkInterval] setIntegerValue:checkFrequencyInHours];
    } else if (sender == includeHardwareButton) {
        [[OSUPreferences includeHardwareDetails] setBoolValue:[includeHardwareButton state]];
    }
}

// API

- (IBAction)checkNow:(id)sender;
{
    [OSUController checkSynchronouslyWithUIAttachedToWindow:[[self controlBox] window]];
}

static NSString *formatAngle(NSString *value, NSString *positive, NSString *negative)
{
    double degrees, minutes, seconds;
    NSString *directional;
    
    degrees = [value doubleValue];
    if (degrees >= 0)
        directional = positive;
    else {
        degrees = -degrees;
        directional = negative;
    }
    minutes = 60 * modf(degrees, &degrees);
    seconds = 60 * modf(minutes, &minutes);
    
    return [NSString stringWithFormat:@"%.0f&#176;&nbsp;%.0f&#8242;&nbsp;%.0f&#8243;&nbsp;%@", degrees, minutes, seconds, directional];
}

- (IBAction)showSystemConfigurationDetailsSheet:(id)sender;
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"HardwareDescription" ofType:@"html"];
    if (!path) {
#ifdef DEBUG    
        NSLog(@"Cannot find HardwareDescription.html");
#endif	
        return;
    }
    
    NSData *htmlData = [[NSData alloc] initWithContentsOfFile:path];
    if (!htmlData) {
#ifdef DEBUG    
        NSLog(@"Cannot load HardwareDescription.html");
#endif	
        return;
    }

    // We have to do the variable replacement on the string since the tables in the HTML will get replaced with attachment cells
    NSMutableString *htmlString = [[[NSMutableString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding] autorelease];
    [htmlData release];

    // Get the system configuration report
    OSUChecker *checker = [OSUChecker sharedUpdateChecker];
    NSDictionary *_report = [checker generateReport];
    if (!_report) {
#ifdef DEBUG    
        NSLog(@"Couldn't generate report");
#endif	
        return;
    }

    NSMutableDictionary *report = [[[_report objectForKey:OSUReportResultsInfoKey] mutableCopy] autorelease];
    
    // Do variable replacement on the HTML text
    {
        NSUInteger length = [htmlString length];
        NSRange keyRange = (NSRange){0,0};

        while (YES) {
            keyRange.location = [htmlString rangeOfString:@"${" options:0 range:(NSRange){keyRange.location, length - keyRange.location}].location;
            if (keyRange.location == NSNotFound)
                break;

            keyRange.location += 2;
            NSUInteger end = [htmlString rangeOfString:@"}" options:0 range:(NSRange){keyRange.location, length - keyRange.location}].location;
            keyRange.length = end - keyRange.location;
            
            NSString *key = [htmlString substringWithRange:keyRange];

            OSUChecker *checker = [OSUChecker sharedUpdateChecker];
            
            NSString *replacement = [[[report objectForKey:key] retain] autorelease];
            [report removeObjectForKey:key];
            
	    if ([key isEqualToString:@"OSU_VER"]) {
		replacement = [[OSUChecker OSUVersionNumber] originalVersionString];
            } else if ([key isEqualToString:@"OSU_APP_ID"]) {
                replacement = [checker applicationIdentifier];
            } else if ([key isEqualToString:@"OSU_APP_VER"]) {
                replacement = [checker applicationEngineeringVersion];
            } else if ([key isEqualToString:@"OSU_TRACK"]) {
                replacement = [checker applicationTrack];
            } else if ([key isEqualToString:@"OSU_VISIBLE_TRACKS"]) {
                replacement = [[OSUPreferences visibleTracks] componentsJoinedByString:@", "];
            } else if ([key isEqualToString:@"APP"]) {
                replacement = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
	    } else if ([key isEqualToString:@"license-type"]) {
		// This should be in the *main* bundle
		replacement = [[NSBundle mainBundle] localizedStringForKey:replacement value:replacement table:@"OZLicenseType"];
	    } else if ([key isEqualToString:@"lang"]) {
		NSString *localizedName = OFLocalizedNameForISOLanguageCode(replacement);
		if (localizedName)
		    replacement = localizedName;
	    } else if ([key isEqualToString:@"LATITUDE"]) {
		NSString *loc = [report objectForKey:@"loc"];
		NSArray *elements = [loc componentsSeparatedByString:@","];
		if ([elements count] == 2)
		    replacement = [elements objectAtIndex:0];
	    } else if ([key isEqualToString:@"LATITUDE-DMS"]) {
		NSString *loc = [report objectForKey:@"loc"];
		NSArray *elements = [loc componentsSeparatedByString:@","];
		if ([elements count] == 2)
		    replacement = formatAngle([elements objectAtIndex:0], @"N", @"S");
	    } else if ([key isEqualToString:@"LONGITUDE"]) {
		NSString *loc = [report objectForKey:@"loc"];
		NSArray *elements = [loc componentsSeparatedByString:@","];
		if ([elements count] == 2)
		    replacement = [elements objectAtIndex:1];
	    } else if ([key isEqualToString:@"LONGITUDE-DMS"]) {
		NSString *loc = [report objectForKey:@"loc"];
		NSArray *elements = [loc componentsSeparatedByString:@","];
		if ([elements count] == 2)
		    replacement = formatAngle([elements objectAtIndex:1], @"E", @"W");
	    } else if ([key isEqualToString:@"cpu"]) {
		NSArray *elements = [replacement componentsSeparatedByString:@","];
		if ([elements count] == 2) {
		    const NXArchInfo *archInfo = NXGetArchInfoFromCpuType([[elements objectAtIndex:0] intValue],
									  [[elements objectAtIndex:1] intValue]);
		    if (archInfo)
			replacement = [NSString stringWithCString:archInfo->description encoding:NSASCIIStringEncoding];
		}
	    } else if ([key isEqualToString:@"cpuhz"] || [key isEqualToString:@"bushz"]) {
                NSDecimalNumber *bytes = [NSDecimalNumber decimalNumberWithString:replacement];
                replacement = [NSString abbreviatedStringForHertz:[bytes unsignedLongLongValue]];
	    } else if ([key isEqualToString:@"mem"]) {
                if ([replacement isEqualToString:@"-2147483648"]) {
                    // See the check tool -- sysctl blow up here.
                    replacement = @">= 2GB";
                } else {
                    NSDecimalNumber *bytes = [NSDecimalNumber decimalNumberWithString:replacement];
                    replacement = [NSString abbreviatedStringForBytes:[bytes unsignedLongLongValue]];
                }
	    } else if ([key isEqualToString:@"DISPLAYS"]) {
		NSMutableString *displays = [NSMutableString string];

		unsigned int displayIndex = 0;
		while (YES) {
		    NSString *displayKey = [NSString stringWithFormat:@"display%d", displayIndex];
		    NSString *displayInfo = [report objectForKey:displayKey];
		    if (!displayInfo)
			break;
		    if ([displays length])
			[displays appendString:@"<br>"];
		    [displays appendString:displayInfo];
                    if ([displays length])
                        [displays appendString:@"<br>"];
		    [report removeObjectForKey:displayKey];

                    NSString *quartzExtremeKey = [NSString stringWithFormat:@"qe%d", displayIndex];
                    NSString *quartzExtreme = [report objectForKey:quartzExtremeKey];
                    if ([@"1" isEqualToString:quartzExtreme])
                        [displays appendString:NSLocalizedStringFromTableInBundle(@"Quartz Extreme Enabled", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel value - shown if Quartz Extreme is enabled")];
                    else if ([@"0" isEqualToString:quartzExtreme])
                        [displays appendString:NSLocalizedStringFromTableInBundle(@"Quartz Extreme Disabled", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel value - shown if Quartz Extreme is not enabled")];
                    else {
                        OBASSERT(NO);
                    }
                    if ([displays length])
                        [displays appendString:@"<br>"];
                    [report removeObjectForKey:quartzExtremeKey];

		    displayIndex++;
		}
		replacement = displays;
	    } else if ([key isEqualToString:@"VIDEO"]) {
		NSMutableString *adaptors = [NSMutableString string];

		// We only record the name of the first adaptor for now
		NSString *adaptorName = [report objectForKey:@"adaptor0_name"];
		if (adaptorName) {
		    static BOOL firstTime = YES;
		    static NSBundle *displayNamesBundle = nil;
		    if (firstTime) {
			firstTime = NO;
			displayNamesBundle = [[NSBundle bundleWithPath:@"/System/Library/SystemProfiler/SPDisplaysReporter.spreporter"] retain];
		    }
		    
		    if (displayNamesBundle)
			adaptorName = [displayNamesBundle localizedStringForKey:adaptorName value:adaptorName table:@"Localizable"];
		    [adaptors appendFormat:@"%@", adaptorName];
		    [report removeObjectForKey:@"adaptor0_name"];
		}
		
		unsigned int adaptorIndex = 0;
		while (YES) {
		    NSString *pciKey   = [NSString stringWithFormat:@"accel%d_pci", adaptorIndex];
		    NSString *glKey    = [NSString stringWithFormat:@"accel%d_gl", adaptorIndex];
		    NSString *identKey = [NSString stringWithFormat:@"accel%d_id", adaptorIndex];
		    NSString *verKey   = [NSString stringWithFormat:@"accel%d_ver", adaptorIndex];
		    
		    NSString *pci, *gl, *ident, *ver;
		    pci   = [report objectForKey:pciKey];
		    gl    = [report objectForKey:glKey];
		    ident = [report objectForKey:identKey];
		    ver   = [report objectForKey:verKey];
		    
		    if (!pci && !gl && !ident && !ver)
			break;
		    
		    if ([adaptors length])
			[adaptors appendString:@"<br><br>"];
		    
		    [adaptors appendString:NSLocalizedStringFromTableInBundle(@"PCI ID", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - PCI bus ID of video card")];
		    [adaptors appendFormat:@": %@<br>", pci ?: @""];
		    [adaptors appendString:NSLocalizedStringFromTableInBundle(@"OpenGL Driver", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - name of the OpenGL driver")];
		    [adaptors appendFormat:@": %@<br>", gl ?: @""];
		    [adaptors appendString:NSLocalizedStringFromTableInBundle(@"Hardware Driver", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - name of video card driver")];
		    [adaptors appendFormat:@": %@<br>", ident ?: @""];
		    [adaptors appendString:NSLocalizedStringFromTableInBundle(@"Driver Version", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - version of video card driver")];
		    [adaptors appendFormat:@": %@", ver ?: @""];

		    [report removeObjectForKey:pciKey];
		    [report removeObjectForKey:glKey];
		    [report removeObjectForKey:identKey];
		    [report removeObjectForKey:verKey];
		    adaptorIndex++;
		}
		
		NSString *memString = [report objectForKey:@"accel_mem"];
		if (memString) {
		    [adaptors appendString:@"<br>"];
		    if (adaptorIndex == 1) {
			[adaptors appendString:NSLocalizedStringFromTableInBundle(@"Memory", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - amount of video memory installed")];
			[adaptors appendString:@": "];
		    } else
			[adaptors appendString:@"<br>"];
		    
		    NSArray *mems = [memString componentsSeparatedByString:@","];
		    NSUInteger memIndex, memCount = [mems count];
		    for (memIndex = 0; memIndex < memCount; memIndex++) {
			if (memIndex)
			    [adaptors appendString:@", "];
			[adaptors appendString:[NSString abbreviatedStringForBytes:[[mems objectAtIndex:memIndex] intValue]]];
		    }
		    [report removeObjectForKey:@"accel_mem"];
		}


		replacement = adaptors;
            } else if ([key isEqualToString:@"OPENGL"]) {
                NSMutableString *glInfo = [NSMutableString string];

                unsigned int adaptorIndex = 0;
                while (YES) {
                    NSString *vendorKey     = [NSString stringWithFormat:@"gl_vendor%d", adaptorIndex];
                    NSString *rendererKey   = [NSString stringWithFormat:@"gl_renderer%d", adaptorIndex];
                    NSString *versionKey    = [NSString stringWithFormat:@"gl_version%d", adaptorIndex];
                    NSString *extensionsKey = [NSString stringWithFormat:@"gl_extensions%d", adaptorIndex];

                    NSString *vendor, *renderer, *version, *extensions;
                    vendor     = [report objectForKey:vendorKey];
                    renderer   = [report objectForKey:rendererKey];
                    version    = [report objectForKey:versionKey];
                    extensions = [report objectForKey:extensionsKey];

                    if (!vendor && !renderer && !version && !extensions)
                        break;

                    if ([glInfo length])
                        [glInfo appendString:@"<br><br>"];

		    [glInfo appendString:NSLocalizedStringFromTableInBundle(@"OpenGL Vendor", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string")];
                    [glInfo appendFormat:@": %@<br>", vendor ?: @""];
		    [glInfo appendString:NSLocalizedStringFromTableInBundle(@"OpenGL Renderer", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string")];
                    [glInfo appendFormat:@": %@<br>", renderer ?: @""];
		    [glInfo appendString:NSLocalizedStringFromTableInBundle(@"OpenGL Version", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string")];
                    [glInfo appendFormat:@": %@<br>", version ?: @""];
		    [glInfo appendString:NSLocalizedStringFromTableInBundle(@"OpenGL Extensions", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string")];
                    [glInfo appendFormat:@": %@<br>", extensions ?: @""];

                    [report removeObjectForKey:vendorKey];
                    [report removeObjectForKey:rendererKey];
                    [report removeObjectForKey:versionKey];
                    [report removeObjectForKey:extensionsKey];
                    adaptorIndex++;
                }

                replacement = glInfo;
            } else if ([key isEqualToString:@"OPENCL"]) {
                NSMutableString *clInfo = [NSMutableString string];
                
                unsigned int clPlatformIndex = 0;
                for(;;) {
                    NSString *platInfoKey = [NSString stringWithFormat:@"cl%u", clPlatformIndex];
                    NSString *platExtKey = [platInfoKey stringByAppendingString:@"_ext"];
                    NSString *platInfo = [report objectForKey:platInfoKey];
                    NSString *platExt = [report objectForKey:platExtKey];
                    
                    if (!platInfo && !platExt)
                        break;
                    
                    [report removeObjectForKey:platInfoKey];
                    [report removeObjectForKey:platExtKey];
                    
                    [clInfo appendString:@"<tr><td colspan=\"8\">"];
                    [clInfo appendString:platInfo];
                    if (![NSString isEmptyString:platExt]) {
                        NSString *extLabel = NSLocalizedStringFromTableInBundle(@"Extensions", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - list of OpenCL platform extensions");
                        [clInfo appendFormat:@"<br>%@: %@", extLabel, platExt];
                    }
                    [clInfo appendString:@"</td></tr>"];
                    
                    NSMutableString *clDeviceInfo = [NSMutableString string];

                    unsigned int clDeviceIndex = 0;
                    for(;;) {
                        NSString *devInfoKey = [NSString stringWithFormat:@"cl%u.%u_dev", clPlatformIndex, clDeviceIndex];
                        NSString *devInfo = [report objectForKey:devInfoKey];
                        if (!devInfo)
                            break;
                        [report removeObjectForKey:devInfoKey];
                        NSArray *parts = [devInfo componentsSeparatedByString:@" " maximum:5];
                        
                        [clDeviceInfo appendFormat:@"<tr><td>%@</td><td>%@</td><td>%@</td>",
                         [parts objectAtIndex:0],  // Device type
                         [parts objectAtIndex:1],  // Number of cores
                         [NSString abbreviatedStringForHertz:1048576*[[parts objectAtIndex:2] unsignedLongLongValue]] // Freq
                         ];
                        OFForEachInArray([[parts objectAtIndex:3] componentsSeparatedByString:@"/"], NSString *, mem, {
                            ([clDeviceInfo appendFormat:@"<td>%@</td>", [NSString abbreviatedStringForBytes:1024*[mem unsignedLongLongValue]]]);
                        });
                        [clDeviceInfo appendFormat:@"<td>%@</td></tr>", [parts objectAtIndex:4]];

                        clDeviceIndex ++;
                    }
                    if (clDeviceIndex != 0) {
                        NSString *typeHeader = NSLocalizedStringFromTableInBundle(@"Type", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - column header for OpenCL device type");
                        NSString *unitsHeader = NSLocalizedStringFromTableInBundle(@"Units", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - column header for OpenCL device processing-unit count");
                        NSString *freqHeader = NSLocalizedStringFromTableInBundle(@"Freq.", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - column header for OpenCL device core frequency");
                        NSString *memHeader = NSLocalizedStringFromTableInBundle(@"Memory", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - column header for OpenCL device memory sizes");
                        NSString *extHeader = NSLocalizedStringFromTableInBundle(@"Exts", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - column header for OpenCL device extensions");
                        [clInfo appendFormat:@"<tr><td rowspan=\"%u\">&nbsp;&nbsp;</td><th>%@</th><th>%@</th><th>%@</th><th colspan=\"3\">%@</th><th>%@</th></tr>%@",
                         1 + clDeviceIndex,
                         typeHeader, unitsHeader, freqHeader, memHeader, extHeader,
                         clDeviceInfo];
                    }
                    
                    clPlatformIndex ++;
                }
                
                [clInfo insertString:@"<table class=\"subtable\">" atIndex:0];
                [clInfo appendString:@"</table>"];
                replacement = clInfo;
            } else if ([key isEqualToString:@"runmin"] || [key isEqualToString:@"trunmin"]) {
                replacement = [NSString stringWithFormat:@"%.1f", [replacement unsignedIntValue]/60.0];
            } else if ([key isEqualToString:@"RUNTIME-Hours"]) {
                replacement = NSLocalizedStringFromTableInBundle(@"Hours Run", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - accumulated number of hours the program has been running");
            } else if ([key isEqualToString:@"RUNTIME-Launches"]) {
                replacement = NSLocalizedStringFromTableInBundle(@"# of Launches", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - number of times the program has been launched");
            } else if ([key isEqualToString:@"RUNTIME-Crashes"]) {
                replacement = NSLocalizedStringFromTableInBundle(@"# of Crashes", @"OmniSoftwareUpdate", OMNI_BUNDLE, @"details panel string - number of times the program has crashed");
            } else if ([key isEqualToString:@"OTHERVARS"]) {
                NSMutableString *rows = [NSMutableString string];
                OFForEachObject([report keyEnumerator], NSString *, aVar) {
                    if (![aVar isEqualToString:@"loc"])
                        [rows appendFormat:@"<tr><th>%@</th><td>%@</td></tr>", aVar, [report objectForKey:aVar]];
                }
                replacement = rows;
            }
            
	    
            if (replacement) {
                // Expand the range to over the '${}'
                keyRange.location -= 2;
                keyRange.length   += 3;
                [htmlString replaceCharactersInRange:keyRange withString:replacement];
                keyRange.location += [replacement length];
		length = [htmlString length];
            }
        }

	[report removeObjectForKey:@"loc"]; // Gets handled by the synthetic LATITUDE and LONGITUDE keys
        if ([report count]) {
            NSLog(@"Unhandled keys: %@", report);
            OBASSERT(NO);
        }
    }
    
    [[systemConfigurationWebView mainFrame] loadHTMLString:htmlString baseURL:nil];
    [NSApp beginSheet:[systemConfigurationWebView window]
       modalForWindow:[[self controlBox] window]
        modalDelegate:self
       didEndSelector:@selector(_systemConfigurationSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (IBAction)dismissSystemConfigurationDetailsSheet:(id)sender;
{
    [NSApp endSheet:[systemConfigurationWebView window]];
}

#pragma mark -
#pragma mark WebPolicyDelegate

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
	request:(NSURLRequest *)request
	  frame:(WebFrame *)frame
decisionListener:(id<WebPolicyDecisionListener>)listener;
{
    NSURL *url = [actionInformation objectForKey:WebActionOriginalURLKey];
    
    // about:blank is passed when loading the initial content
    if ([[url absoluteString] isEqualToString:@"about:blank"]) {
	[listener use];
	return;
    }
    
    // when a link is clicked reject it locally and open it in an external browser
    if ([[actionInformation objectForKey:WebActionNavigationTypeKey] intValue] == WebNavigationTypeLinkClicked) {
	[[NSWorkspace sharedWorkspace] openURL:url];
	[listener ignore];
	return;
    }

#ifdef DEBUG
    NSLog(@"action %@, request %@", actionInformation, request);
#endif
}

- (void)webView:(WebView *)webView unableToImplementPolicyWithError:(NSError *)error frame:(WebFrame *)frame;
{
#ifdef DEBUG
    NSLog(@"error %@", error);
#endif    
}

@end

@implementation OSUPreferenceClient (Private)
- (void)_systemConfigurationSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    [sheet orderOut:nil];
}
@end
