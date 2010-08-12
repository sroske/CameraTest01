//
//  CameraVC.m
//  CameraTest01
//
//  Created by Shawn Roske on 7/25/10.
//  Copyright 2010 Bitgun. All rights reserved.
//

#import "CameraVC.h"

@interface CameraVC (Private)

- (CGImageRef)CGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angle;

- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image;
- (UIImage *)UIImageFromIplImage:(IplImage *)image;

- (void) opencvFaceDetect:(UIImage *)overlayImage;

@end


@implementation CameraVC

@synthesize imageView;
@synthesize debugView;
@synthesize squareView;

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
		
		// select the front-facing camera if present, otherwise use the normal camera
		AVCaptureDevice *device = NULL;
		NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
		if ( [devices count] > 1 )
			device = (AVCaptureDevice *)[devices lastObject];
		else
			device = (AVCaptureDevice *)[devices objectAtIndex:0];
		
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
		output.minFrameDuration = CMTimeMake(1, 10);
		
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
	UIImage *image = [UIImage imageWithCGImage:[self CGImageRotatedByAngle:newImage angle:-90.0f]];
	self.imageView.image = image;
	
	/*We relase the CGImageRef*/
	CGImageRelease(newImage);
	
	[self opencvFaceDetect:NULL];
}

- (CGImageRef)CGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angle
{
	CGFloat angleInRadians = angle * (M_PI / 180);
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGRect imgRect = CGRectMake(0, 0, width, height);
	CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
	CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef bmContext = CGBitmapContextCreate(NULL,
												   rotatedRect.size.width,
												   rotatedRect.size.height,
												   8,
												   0,
												   colorSpace,
												   kCGImageAlphaPremultipliedFirst);
	CGContextSetAllowsAntialiasing(bmContext, FALSE);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationNone);
	CGColorSpaceRelease(colorSpace);
	CGContextTranslateCTM(bmContext,
						  +(rotatedRect.size.width/2),
						  +(rotatedRect.size.height/2));
	CGContextRotateCTM(bmContext, angleInRadians);
	CGContextTranslateCTM(bmContext,
						  -(rotatedRect.size.width/2),
						  -(rotatedRect.size.height/2));
	CGContextDrawImage(bmContext, CGRectMake(0, 0,
											 rotatedRect.size.width,
											 rotatedRect.size.height),
					   imgRef);
	
	CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
	CFRelease(bmContext);
	[(id)rotatedImage autorelease];
	
	return rotatedImage;
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
	
	[self.view addSubview:self.squareView];
	
	// Load XML
	NSString *path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
	cascade = (CvHaarClassifierCascade*)cvLoad([path cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL, NULL);
	storage = cvCreateMemStorage(0);
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
	cvReleaseMemStorage(&storage);
	cvReleaseHaarClassifierCascade(&cascade);
	[session release];
    [super dealloc];
}

#pragma mark -
#pragma mark OpenCV Support Methods

/*
- (void) opencvFaceDetect:(UIImage *)overlayImage  {
	if(imageView.image) {
		cvSetErrMode(CV_ErrModeParent);
		
		IplImage *image = [self CreateIplImageFromUIImage:imageView.image];
		
		int scale = 8;
		
		// Scaling down
		IplImage *small_image = cvCreateImage(cvSize(image->width/scale,image->height/scale), IPL_DEPTH_8U, 3);
		cvResize( image, small_image, CV_INTER_NN );
		//cvPyrDown(image, small_image, CV_GAUSSIAN_5x5);
		
		// Detect faces and draw rectangle on them
		CvSeq* faces = cvHaarDetectObjects(small_image, cascade, storage, 1.2f, 2, CV_HAAR_DO_CANNY_PRUNING, cvSize(20, 20));
		cvReleaseImage(&small_image);
		
		// Create canvas to show the results
		CGImageRef imageRef = imageView.image.CGImage;
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef contextRef = CGBitmapContextCreate(NULL, imageView.image.size.width, imageView.image.size.height,
														8, imageView.image.size.width * 4,
														colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
		CGContextDrawImage(contextRef, CGRectMake(0, 0, imageView.image.size.width, imageView.image.size.height), imageRef);
		
		CGContextSetLineWidth(contextRef, 4);
		CGContextSetRGBStrokeColor(contextRef, 0.0, 0.0, 1.0, 0.5);
		
		// Draw results on the iamge
		for(int i = 0; i < faces->total; i++) {
			NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
			
			// Calc the rect of faces
			CvRect cvrect = *(CvRect*)cvGetSeqElem(faces, i);
			CGRect face_rect = CGContextConvertRectToDeviceSpace(contextRef, CGRectMake(cvrect.x * scale, cvrect.y * scale, cvrect.width * scale, cvrect.height * scale));
			
			if(overlayImage) {
				CGContextDrawImage(contextRef, face_rect, overlayImage.CGImage);
			} else {
				CGContextStrokeRect(contextRef, face_rect);
			}
			
			[pool release];
		}
		
		imageView.image = [UIImage imageWithCGImage:CGBitmapContextCreateImage(contextRef)  scale:1.0 orientation:UIImageOrientationRight];
		
		cvReleaseImage(&image);
		CGContextRelease(contextRef);
		CGColorSpaceRelease(colorSpace);
	}
}*/

