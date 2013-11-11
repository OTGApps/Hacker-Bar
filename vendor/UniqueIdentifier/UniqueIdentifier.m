
#import <IOKit/IOKitLib.h>
#import <WebKit/WebKit.h>

#if !__has_feature(objc_arc)
#error Need automatic reference counting to compile this.
#endif

#import "UniqueIdentifier.h"

// ---
@implementation UniqueIdentifier

-(NSString *)uniqueIdentifier
{
        // http://stackoverflow.com/questions/5868567/unique-identifier-of-a-mac
    io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));
    CFStringRef serialNumberAsCFString = NULL;
    if (platformExpert) {
        serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, CFSTR(kIOPlatformSerialNumberKey), kCFAllocatorDefault, 0);
        IOObjectRelease(platformExpert);
    }

    NSString *serialNumberAsNSString = nil;
    if (serialNumberAsCFString) {
        serialNumberAsNSString = [NSString stringWithString:(__bridge NSString *)serialNumberAsCFString];
        CFRelease(serialNumberAsCFString);
    }

    if (!serialNumberAsNSString) {
        NSHost* host = [NSHost currentHost];
        serialNumberAsNSString = [[host name] copy];
    }
    if (serialNumberAsNSString.length == 0) {
        serialNumberAsNSString = @"(unknown)";
    }
    return serialNumberAsNSString;
}

@end
