//
//  CameraImageView.m
//  CameraTest01
//
//  Created by Shawn Roske on 7/26/10.
//  Copyright 2010 Bitgun. All rights reserved.
//

#import "CameraImageView.h"


@implementation CameraImageView

@synthesize image;

- (void)setImage:(UIImage *)i
{
	if ( image != i )
	{
		[image release];
		image = [i retain];
	}
	NSLog(@"set image");
	//[self setNeedsDisplay];	
	[self layoutSubviews];
}

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
	{
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect 
{
	NSLog(@"drawing");
	[self.image drawInRect:rect];
}

- (void)dealloc 
{
	[image release];
    [super dealloc];
}


@end