- (void) opencvFaceDetect:(UIImage *)overlayImage  
{
	if(imageView.image) 
	{
		cvSetErrMode(CV_ErrModeParent);
		
		IplImage *image = [self CreateIplImageFromUIImage:imageView.image];
		
		int scale = 2;
		
		// scaling down
		IplImage *small_image = cvCreateImage(cvSize(image->width/scale,image->height/scale), IPL_DEPTH_8U, 3);
		//cvResize( image, small_image, CV_INTER_NN );
		cvPyrDown(image, small_image, CV_GAUSSIAN_5x5);
		
		// detect faces and draw rectangle on them
		CvSeq* faces = cvHaarDetectObjects(small_image, cascade, storage, 1.2f, 2, CV_HAAR_DO_CANNY_PRUNING, cvSize(20, 20));
		
		IplImage *preview_small = cvCreateImage(cvSize(image->width/scale,image->height/scale), IPL_DEPTH_8U, 3);;
		
		cvCvtColor( small_image, preview_small, CV_BGR2RGB );
		UIImage *small = [self UIImageFromIplImage:preview_small];
		[self.debugView setImage:small];
		
		cvReleaseImage(&image);
		cvReleaseImage(&small_image);
		cvReleaseImage(&preview_small);

		for( int i = 0; i < faces->total; i++ ) 
		{
			CvRect r = *(CvRect*)cvGetSeqElem(faces, i);
			//CGRect rect = CGContextConvertRectToDeviceSpace(contextRef, CGRectMake(r.x * scale, r.y * scale, r.width * scale, r.height * scale));
			NSLog(@"face[%i]: {%i, %i, %i, %i}", i, r.x, r.y, r.width, r.height);
			[self.squareView setFrame:CGRectMake(r.x*2.0f, r.y*2.0f, r.width*2.0f, r.height*2.0f)];
		}			

		[self.squareView setHidden:(faces->total == 0)];

	}
}


// NOTE you SHOULD cvReleaseImage() for the return value when end of the code.
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image 
{
	CGImageRef imageRef = image.CGImage;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	IplImage *iplimage = cvCreateImage(cvSize(image.size.width, image.size.height), IPL_DEPTH_8U, 4);
	CGContextRef contextRef = CGBitmapContextCreate(iplimage->imageData, iplimage->width, iplimage->height,
													iplimage->depth, iplimage->widthStep,
													colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault);
	CGContextDrawImage(contextRef, CGRectMake(0, 0, image.size.width, image.size.height), imageRef);
	CGContextRelease(contextRef);
	CGColorSpaceRelease(colorSpace);
	
	IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
	cvCvtColor(iplimage, ret, CV_RGBA2BGR);
	cvReleaseImage(&iplimage);
	
	return ret;
}

// NOTE You should convert color mode as RGB before passing to this function
- (UIImage *)UIImageFromIplImage:(IplImage *)image 
{	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSData *data = [NSData dataWithBytes:image->imageData length:image->imageSize];
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(image->width, image->height,
										image->depth, image->depth * image->nChannels, image->widthStep,
										colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
										provider, NULL, false, kCGRenderingIntentDefault);
	UIImage *ret = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	return ret;
}

@end
