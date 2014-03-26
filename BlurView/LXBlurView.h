//
//  LXBlurView.h
//  BlurView
//
//  Created by xu lian on 2014-01-28.
//  Copyright (c) 2014 Beyondcow. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LXBlurView : NSView
@property(assign) CGFloat blurRadius;

- (IBAction)setBlurRadius:(CGFloat)blurRadius;

@end
