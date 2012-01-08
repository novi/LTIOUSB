//
//  LTIOUSBDevice.h
//  LTIOUSB
//
//  Created by 伊藤 祐輔 on 12/01/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// Abstract class
@interface LTIOUSBDevice : NSObject


@property (nonatomic, readonly, getter = isConnected) BOOL connected;
@property (nonatomic, strong, readonly) NSDictionary* deviceInfo;
@property (nonatomic, assign, readonly) io_service_t deviceHandle;

// You can override on subclass
- (void)deviceConnected;
- (void)deviceDisconnected;
+ (NSString*)deviceIdentifier:(io_service_t)device; // Same identifier is same instance, default implementation is "<serial>-<productID>-<vendorID>"
+ (BOOL)removeFromDeviceListOnDisconnect;

// Helper
- (BOOL)createDeviceInterface;
- (void)closeDevice;

@end




@interface LTIOUSBDevice(Private)

- (id)initWithIdentifier:(NSString*)identifier;
- (void)setDeviceConnectedWithDevice:(io_service_t)device;
- (void)setDeviceDisconnected;
- (NSString*)identifier;
- (io_service_t)device;

@end


