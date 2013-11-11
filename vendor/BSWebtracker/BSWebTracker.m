//
//  BSWebTracker.m
//  WebTracker
//
//  Created by Sasmito Adibowo on 27-04-13.
//  Copyright (c) 2013 Basil Salad Software. All rights reserved.
//  http://basilsalad.com
//
//  Licensed under the BSD License <http://www.opensource.org/licenses/bsd-license>
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
//  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
//  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <IOKit/IOKitLib.h>
#import <WebKit/WebKit.h>

#if !__has_feature(objc_arc)
#error Need automatic reference counting to compile this.
#endif

#import "BSWebTracker.h"


@interface BSWebTracker ()

@property (nonatomic,strong,readonly) NSString* trackingMedium;

@property (nonatomic,strong,readonly) NSString* trackingSource;

@property (nonatomic,strong,readonly) WebView* webView;

@property (nonatomic,strong,readonly) NSMutableArray* trackerURLQueue;

@end

// ---

NSString* const BSWebTrackerFlushQueueNotification = @"com.basilsalad.BSWebTrackerFlushQueueNotification";

// ---
@implementation BSWebTracker

-(void) handleFlushQueue:(NSNotification*) notification
{
    NSMutableArray* queue = self.trackerURLQueue;
    if (queue.count > 0) {
        // allocate WebView when needed, because we need one.
        WebView* webView = self.webView;
        if ([webView isLoading]) {
            return; // webView is busy.
        }
        NSURL* url = [self dequeueURL];
        if (url) {
            NSURLRequest* request = [NSURLRequest requestWithURL:url];
            [webView.mainFrame loadRequest:request];
        }
    } else if (![_webView isLoading]) {
        // no more queued requests & web view isn't doing anything - clean up the web view
        [self cleanupWebView];
    }
}


-(void) notifyFlushQueue
{
    NSNotification* notification = [NSNotification notificationWithName:BSWebTrackerFlushQueueNotification object:self];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostWhenIdle];
}


-(void) queueURL:(NSURL*) url
{
    if (url) {
        [self.trackerURLQueue addObject:url];
        [self notifyFlushQueue];
    }
}


-(NSURL*) dequeueURL
{
    NSURL* url = nil;
    NSMutableArray* queue = self.trackerURLQueue;
    if (queue.count > 0) {
        url = queue[0];
        [queue removeObjectAtIndex:0];
    }
    return url;
}


-(void) cleanupWebView
{
    // Comment this out since it prevents calls from actually working after the first time.
    // if (_webView) {
    //     _webView.frameLoadDelegate = nil;
    //     [_webView stopLoading:nil];
    //     _webView = nil;
    // }
}


-(void) trackName:(NSString*) campaignName content:(NSString*) campaignContent term:(NSString*) campaignTerm
{
    NSString* trackerURLString = self.trackerURLString;
    if (!trackerURLString) {
        return;
    }
    if (campaignName.length == 0) {
        // campaign name is required. So we just plug in a default here.
        campaignName = @"(none)";
    }
    NSMutableString* urlString = [NSMutableString stringWithFormat:@"%@?utm_source=%@&utm_medium=%@&utm_campaign=%@",trackerURLString,[self.trackingSource stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],[self.trackingMedium stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],[campaignName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if (campaignContent.length > 0) {
        [urlString appendFormat:@"&utm_content=%@",[campaignContent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    if (campaignTerm.length > 0) {
        [urlString appendFormat:@"&utm_term=%@",[campaignTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }

    NSURL* url = [NSURL URLWithString:urlString];
    [self queueURL:url];
}


-(void) retryAfterFailure
{
    // TODO: handle reachability, sleep/wake, etc – make it more resilient
    BSWebTracker __weak* weakSelf = self;
    [[NSOperationQueue mainQueue] performSelector:@selector(addOperationWithBlock:) withObject:^{
        // wait for a while to give a chance for network adaptor, etc to get connectivity
        // this won't do anything if the object is already deallocated.
        [weakSelf notifyFlushQueue];
    } afterDelay:10];
}


#pragma mark NSObject

-(id)init
{
    if ((self = [super init])) {
        NSNotificationCenter* defaultNC = [NSNotificationCenter defaultCenter];
        [defaultNC addObserver:self selector:@selector(handleFlushQueue:) name:BSWebTrackerFlushQueueNotification object:self];
    }
    return self;
}


-(void)dealloc
{
    [self cleanupWebView];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Property Access

// tracking medium is the machine

@synthesize trackingMedium = _trackingMedium;

-(NSString *)trackingMedium
{
    if (!_trackingMedium) {
        // http://stackoverflow.com/questions/5868567/unique-identifier-of-a-mac
        io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));
        CFStringRef serialNumberAsCFString = NULL;
        if (platformExpert) {
            serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,
                                                                     CFSTR(kIOPlatformSerialNumberKey),
                                                                     kCFAllocatorDefault, 0);
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
        _trackingMedium = serialNumberAsNSString;
    }
    return _trackingMedium;
}


// tracking source is the main app's bundle ID

@synthesize trackingSource = _trackingSource;

-(NSString *)trackingSource
{
    if (!_trackingSource) {
        NSBundle* mainBundle = [NSBundle mainBundle];
        NSDictionary* infoDictionary = mainBundle.infoDictionary;
        _trackingSource = [NSString stringWithFormat:@"%@ (%@)",infoDictionary[(__bridge id) kCFBundleIdentifierKey],infoDictionary[(__bridge id)kCFBundleVersionKey]];
    }
    return _trackingSource;
}


@synthesize webView = _webView;

-(WebView *)webView
{
    if (!_webView) {
        _webView = [[WebView alloc] initWithFrame:NSMakeRect(0, 0, 320, 200) frameName:nil groupName:nil];
        _webView.frameLoadDelegate = self;
    }
    return _webView;
}


@synthesize trackerURLQueue = _trackerURLQueue;

-(NSMutableArray *)trackerURLQueue
{
    if (!_trackerURLQueue) {
        _trackerURLQueue = [NSMutableArray new];
    }
    return _trackerURLQueue;
}

#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)webView didStartProvisionalLoadForFrame:(WebFrame *)webFrame
{

}


- (void)webView:(WebView *)webView didFinishLoadForFrame:(WebFrame *)webFrame
{
    if (webFrame == webView.mainFrame) {
        // either handle more requests or cleanup the web view.
        [self notifyFlushQueue];
    }
}


- (void)webView:(WebView *)webView didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *) webFrame
{
    if (webFrame == webView.mainFrame) {
        [self retryAfterFailure];
    }
}

- (void)webView:(WebView *)webView didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)webFrame
{
    if (webFrame == webView.mainFrame) {
        [self retryAfterFailure];
    }
}

@end


