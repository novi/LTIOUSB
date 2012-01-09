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
- (void)closePluginInterface;
@property (nonatomic, assign, readonly) IOCFPlugInInterface** pluginInterface;

- (BOOL)createDeviceInterface;
- (void)closeDeviceInterface;
@property (nonatomic, assign, readonly) IOUSBDeviceInterface320** deviceInterface;


// Helpers
- (BOOL)openDevice;
- (BOOL)closeDevice;
- (BOOL)resetDevice;

@end




@interface LTIOUSBDevice(Private)

- (id)initWithIdentifier:(NSString*)identifier;
- (void)setDeviceConnectedWithDevice:(io_service_t)device;
- (void)setDeviceDisconnected;
- (NSString*)identifier;
- (io_service_t)device;

@end


