//
//  LTIOUSBManager.h
//  LTIOUSB
//
//  Created by Yusuke Ito on 12/01/07.
//  Copyright (c) 2012 Yusuke Ito.
//  http://www.opensource.org/licenses/MIT
//

#import <Foundation/Foundation.h>
#import "LTIOUSBDevice.h"

NSString* const LTIOUSBDeviceConnectedNotification;
NSString* const LTIOUSBDeviceDisconnectedNotification;
NSString* const LTIOUSBManagerObjectBaseClassKey; // the value must be NSString



//@class LTIOUSBDevice;
@interface LTIOUSBManager : NSObject

// Primitive
+ (LTIOUSBManager*)sharedInstance;
- (BOOL)startWithMatchingDictionaries:(NSArray*)array; // return: not 0 is success
@property (nonatomic, strong, readonly) NSArray* devices; // LTIOUSBDevice or its subclass



// Helper
- (BOOL)startWithMatchingDictionary:(NSDictionary*)dict;

+ (NSMutableDictionary*)matchingDictionaryForProductID:(uint16_t)deviceID vendorID:(uint16_t)vendorID objectBaseClass:(Class)cls;
//+ (NSMutableDictionary*)matchingDictionaryWithDeviceClass:(uint16_t)deviceClass objectBaseClass:(Class)cls;
+ (NSMutableDictionary*)matchingDictionaryForAllUSBDevicesWithObjectBaseClass:(Class)cls;

@end





@interface LTIOUSBManager(Private)

- (LTIOUSBDevice*)deviceWithIdentifier:(NSString*)identifier;
- (void)addDevice:(LTIOUSBDevice*)device;
- (void)removeDevice:(LTIOUSBDevice*)device;

@end