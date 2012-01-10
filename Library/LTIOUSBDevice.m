//
//  LTIOUSBDevice.m
//  LTIOUSB
//
//  Created by Yusuke Ito on 12/01/07.
//  Copyright (c) 2012 Yusuke Ito.
//  http://www.opensource.org/licenses/MIT
// 

#import "LTIOUSBDevice.h"
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOMessage.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/usb/IOUSBLib.h>
#import <IOKit/IOBSD.h>

void _LTUSBInterfaceReadWriteAsyncCallback(void *refcon, IOReturn result, void *arg0);



void _LTUSBInterfaceReadWriteAsyncCallback(void *refcon, IOReturn result, void *arg0)
{
    void (^callback)(UInt32 size, IOReturn res) = (__bridge id)refcon;
    
    UInt32 size = (UInt32)arg0;
    if (result == kIOReturnSuccess && size) {
        callback(size, result);
    } else {
        callback(0, result);
    }
    
    CFRelease((CFTypeRef)refcon);
}



@interface LTIOUSBDevice()
{
    NSString* _identifier;
    BOOL _connected;
    io_service_t _handle;
    IOCFPlugInInterface** _pluginInterface;
    IOUSBDeviceInterface320** _deviceInterface;
    IOUSBInterfaceInterface300** _interfaceInterface;
}
@end

@implementation LTIOUSBDevice

@synthesize connected = _connected;
@synthesize pluginInterface = _pluginInterface;
@synthesize deviceInterface = _deviceInterface;
@synthesize interfaceInterface = _interfaceInterface;

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
    /*if ([self createPluginInterface]) {
        NSLog(@"createPluginInterface: %p", _pluginInterface);
    }
    if ([self createDeviceInterface]) {
        // success
        NSLog(@"createDeviceInterface: %p", _deviceInterface);
    }*/
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
    return NO;
}

-(BOOL)createPluginInterface
{
    if (_pluginInterface) {
        return NO;
    }
    
    kern_return_t kr;
    IOCFPlugInInterface** pluginInterface = NULL;
    SInt32 score = 0;
    kr = IOCreatePlugInInterfaceForService(_handle, kIOUSBDeviceUserClientTypeID, kIOCFPlugInInterfaceID, &pluginInterface, &score);
    
    if (kr != kIOReturnSuccess) {
        return NO;
    }
    
    _pluginInterface = pluginInterface;
    
    return YES;
}



-(void)closePluginInterface
{
    if (_pluginInterface) {
        (*_pluginInterface)->Release(_pluginInterface);
        _pluginInterface = NULL;
    }
    //IOObjectRelease(_handle); // release for device added
    //_handle = IO_OBJECT_NULL;
}


-(BOOL)createDeviceInterface
{
    if (_deviceInterface) {
        return NO;
    }
    
    IOUSBDeviceInterface320** interface = NULL;
    HRESULT res = (*_pluginInterface)->QueryInterface(_pluginInterface, CFUUIDGetUUIDBytes(kIOUSBDeviceInterfaceID320), (LPVOID*)&interface);
    if (res != 0 && interface == NULL) {
        return NO;
    }
    
    /*
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
    
    //ret = (*interface)->ResetDevice(interface);
    //NSLog(@"reset: %d", ret);
    
    ret = (*interface)->USBDeviceClose(interface);
    if (ret != kIOReturnSuccess) {
        NSLog(@"close failed, %d, %x", ret, ret);
    }*/
    
    _deviceInterface = interface;
    
    return YES;
}

-(void)closeDeviceInterface
{
    [self closeDevice];
    if (_deviceInterface) {
        (*_deviceInterface)->Release(_deviceInterface);
        _deviceInterface = NULL;
    }
}




