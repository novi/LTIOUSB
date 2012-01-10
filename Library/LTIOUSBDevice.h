//
//  LTIOUSBDevice.h
//  LTIOUSB
//
//  Created by Yusuke Ito on 12/01/07.
//  Copyright (c) 2012 Yusuke Ito.
//  http://www.opensource.org/licenses/MIT
//


#import <Foundation/Foundation.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/usb/IOUSBLib.h>


typedef void (^LTIOUSBDeviceReadCallback)(NSData* data);
typedef void (^LTIOUSBDeviceWriteCallback)(BOOL success);


// Abstract class
@interface LTIOUSBDevice : NSObject


@property (nonatomic, readonly, getter = isConnected) BOOL connected;
@property (nonatomic, strong, readonly) NSDictionary* deviceInfo;
//@property (nonatomic, assign, readonly) io_service_t deviceHandle;

// You can override on subclass
- (void)deviceConnected;
- (void)deviceDisconnected;
+ (NSString*)deviceIdentifier:(io_service_t)device; // Same identifier is same instance, default implementation is "<serial>-<productID>-<vendorID>"
+ (BOOL)removeFromDeviceListOnDisconnect; // Default is NO

// Handle Interface
- (BOOL)createPluginInterface; // return: not 0 is success
- (void)destroyPluginInterface;
@property (nonatomic, assign, readonly) IOCFPlugInInterface** pluginInterface;

- (BOOL)createDeviceInterface;
- (void)destroyDeviceInterface;
@property (nonatomic, assign, readonly) IOUSBDeviceInterface320** deviceInterface;

- (BOOL)findFirstInterfaceInterface; // device must be opend
- (void)destroyInterfaceInterface;

// You can override on subclass if use another interface-interface to use Helper Methods
@property (nonatomic, assign, readonly) IOUSBInterfaceInterface300** interfaceInterface;

// Helpers
- (BOOL)openDevice;
- (BOOL)closeDevice;
- (BOOL)resetDevice;

// these helper methods use |self.interfaceInterface| for interface-interface
- (BOOL)openInterface; 
- (BOOL)closeInterface; 
- (BOOL)addAsyncRunloopSourceToRunloop:(CFRunLoopRef)toRunloop;

- (BOOL)clearPipeStall:(UInt8)pipe;

- (BOOL)writeToPipe:(UInt8)pipe data:(NSData*)data noDataTimeout:(UInt32)dto completionTimeout:(UInt32)cto;
- (BOOL)readFromPipe:(UInt8)pipe data:(NSData**)readData noDataTimeout:(UInt32)dto completionTimeout:(UInt32)cto; // not yet tested

- (BOOL)readFromPipeAsync:(UInt8)pipe callback:(LTIOUSBDeviceReadCallback)callback maxPacketSize:(UInt32)maxSize noDataTimeout:(UInt32)dto completionTimeout:(UInt32)cto;
- (BOOL)writeToPipeAsync:(UInt8)pipe data:(NSData*)data callback:(LTIOUSBDeviceWriteCallback)callback noDataTimeout:(UInt32)dto completionTimeout:(UInt32)cto; // not yet tested

- (BOOL)sendControlRequestToPipe:(UInt8)pipe request:(IOUSBDevRequestTO)request;

@end




@interface LTIOUSBDevice(Private)

- (id)initWithIdentifier:(NSString*)identifier;
- (void)setDeviceConnectedWithDevice:(io_service_t)device;
- (void)setDeviceDisconnected;
- (NSString*)identifier;
- (io_service_t)device;

@end


