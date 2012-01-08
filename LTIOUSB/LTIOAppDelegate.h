//
//  LTIOAppDelegate.h
//  LTIOUSB
//
//  Created by 伊藤 祐輔 on 12/01/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LTIOAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
- (IBAction)closeAll:(id)sender;
- (IBAction)openAll:(id)sender;
- (IBAction)resetAll:(id)sender;

@end
