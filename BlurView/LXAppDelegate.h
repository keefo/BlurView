//
//  LXAppDelegate.h
//  BlurView
//
//  Created by xu lian on 2014-01-28.
//  Copyright (c) 2014 Beyondcow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LXBlurView.h"
#import "LXImageView.h"

@interface LXAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet LXImageView *imageview;
@property (assign) IBOutlet LXBlurView *view;


@end
