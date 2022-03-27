//
//  ViewController.h
//  IllustShot
//
//  Created by beehitsuji on 2013/04/27.
//  Copyright (c) 2013年 catandbeesheep. All rights reserved.
//

/*
#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@end
*/
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
 
@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
 
@end