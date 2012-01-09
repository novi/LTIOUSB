//
//  LTIOAppDelegate.h
//  LTIOUSB
//


#import <Cocoa/Cocoa.h>

@interface LTIOAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
- (IBAction)closeAll:(id)sender;
- (IBAction)openAll:(id)sender;
- (IBAction)resetAll:(id)sender;

@end