-(BOOL)findFirstInterfaceInterface
{
    if (_interfaceInterface) {
        return NO;
    }
    
    IOUSBFindInterfaceRequest request;
    request.bInterfaceClass    = kIOUSBFindInterfaceDontCare;
    request.bInterfaceSubClass = kIOUSBFindInterfaceDontCare;
    request.bInterfaceProtocol = kIOUSBFindInterfaceDontCare;
    request.bAlternateSetting  = kIOUSBFindInterfaceDontCare;
    
    IOUSBDeviceInterface320** deviceInterface = self.deviceInterface;
    
    IOReturn ret;
    io_iterator_t iterator = IO_OBJECT_NULL;
    io_service_t interface = IO_OBJECT_NULL;
    ret = (*deviceInterface)->CreateInterfaceIterator(deviceInterface, &request, &iterator);
    IOCFPlugInInterface** pluginInterface = NULL;
    SInt32 score = 0;
    while ((interface = IOIteratorNext(iterator))) {
        kern_return_t kr = IOCreatePlugInInterfaceForService(interface, kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID, &pluginInterface, &score);
        IOObjectRelease(interface);
        
        if (kr != 0 || !pluginInterface) {
            continue; // error
        }
        
        
        IOUSBInterfaceInterface300** interfaceInterface = NULL;
        HRESULT res = (*pluginInterface)->QueryInterface(pluginInterface, CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID300), (LPVOID)&interfaceInterface);
        IODestroyPlugInInterface(pluginInterface);
        if (res != 0) {
            continue; // error
        }
        
        IOObjectRelease(iterator);
        _interfaceInterface = interfaceInterface;
        return YES;
        //return interfaceInterface;
    }
    
    IOObjectRelease(iterator);
    return NO;
}

-(void)closeInterfaceInterface
{
    [self closeInterface];
    if (_interfaceInterface) {
        (*_interfaceInterface)->Release(_interfaceInterface);
        _interfaceInterface = NULL;
    }
}


/*
-(void)replaceInterfaceInterfaceWith:(IOUSBInterfaceInterface300 **)interface
{
    if (interface && _interfaceInterface != interface) {
        _interfaceInterface = interface;
    }
}
*/



#pragma mark - Helpers

-(BOOL)openDevice
{
    if ( ! _deviceInterface) {
        return NO;
    }
    
    IOReturn ret = (*_deviceInterface)->USBDeviceOpen(_deviceInterface);
    if (ret != kIOReturnSuccess) {
        NSLog(@"open failed, %d, %x", ret, ret);
        return NO;
    }
    
    return YES;
}

-(BOOL)closeDevice
{
    if ( ! _deviceInterface) {
        return NO;
    }
    
    IOReturn ret = (*_deviceInterface)->USBDeviceClose(_deviceInterface);
    if (ret != kIOReturnSuccess) {
        return NO;
    }
    
    return YES;
}

-(BOOL)resetDevice
{
    if ( ! _deviceInterface) {
        return NO;
    }
    
    if (! [self openDevice]) {
        return NO;
    }
    
    IOReturn ret = (*_deviceInterface)->ResetDevice(_deviceInterface);
    if (ret != kIOReturnSuccess) {
        NSLog(@"reset failed, %d, %x", ret, ret);
        return NO;
    }
    
    return YES;
}

-(BOOL)openInterface
{
    IOUSBInterfaceInterface300** interface = self.interfaceInterface;
    if (!interface) {
        return NO;
    }
    
    IOReturn ret = (*interface)->USBInterfaceOpen(interface);
    if (ret != kIOReturnSuccess) {
        return NO;
    }
    
    return YES;
}

-(BOOL)closeInterface
{
    IOUSBInterfaceInterface300** interface = self.interfaceInterface;
    if (!interface) {
        return NO;
    }
    
    IOReturn ret = (*interface)->USBInterfaceClose(interface);
    if (ret != kIOReturnSuccess) {
        return NO;
    }
    
    return YES;
}


-(BOOL)addAsyncRunloopSourceToRunloop:(CFRunLoopRef)toRunloop
{
    CFRunLoopSourceRef source = NULL;
    IOReturn ret = (*_interfaceInterface)->CreateInterfaceAsyncEventSource(_interfaceInterface, &source);
    if (ret != kIOReturnSuccess) {
        return NO;
    }
    CFRunLoopAddSource(toRunloop, source, kCFRunLoopDefaultMode);
    CFRelease(source);
    
    return YES;
}


-(BOOL)clearPipeStall:(UInt8)pipe
{
    IOReturn ret = (*_interfaceInterface)->ClearPipeStall(_interfaceInterface, pipe);
    if (ret != kIOReturnSuccess) {
        return NO;
    }
    
    return YES;
}

