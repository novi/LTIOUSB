//
//  LTIOAppDelegate.m
//  LTIOUSB
//

#import "LTIOAppDelegate.h"
#import "LTIOUSBManager.h"

@implementation LTIOAppDelegate

@synthesize window = _window;

- (void)_deviceAdded:(NSNotification*)notif
{
    NSLog(@"devices: \n%@", [[LTIOUSBManager sharedInstance] devices]);
    NSLog(@"%s: \n%@", __func__, notif.object);
}

- (void)_deviceDisconnected:(NSNotification*)notif
{
    NSLog(@"devices: \n%@", [[LTIOUSBManager sharedInstance] devices]);
    NSLog(@"%s: \n%@", __func__, notif.object);
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_deviceAdded:) name:LTIOUSBDeviceConnectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_deviceDisconnected:) name:LTIOUSBDeviceDisconnectedNotification object:nil];
    
    NSMutableArray* dicts = [NSMutableArray array];
    
    //[dicts addObject:[LTIOUSBManager matchingDictionaryForAllUSBDevicesWithObjectBaseClass:[LTIOUSBDevice class]] ];
    [dicts addObject:[LTIOUSBManager matchingDictionaryForProductID:0x1312 vendorID:0x10c4 objectBaseClass:[LTIOUSBDevice class]] ];
    
    [dicts addObject:[LTIOUSBManager matchingDictionaryForProductID:0x2707 vendorID:0x08bb objectBaseClass:[LTIOUSBDevice class]] ];
    
    [[LTIOUSBManager sharedInstance] startWithMatchingDictionaries:dicts];
    
}

- (IBAction)closeAll:(id)sender {
    for (LTIOUSBDevice* device in [[LTIOUSBManager sharedInstance] devices]) {
        [device closeDeviceInterface];
        [device closePluginInterface];
    }
}

- (IBAction)openAll:(id)sender {
    for (LTIOUSBDevice* device in [[LTIOUSBManager sharedInstance] devices]) {
        if ([device createPluginInterface]) {
            NSLog(@"createPluginInterface: %p", device.pluginInterface);
        }
        if ([device createDeviceInterface]) {
            // success
            NSLog(@"createDeviceInterface: %p", device.deviceInterface);
        }
        [device openDevice];
    }
}

- (IBAction)resetAll:(id)sender
{
    for (LTIOUSBDevice* device in [LTIOUSBManager sharedInstance].devices) {
        [device openDevice];
        [device resetDevice];
    }
}
@end
