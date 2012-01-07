//
//  LTIOUSBDevice.m
//  LTIOUSB
//
//  Created by 伊藤 祐輔 on 12/01/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "LTIOUSBDevice.h"
#import <IOKit/usb/IOUSBLib.h>


@interface LTIOUSBDevice()
{
    NSString* _identifier;
    BOOL _connected;
    io_service_t _handle;
}
@end

@implementation LTIOUSBDevice

@synthesize connected = _connected;

-(NSDictionary *)deviceInfo
{
    CFMutableDictionaryRef dict = NULL;
    IORegistryEntryCreateCFProperties(_handle, &dict, NULL, 0);
    return (__bridge_transfer NSDictionary*)dict;
}

-(void)deviceConnected
{
    
}

-(void)deviceDisconnected
{
    
}

+(NSString *)deviceIdentifier:(io_service_t)device
{
    CFMutableDictionaryRef dict = NULL;
    IORegistryEntryCreateCFProperties(device, &dict, NULL, 0);
    CFNumberRef productID = CFDictionaryGetValue(dict, CFSTR(kUSBProductID) );
    CFNumberRef vendorID = CFDictionaryGetValue(dict, CFSTR(kUSBVendorID) );
    CFStringRef serialNum = CFDictionaryGetValue(dict, CFSTR(kUSBSerialNumberString));
    
    NSString* ids = [NSString stringWithFormat:@"%@-%x-%x", serialNum, [(__bridge NSNumber*)productID unsignedIntValue], [(__bridge NSNumber*)vendorID unsignedIntValue]];
    if (dict) {
        CFRelease(dict);
    }
    
    return ids;
}

@end


@implementation LTIOUSBDevice(Private)


-(id)initWithIdentifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        _identifier = identifier;
        _handle = IO_OBJECT_NULL;
    }
    return self;
}

- (void)setDeviceConnectedWithDevice:(io_object_t)device
{
    _handle = device;
    _connected = YES;
    
    [self deviceConnected];
}

- (void)setDeviceDisconnected
{
    _connected = NO;
    
    [self deviceDisconnected];
}

-(io_service_t)device
{
    return _handle;
}


-(NSString *)identifier
{
    return _identifier;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@: (%p) %@\n----%@-%@", [super description], _identifier, _handle, IOObjectCopyClass(_handle), [self.deviceInfo objectForKey:@"USB Product Name"], _connected ? @"connected": @"disconnected"];
}


@end
