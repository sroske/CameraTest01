//
//  CameraTest01AppDelegate.h
//  CameraTest01
//
//  Created by Shawn Roske on 7/25/10.
//  Copyright Bitgun 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraVC.h"

@interface CameraTest01AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	CameraVC *camera;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) CameraVC *camera;

@end

