//
//  CameraVC.m
//  CameraTest01
//
//  Created by Shawn Roske on 7/25/10.
//  Copyright 2010 Bitgun. All rights reserved.
//

#import "CameraVC.h"

@implementation CameraVC

@synthesize imageView;

@synthesize statusItem;
@synthesize startItem;
@synthesize stopItem;

@synthesize session;

// Create and configure a capture session and start it running
- (AVCaptureSession *)session
{
	if ( session == nil )
	{
		NSError *error = nil;
		
		// Create the session
		AVCaptureSession *s = [[AVCaptureSession alloc] init];
		
		// Configure the session to produce lower resolution video frames, if your 
		// processing algorithm can cope. We'll specify medium quality for the
		// chosen device.
		s.sessionPreset = AVCaptureSessionPresetMedium;
		
		// Find a suitable AVCaptureDevice
		AVCaptureDevice *device = [AVCaptureDevice
								   defaultDeviceWithMediaType:AVMediaTypeVideo];
		
		// Create a device input with the device and add it to the session.
		AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device 
																			error:&error];
		if (!input) 
		{
			// Handling the error appropriately.
			NSLog(@"failed to setup input device!");
		}
		[s addInput:input];
		
		// Create a VideoDataOutput and add it to the session
		AVCaptureVideoDataOutput *output = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
		[s addOutput:output];
		
		// Configure your output.
		//dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
		[output setSampleBufferDelegate:self queue:dispatch_get_current_queue()];
		//dispatch_release(queue);
		
		// Specify the pixel format
		output.videoSettings = 
		[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] 
									forKey:(id)kCVPixelBufferPixelFormatTypeKey];
		
		
		// If you wish to cap the frame rate to a known value, such as 15 fps, set 
		// minFrameDuration.
		output.minFrameDuration = CMTimeMake(1, 15);
		
		[self setSession:s];
		[s release];
	}
	return session;
}

// Delegate routine that is called when a sample buffer was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection
{ 
	
	
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0); 
    /*Get information about the image*/
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer); 
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer); 
    
    /*Create a CGImageRef from the CVImageBufferRef*/
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
    CGImageRef newImage = CGBitmapContextCreateImage(newContext); 
	/*We unlock the  image buffer*/
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	
    /*We release some components*/
    CGContextRelease(newContext); 
    CGColorSpaceRelease(colorSpace);
	
	/*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly)*/
	UIImage *image = [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
	self.imageView.image = image;
	
	/*We relase the CGImageRef*/
	CGImageRelease(newImage);
	
    // Create a UIImage from the sample buffer data
	//[self.imageView setImage:[self imageFromSampleBuffer:sampleBuffer]];
}

- (IBAction) start
{
	if ( self.session.running == NO )
	{
		[self.statusItem setTitle:@"Acquiring..."];
		[self.startItem setEnabled:NO];
		[self.stopItem setEnabled:YES];
		
		[self.session startRunning];
	}
		
}
- (IBAction) stop
{
	[self.statusItem setTitle:@""];
	[self.startItem setEnabled:YES];
	[self.stopItem setEnabled:NO];
	
	[self.session stopRunning];
}


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	[self.statusItem setTitle:@""];
	[self.stopItem setEnabled:NO];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc 
{
	[session release];
    [super dealloc];
}


@end
