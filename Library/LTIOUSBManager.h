//
//  LTIOUSBManager.h
//  LTIOUSB
//
//  Created by 伊藤 祐輔 on 12/01/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LTIOUSBDevice.h"

NSString* const LTIOUSBDeviceConnectedNotification;
NSString* const LTIOUSBDeviceDisconnectedNotification;
// NSString* const LTIOUSBManagerObjectBaseClassKey;



//@class LTIOUSBDevice;
@interface LTIOUSBManager : NSObject

// Primitive
+ (id)sharedInstance;
- (BOOL)startWithMatchingDictionaries:(NSArray*)array;
@property (nonatomic, strong, readonly) NSArray* devices;

// Helper
- (BOOL)startWithMatchingDictionary:(NSDictionary*)dict;

+ (NSMutableDictionary*)matchingDictionaryForProductID:(uint16_t)deviceID vendorID:(uint16_t)vendorID objectBaseClass:(Class)cls;
//+ (NSMutableDictionary*)matchingDictionaryWithDeviceClass:(uint16_t)deviceClass objectBaseClass:(Class)cls;
+ (NSMutableDictionary*)matchingDictionaryForAllUSBDevicesWithObjectBaseClass:(Class)cls;

@end





@interface LTIOUSBManager(Private)

- (LTIOUSBDevice*)deviceWithIdentifier:(NSString*)identifier;
- (void)addDevice:(LTIOUSBDevice*)device;

@end