//
//  CameraVC.h
//  CameraTest01
//
//  Created by Shawn Roske on 7/25/10.
//  Copyright 2010 Bitgun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraImageView.h"

@interface CameraVC : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate> {
	UIImageView *imageView;
	AVCaptureSession *session;
	UIBarButtonItem	*statusItem;
	UIBarButtonItem	*startItem;
	UIBarButtonItem	*stopItem;
}

@property (nonatomic, retain) IBOutlet UIBarButtonItem *statusItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *startItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *stopItem;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) AVCaptureSession *session;

- (IBAction) start;
- (IBAction) stop;

@end