-(BOOL)readFromPipe:(UInt8)pipe data:(NSData *__autoreleasing *)readData noDataTimeout:(UInt32)dto completionTimeout:(UInt32)cto
{
#warning @TODO: get pipe max size from endpoint descriptor
    
    UInt32 pipeMaxSize = 4096;
    UInt8* buf = malloc(sizeof(UInt8)*pipeMaxSize);
    UInt32 readDataSize = 0;
    
    IOReturn ret = (*_interfaceInterface)->ReadPipeTO(_interfaceInterface, pipe, buf, &readDataSize, dto, cto);
    if (ret != kIOReturnSuccess) {
        return NO;
    }
    
    if (readData) {
        *readData = [NSData dataWithBytesNoCopy:buf length:readDataSize freeWhenDone:YES];
    }
    
    return YES;
}

-(BOOL)writeToPipe:(UInt8)pipe data:(NSData *)data noDataTimeout:(UInt32)dto completionTimeout:(UInt32)cto
{
    IOReturn ret = (*_interfaceInterface)->WritePipeTO(_interfaceInterface, pipe, (void*)data.bytes, (UInt32)data.length, dto, cto);
    if (ret != kIOReturnSuccess) {
        return NO;
    }
    return YES;
}

-(BOOL)readFromPipeAsync:(UInt8)pipe callback:(LTIOUSBDeviceReadCallback)callback maxPacketSize:(UInt32)maxSize noDataTimeout:(UInt32)dto completionTimeout:(UInt32)cto
{
    UInt8* buffer = malloc(sizeof(UInt8)*maxSize);
    
    id readCallBackObj = [^ void(NSUInteger size, IOReturn result) {
        NSData* data = size ? [NSData dataWithBytes:buffer length:size] : nil;
        free(buffer);
        if (callback) {
            if (result == kIOReturnSuccess) {
                if (size) {
                    callback(data);
                } else {
                    callback([NSData data]); // zero size data
                }
            } else {
                callback(nil);
            }
        }
    } copy];
    
    CFTypeRef readCallBack =  (__bridge_retained CFTypeRef)readCallBackObj;
    
    IOReturn ret = (*_interfaceInterface)->ReadPipeAsyncTO(_interfaceInterface, pipe, buffer, maxSize, dto, cto, _LTUSBInterfaceReadWriteAsyncCallback, (void*)readCallBack);
    
    if (ret != kIOReturnSuccess) {
        CFRelease(readCallBack); // release callback if failure
        return NO;
    }
    
    return YES;
}

-(BOOL)writeToPipeAsync:(UInt8)pipe data:(NSData *)data callback:(LTIOUSBDeviceWriteCallback)callback noDataTimeout:(UInt32)dto completionTimeout:(UInt32)cto
{
    CFTypeRef writeCallBack =  (__bridge_retained CFTypeRef)[^ void(NSUInteger size, IOReturn result) {
        BOOL success = (size == data.length) ? YES : NO;
        if (callback) {
            callback(success);
        }
    } copy];
    
    
    IOReturn ret = (*_interfaceInterface)->WritePipeAsyncTO(_interfaceInterface, pipe, (void*)data.bytes, (UInt32)data.length, dto, cto, _LTUSBInterfaceReadWriteAsyncCallback, (void*)writeCallBack);
    
    if (ret != kIOReturnSuccess) {
        CFRelease(writeCallBack); // release callback if failure
        return NO;
    }
    
    return YES;
}

-(BOOL)sendControlRequestToPipe:(UInt8)pipe request:(IOUSBDevRequestTO)request
{
    IOReturn ret = (*_interfaceInterface)->ControlRequestTO(_interfaceInterface, pipe, &request);
    if (ret != kIOReturnSuccess) {
        return NO;
    }
    return YES;
}

@end

#pragma mark -

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
    
    [self closeInterfaceInterface];
    [self closeDeviceInterface];
    [self closePluginInterface];
    
    _connected = NO;

    IOObjectRelease(_handle); // release for device added
    IOObjectRelease(_handle); // release for device removed
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
