//
//  LTIOUSBDevice.m
//  LTIOUSB
//
//  Created by 伊藤 祐輔 on 12/01/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "LTIOUSBDevice.h"
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOMessage.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/IOBSD.h>


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

-(io_service_t)deviceHandle
{
    return _handle;
}

-(void)deviceConnected
{
    if ([self createDeviceInterface]) {
        // success
        NSLog(@"device interface created");
    }
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

+(BOOL)removeFromDeviceListOnDisconnect
{
    return YES;
}


#pragma mark - Helpers

-(BOOL)createDeviceInterface
{
    kern_return_t kr;
    IOCFPlugInInterface** pluginInterface = NULL;
    SInt32 score = 0;
    kr = IOCreatePlugInInterfaceForService(_handle, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &pluginInterface, &score);
    
    if (kr != kIOReturnSuccess) {
        return NO;
    }
    
    IOUSBDeviceInterface320** interface = NULL;
    HRESULT res = (*pluginInterface)->QueryInterface(pluginInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID320), (LPVOID*)&interface);
    if (res != 0 && interface == NULL) {
        return NO;
    }
    
#warning test
    IOReturn ret;
    
    ret = (*interface)->USBDeviceClose(interface);
    if (ret != kIOReturnSuccess) {
       NSLog(@"close failed, %d, %x", ret, ret);
    }
    
    ret = (*interface)->USBDeviceOpen(interface);
    if (ret != kIOReturnSuccess) {
        NSLog(@"open failed, %d, %x", ret, ret);
        return NO;
    }
    
    UInt8 numofconf = 0;
    ret = (*interface)->GetNumberOfConfigurations(interface, &numofconf);
    NSLog(@"GetNumberOfConfigurations: %d", numofconf);
    
    UInt8 class = 0;
    ret = (*interface)->GetDeviceClass(interface, &class);
    NSLog(@"GetDeviceClass: %d", class);
    
    UInt8 subclass = 0;
    ret = (*interface)->GetDeviceSubClass(interface, &subclass);
    NSLog(@"GetDeviceSubClass: %d", subclass);
    
    ret = (*interface)->ResetDevice(interface);
    NSLog(@"reset: %d", ret);
    
    ret = (*interface)->USBDeviceClose(interface);
    if (ret != kIOReturnSuccess) {
        NSLog(@"close failed, %d, %x", ret, ret);
    }
    
    ret = (*interface)->Release(interface);
    NSLog(@"released %d", ret);
    
    return YES;
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
    if (_handle == device) {
        return;
    }
    _handle = device;
    _connected = YES;
    
    [self deviceConnected];
}

- (void)setDeviceDisconnected
{
    if ( ! _handle) {
        return;
    }
    
    _connected = NO;
    _handle = IO_OBJECT_NULL;
    
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
