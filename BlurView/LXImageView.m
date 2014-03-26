//
//  LXImageView.m
//  BlurView
//
//  Created by xu lian on 2014-01-29.
//  Copyright (c) 2014 Beyondcow. All rights reserved.
//

#import "LXImageView.h"

@implementation LXImageView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        idx=0;
    }
    return self;
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//	[super drawRect:dirtyRect];
//	
//    // Drawing code here.
//}

- (void)mouseDown:(NSEvent *)theEvent
{
    [self setImage:[NSImage imageNamed:[NSString stringWithFormat:@"%d",idx]]];
}

@end
