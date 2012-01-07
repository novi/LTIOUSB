//
//  LTIOUSBManager.m
//  LTIOUSB
//
//  Created by 伊藤 祐輔 on 12/01/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "LTIOUSBManager.h"

#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOMessage.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/IOBSD.h>

#import "LTIOUSBDevice.h"

void _LTIOUSBDeviceAdded(void* context, io_iterator_t iterator);
void _LTIOUSBDeviceRemoved(void* context, io_iterator_t iterator);


NSString* const LTIOUSBDeviceConnectedNotification = @"LTIOUSBDeviceAddedNotification";
NSString* const LTIOUSBDeviceDisconnectedNotification = @"LTIOUSBDeviceRemovedNotification";
NSString* const LTIOUSBManagerObjectBaseClassKey = @"LTIOUSBManagerObjectBaseClassKey";

#pragma mark - Callbacks

// context: object base class string
void _LTIOUSBDeviceAdded(void* context, io_iterator_t iterator)
{
    LTIOUSBManager* manager = [LTIOUSBManager sharedInstance];
    Class objectClass = NSClassFromString((__bridge NSString*)context);
    
    io_service_t io_device = IO_OBJECT_NULL;
    
    NSMutableArray* addedDevices = [[NSMutableArray alloc] initWithCapacity:1];
	
	while((io_device = IOIteratorNext(iterator))) {
        NSString* identifier = [objectClass deviceIdentifier:io_device];
        LTIOUSBDevice* device = [manager deviceWithIdentifier:identifier];
        if (! device) {
            device = [[objectClass alloc] initWithIdentifier:identifier];
            [manager addDevice:device];
        }
        [device setDeviceConnectedWithDevice:io_device];
        [addedDevices addObject:device];
    }
    
    if (addedDevices.count) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LTIOUSBDeviceConnectedNotification object:addedDevices];
    }
}

void _LTIOUSBDeviceRemoved(void* context, io_iterator_t iterator)
{
    LTIOUSBManager* manager = [LTIOUSBManager sharedInstance];
    
    io_service_t io_device = IO_OBJECT_NULL;
    
    NSMutableArray* removed = [[NSMutableArray alloc] initWithCapacity:1];
	
	while((io_device = IOIteratorNext(iterator))) {
        for (LTIOUSBDevice* device in manager.devices) {
            if ([device device] == io_device) {
                //NSLog(@"removed: %@", device);
                [device setDeviceDisconnected];
                [removed addObject:device];
            }
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LTIOUSBDeviceDisconnectedNotification object:removed];
}

@interface LTIOUSBManager()
{
    NSMutableArray* _devices;
    BOOL _isStarted;
}
@end

@implementation LTIOUSBManager

@synthesize devices = _devices;

+(id)sharedInstance
{
    static dispatch_once_t pred;
    static id obj = nil;
        
    dispatch_once(&pred, ^{ obj = [[self alloc] init]; });
    return obj;
}

- (id)init
{
    self = [super init];
    if (self) {
        _isStarted = NO;
        _devices = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)addDevice:(LTIOUSBDevice *)device
{
    [_devices addObject:device];
}

- (BOOL)startWithMatchingDictionaries:(NSArray*)matching;
{
    if (_isStarted) {
        // TODO: handle error
        return YES;
    }
    
    
    mach_port_t masterPort = 0;
	IOMasterPort(MACH_PORT_NULL, &masterPort);
    
    IONotificationPortRef notifyPort = IONotificationPortCreate(masterPort);
	CFRunLoopSourceRef runLoopSource = IONotificationPortGetRunLoopSource(notifyPort);
	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
	CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopDefaultMode);
    
    NSDictionary* deviceClassMatchingDict = [[NSDictionary alloc] initWithDictionary:(__bridge_transfer NSDictionary*)IOServiceMatching(kIOUSBDeviceClassName)];
    
    for (NSDictionary* dict in matching) {
        
        NSMutableDictionary* matchingDict = [dict mutableCopy];
        for (id key in deviceClassMatchingDict) {
            [matchingDict setObject:[deviceClassMatchingDict objectForKey:key] forKey:key];
        }
        
        CFStringRef objectBaseClassName = (__bridge_retained CFStringRef)[matchingDict objectForKey:LTIOUSBManagerObjectBaseClassKey];
        
        // remove Object Base Class object, to use it matching dictionary
        [matchingDict removeObjectForKey:LTIOUSBManagerObjectBaseClassKey];
        
        
        NSLog(@"matching dict: %@", matchingDict);
        
        io_iterator_t iterator = IO_OBJECT_NULL;
        kern_return_t kr = IOServiceAddMatchingNotification(notifyPort, kIOFirstMatchNotification, (__bridge_retained CFDictionaryRef)matchingDict, _LTIOUSBDeviceAdded,
                                         (void*)objectBaseClassName, &iterator);
        if (kr != kIOReturnSuccess) {
            return NO;
        }
        
        if (iterator) {
            _LTIOUSBDeviceAdded((void*)objectBaseClassName, iterator);
            //IOObjectRelease(iterator);
        }
        
        iterator = IO_OBJECT_NULL;
        kr = IOServiceAddMatchingNotification(notifyPort, kIOTerminatedNotification, (__bridge_retained CFDictionaryRef)matchingDict, _LTIOUSBDeviceRemoved,
                                         (void*)objectBaseClassName, &iterator);
        if (kr != kIOReturnSuccess) {
            return NO;
        }
        if (iterator) {
            _LTIOUSBDeviceRemoved((void*)objectBaseClassName, iterator);
            //IOObjectRelease(iterator);
        }
    }
    
    _isStarted = YES;
    return YES; // success
}

-(LTIOUSBDevice*)deviceWithIdentifier:(NSString *)identifier
{
    for (LTIOUSBDevice* device in _devices) {
        if ([[device identifier] isEqualToString:identifier]) {
            return device;
        }
    }
    
    return nil;
}


#pragma mark - Helpers

- (BOOL)startWithMatchingDictionary:(NSDictionary*)dict
{
    return [self startWithMatchingDictionaries:[NSArray arrayWithObject:dict]];
}

+ (NSMutableDictionary*)matchingDictionaryForProductID:(uint16_t)deviceID vendorID:(uint16_t)vendorID objectBaseClass:(Class)cls
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setObject:NSStringFromClass(cls) forKey:LTIOUSBManagerObjectBaseClassKey];
    
    [dict setObject:[NSNumber numberWithUnsignedShort:deviceID] forKey:[NSString stringWithUTF8String:kUSBProductID]];
    [dict setObject:[NSNumber numberWithUnsignedShort:vendorID] forKey:[NSString stringWithUTF8String:kUSBVendorID]];
    
    return dict;
}

+ (NSMutableDictionary*)matchingDictionaryWithDeviceClass:(uint16_t)deviceClass objectBaseClass:(Class)cls
{
    
}

+ (NSMutableDictionary*)matchingDictionaryForAllUSBDevicesWithObjectBaseClass:(Class)cls
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setObject:NSStringFromClass(cls) forKey:LTIOUSBManagerObjectBaseClassKey];
    
    return dict;
}


@end
