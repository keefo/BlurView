//
//  LXAppDelegate.m
//  BlurView
//
//  Created by xu lian on 2014-01-28.
//  Copyright (c) 2014 Beyondcow. All rights reserved.
//

#import "LXAppDelegate.h"

@implementation LXAppDelegate

+ (void)initialize{
	if ( self == [LXAppDelegate class] ) {
        NSDictionary *defaultValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                       @(40), @"defaultBlurRadius",
                                       nil
                                       ];
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
        [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
	}
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults *df=[NSUserDefaults standardUserDefaults];
    
    [df addObserver:self forKeyPath:@"defaultBlurRadius" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionInitial) context:nil];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"defaultBlurRadius"]) {
        CGFloat defaultBlurRadius=[[NSUserDefaults standardUserDefaults] floatForKey:@"defaultBlurRadius"];
        [_view setBlurRadius:defaultBlurRadius];
    }else{
        [_view setBlurRadius:30.0];
    }

    [_imageview mouseDown:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"defaultBlurRadius"]){
        CGFloat defaultBlurRadius=[[NSUserDefaults standardUserDefaults] floatForKey:@"defaultBlurRadius"];
        [_view setBlurRadius:defaultBlurRadius];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}



@end
