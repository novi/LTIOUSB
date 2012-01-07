//
//  LTIOAppDelegate.m
//  LTIOUSB
//
//  Created by 伊藤 祐輔 on 12/01/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
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
    
    [dicts addObject:[LTIOUSBManager matchingDictionaryForAllUSBDevicesWithObjectBaseClass:[LTIOUSBDevice class]] ];
    [dicts addObject:[LTIOUSBManager matchingDictionaryForProductID:0x1312 vendorID:0x10c4 objectBaseClass:[LTIOUSBDevice class]] ];
    
    [[LTIOUSBManager sharedInstance] startWithMatchingDictionaries:dicts];
    
}

@end