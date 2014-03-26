//
//  LXBlurView.m
//  BlurView
//
//  Created by xu lian on 2014-01-28.
//  Copyright (c) 2014 Beyondcow. All rights reserved.
//

#import "LXBlurView.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>

@interface LXBlurView ()
{
    NSRect oldframe;
    NSPoint oldpoint;
    BOOL mousedown;
}

@end


@implementation LXBlurView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.blurRadius=40.0;
    }
    return self;
}

- (NSImage*)blurimage:(NSImage*)img withRadius:(CGFloat)radius withIteration:(int)iterations tintColor:(NSColor *)tintColor
{
    //image must be nonzero size
    if (floorf(img.size.width) * floorf(img.size.height) <= 0.0f) return img;
    else{
        
        //boxsize must be an odd integer
        int scale=1;
        uint32_t boxSize = (uint32_t)(radius * scale);
        if (boxSize % 2 == 0) boxSize ++;
        
        //create image buffers
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)[img TIFFRepresentation], NULL);
        CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
        CFRelease(source);
        
        vImage_Buffer buffer1, buffer2;
        buffer1.width = buffer2.width = CGImageGetWidth(imageRef);
        buffer1.height = buffer2.height = CGImageGetHeight(imageRef);
        buffer1.rowBytes = buffer2.rowBytes = CGImageGetBytesPerRow(imageRef);
        size_t bytes = buffer1.rowBytes * buffer1.height;
        buffer1.data = malloc(bytes);
        buffer2.data = malloc(bytes);
        
        //create temp buffer
        void *tempBuffer = malloc((size_t)vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend + kvImageGetTempBufferSize));
        if (tempBuffer==NULL) {
            if(buffer1.data){
                free(buffer1.data);
                buffer1.data=NULL;
            }
            if (buffer2.data) {
                free(buffer2.data);
                buffer2.data=NULL;
            }
            if (imageRef) {
                CGImageRelease(imageRef);
            }
        }else{
            
            //copy image data
            CFDataRef dataSource = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
            memcpy(buffer1.data, CFDataGetBytePtr(dataSource), bytes);
            CFRelease(dataSource);
            
            for (NSUInteger i = 0; i < iterations; i++)
            {
                //perform blur
                vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
                
                //swap buffers
                void *temp = buffer1.data;
                buffer1.data = buffer2.data;
                buffer2.data = temp;
            }
            
            //free buffers
            free(buffer2.data);
            free(tempBuffer);
            
            //create image context from buffer
            CGContextRef ctx = CGBitmapContextCreate(buffer1.data, buffer1.width, buffer1.height,
                                                     8, buffer1.rowBytes, CGImageGetColorSpace(imageRef),
                                                     CGImageGetBitmapInfo(imageRef));
            
            //apply tint
            if (tintColor && CGColorGetAlpha(tintColor.CGColor) > 0.0f)
            {
                CGContextSetFillColorWithColor(ctx, [tintColor colorWithAlphaComponent:0.25].CGColor);
                CGContextSetBlendMode(ctx, kCGBlendModePlusLighter);
                CGContextFillRect(ctx, CGRectMake(0, 0, buffer1.width, buffer1.height));
            }
            
            if (imageRef) {
                CGImageRelease(imageRef);
            }
            //create image from context
            imageRef = CGBitmapContextCreateImage(ctx);
            
            //CGContextRef viewctx = [[NSGraphicsContext currentContext] graphicsPort];
            //CGContextDrawImage(viewctx, self.bounds, imageRef);
            
            NSImage *image=[[NSImage alloc] initWithCGImage:imageRef size:img.size];
            
            CGImageRelease(imageRef);
            CGContextRelease(ctx);
            free(buffer1.data);
            
            return image;
        }
        
    }
    
    return img;
}


//this blur method is for testing only
- (NSImage*)blurimage1:(NSImage*)img withRadius:(CGFloat)radius withIteration:(int)iterations tintColor:(NSColor *)tintColor
{
    //image must be nonzero size
    if (floorf(img.size.width) * floorf(img.size.height) <= 0.0f) return img;
    else{
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)[img TIFFRepresentation], NULL);
        CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
        CFRelease(source);
        
        CIImage *imageToBlur = [CIImage imageWithCGImage:imageRef];
        
        CIFilter *_blurFilter;
        // Next, we create the blur filter
        _blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [_blurFilter setDefaults];
        [_blurFilter setValue:@(radius/60.0*10.0) forKey:@"inputRadius"];

        for(int i=0; i<iterations; i++){
            [_blurFilter setValue:imageToBlur forKey: @"inputImage"];
            imageToBlur = [_blurFilter valueForKey: @"outputImage"];
        }
       
        NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:imageToBlur];
        [rep setSize:img.size];
        NSImage *nsImage = [[NSImage alloc] initWithSize:img.size];
        [nsImage addRepresentation:rep];
        
        CGImageRelease(imageRef);

        return nsImage;
    }
    
    return img;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (_blurRadius<=0) {
        [[NSColor colorWithDeviceWhite:1.0 alpha:0.2] set];
        NSRectFillUsingOperation(self.bounds, NSCompositeSourceOver);
        return;
    }
   
    CFAbsoluteTime beg=CFAbsoluteTimeGetCurrent();
    @autoreleasepool {
        NSImage *img=[self prepareUnderlyingSnapshot];
        if(img){
            NSImage *blurimg=[self blurimage:img withRadius:_blurRadius withIteration:4 tintColor:[NSColor whiteColor]];
            [blurimg drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
            blurimg=nil;
        }
    }
    CFAbsoluteTime end=CFAbsoluteTimeGetCurrent();
    [[NSString stringWithFormat:@"%.0ffps", (1.0/(end-beg))] drawAtPoint:NSMakePoint(10, self.bounds.size.height-25) withAttributes:@{NSForegroundColorAttributeName:[NSColor whiteColor]}];
}

#pragma mark -
//TODO: make this method faster
//TODO: make this mehtod can snapshot CALayer
- (NSImage *)prepareUnderlyingSnapshot
{
    [self setHidden:YES];
    NSImage *image=nil;
    @try {
        if (self.superview) {
            [self.superview lockFocus];
            NSBitmapImageRep* rep = [self.superview bitmapImageRepForCachingDisplayInRect:self.superview.frame];
            [self.superview cacheDisplayInRect:self.superview.frame toBitmapImageRep:rep];
            [self.superview unlockFocus];
            image = [[NSImage alloc] initWithCGImage:[rep CGImage] size:NSMakeSize(rep.pixelsWide, rep.pixelsHigh)];
            rep=nil;
        }
    }
    @catch (NSException *exception) {
        image=nil;
    }
    @finally {
    }
    [self setHidden:NO];
    
    if (image) {
        
        NSSize size=NSMakeSize(self.bounds.size.width, self.bounds.size.height);
        
        NSImage *img=[[NSImage alloc] initWithSize:size];
        [img lockFocus];
        [[NSColor whiteColor] set];
        NSRectFill(NSMakeRect(0, 0, size.width, size.height));
        [image drawAtPoint:NSMakePoint(-self.frame.origin.x, -self.frame.origin.y) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [img unlockFocus];
        return img;
    }
    
    return nil;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    mousedown=YES;
    oldpoint=[theEvent locationInWindow];
    oldframe=self.frame;
}

- (void)mouseUp:(NSEvent *)theEvent
{
    mousedown=NO;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint newpoint=[theEvent locationInWindow];
    [self setFrameOrigin:NSMakePoint(oldframe.origin.x, oldframe.origin.y+(newpoint.y-oldpoint.y))];
}


@end







