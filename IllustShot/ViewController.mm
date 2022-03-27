//
//  ViewController.m
//  IllustShot
//
//  Created by beehitsuji on 2013/04/27.
//  Copyright (c) 2013年 catandbeesheep. All rights reserved.
//

/*
#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
*/
#import "ViewController.h"
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>
#import <CoreGraphics/CoreGraphics.h>

#import "GLESImageView.h"
#import "EdgeDetectionSample.h"


@interface ViewController ()
{
    cv::Mat outputFrame;
	EdgeDetectionSample * sample;
}

@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) UIImageView *previewImageView;

@property (strong, nonatomic) UIView *containerView;
@property (nonatomic, strong) GLESImageView *imageView;
//@property (strong, nonatomic) UIImage *peView;

@end
 
@implementation ViewController
 
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	sample = new EdgeDetectionSample();
    
    //UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Hello!" message:@"Welcome to OpenCV" delegate:self cancelButtonTitle:@"Continue" otherButtonTitles:nil];
    //[alert show];
    
    
    // 撮影ボタンを配置したツールバーを生成
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
     
    UIBarButtonItem *takePhotoButton = [[UIBarButtonItem alloc] initWithTitle:@"撮影"
                                                                        style:UIBarButtonItemStyleBordered
                                                                       target:self
                                                                       action:@selector(takePhoto:)];
    toolbar.items = @[takePhotoButton];
    [self.view addSubview:toolbar];
    
    /*
    // プレビュー用のビューを生成
    self.previewImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,
                                                                          toolbar.frame.size.height,
                                                                          self.view.bounds.size.width,
                                                                          self.view.bounds.size.height - toolbar.frame.size.height)];
    [self.view addSubview:self.previewImageView];
    */
    // Init the default view (video view layer)
	//(ORG)self.imageView = [[GLESImageView alloc] initWithFrame:self.containerView.bounds];
    self.imageView = [[GLESImageView alloc] initWithFrame:CGRectMake(0,
                                                                     toolbar.frame.size.height,
                                                                     self.view.bounds.size.width,
                                                                     self.view.bounds.size.height - toolbar.frame.size.height)];

	
	
	[self.imageView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
    [self.view addSubview:self.imageView];
    
    // 撮影開始
    [self setupAVCapture];
}
 
- (void)setupAVCapture
{
    NSError *error = nil;
     
    // 入力と出力からキャプチャーセッションを作成
    self.session = [[AVCaptureSession alloc] init];
     
    self.session.sessionPreset = AVCaptureSessionPresetMedium;
     
    // カメラからの入力を作成
    AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
     
    // カメラからの入力を作成し、セッションに追加
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
    [self.session addInput:self.videoInput];
     
    // 画像への出力を作成し、セッションに追加
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.session addOutput:self.videoDataOutput];
     
    // ビデオ出力のキャプチャの画像情報のキューを設定
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:TRUE];
    [self.videoDataOutput setSampleBufferDelegate:self queue:queue];
     
    // ビデオへの出力の画像は、BGRAで出力
    self.videoDataOutput.videoSettings = @{
      (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
    };
     
    // ビデオ入力のAVCaptureConnectionを取得
    AVCaptureConnection *videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
     
    // 1秒あたり4回画像をキャプチャ
    videoConnection.videoMinFrameDuration = CMTimeMake(1, 30);
     
    [self.session startRunning];
}
 
// AVCaptureVideoDataOutputSampleBufferDelegateプロトコルのメソッド。新しいキャプチャの情報が追加されたときに呼び出される。
/*
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // キャプチャしたフレームからCGImageを作成
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
     
    //追加
    outputFrame = [self cvMatGrayFromUIImage:image];
    image = [self UIImageFromCVMat:outputFrame];
    

    // 画像を画面に表示
    dispatch_async(dispatch_get_main_queue(), ^{
        self.previewImageView.image = image;
    });
}
*/
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
       fromConnection:(AVCaptureConnection *)connection 
{ 

  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  
  // Lock the image buffer
  CVPixelBufferLockBaseAddress(imageBuffer,0); 
  
  // Get information about the image
  uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer); 
  size_t width = CVPixelBufferGetWidth(imageBuffer); 
  size_t height = CVPixelBufferGetHeight(imageBuffer);  
  size_t stride = CVPixelBufferGetBytesPerRow(imageBuffer);
  
  cv::Mat frame(height, width, CV_8UC4, (void*)baseAddress, stride);

  //if ([self videoOrientation] == AVCaptureVideoOrientationLandscapeLeft)
  //{
  //  cv::flip(frame, frame, 0);
  //}
  
  /*
  cv::Vec4b tlPixel = frame.at<cv::Vec4b>(0,0);
  cv::Vec4b trPixel = frame.at<cv::Vec4b>(0,width - 1);
  cv::Vec4b blPixel = frame.at<cv::Vec4b>(height-1, 0);
  cv::Vec4b brPixel = frame.at<cv::Vec4b>(height-1, width - 1);


  std::cout << "TL: " << (int)tlPixel[0] << " " << (int)tlPixel[1] << " " << (int)tlPixel[2] << std::endl
            << "TR: " << (int)trPixel[0] << " " << (int)trPixel[1] << " " << (int)trPixel[2] << std::endl
            << "BL: " << (int)blPixel[0] << " " << (int)blPixel[1] << " " << (int)blPixel[2] << std::endl
            << "BR: " << (int)brPixel[0] << " " << (int)brPixel[1] << " " << (int)brPixel[2] << std::endl;
  */
  //[delegate frameCaptured:frame];
  

	//浅いコピー
	//outputFrame = frame;
	//グレイスケール画像に変換
	//cvtColor(frame, outputFrame, CV_RGB2GRAY);  
	
    // 画像を画面に表示
    bool isMainQueue = dispatch_get_current_queue() == dispatch_get_main_queue();

	if (isMainQueue)
    {
        NSLog(@"in01");
        sample->processFrame2(frame, outputFrame);
        [self.imageView drawFrame:outputFrame];
    }
    else
    {
        dispatch_sync( dispatch_get_main_queue(),
                      ^{
                          sample->processFrame2(frame, outputFrame);
                          [self.imageView drawFrame:outputFrame];
                      }
                      );
    }

    /*We unlock the  image buffer*/
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
} 




 
// サンプルバッファのデータからCGImageRefを生成する
- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
     
    // ピクセルバッファのベースアドレスをロックする
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
     
    // Get information of the image
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
     
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
     
    // RGBの色空間
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
     
    CGContextRef newContext = CGBitmapContextCreate(baseAddress,
                                                    width,
                                                    height,
                                                    8,
                                                    bytesPerRow,
                                                    colorSpace,
                                                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
     
    CGImageRef cgImage = CGBitmapContextCreateImage(newContext);
     
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
     
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
     
    
    CGImageRelease(cgImage);
     
    return image;
}
 
- (void)takePhoto:(id)sender
{
    //AudioServicesPlaySystemSound(1108);
     
    // アルバムに画像を保存
    //UIImageWriteToSavedPhotosAlbum(self.previewImageView.image, self, nil, nil);
	
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	UIImage *glViewImageCaptue = [_imageView drawableToCGImage];
	
	UIGraphicsBeginImageContext(screenRect.size);
	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	[self.view.layer renderInContext:ctx];
	
	[glViewImageCaptue drawInRect:screenRect];
	
	UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	UIImageWriteToSavedPhotosAlbum(viewImage, self, nil, nil);
	 
}

/*
//convert from UIImage to cv:Mat
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;

  cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels

  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                 cols,                       // Width of bitmap
                                                 rows,                       // Height of bitmap
                                                 8,                          // Bits per component
                                                 cvMat.step[0],              // Bytes per row
                                                 colorSpace,                 // Colorspace
                                                 kCGImageAlphaNoneSkipLast |
                                                 kCGBitmapByteOrderDefault); // Bitmap info flags

  CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
  CGContextRelease(contextRef);
  CGColorSpaceRelease(colorSpace);

  return cvMat;
}

- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;

  cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels

  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                 cols,                       // Width of bitmap
                                                 rows,                       // Height of bitmap
                                                 8,                          // Bits per component
                                                 cvMat.step[0],              // Bytes per row
                                                 colorSpace,                 // Colorspace
                                                 kCGImageAlphaNoneSkipLast |
                                                 kCGBitmapByteOrderDefault); // Bitmap info flags

  CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
  CGContextRelease(contextRef);
  CGColorSpaceRelease(colorSpace);

  return cvMat;
 }
 
 -(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
  NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
  CGColorSpaceRef colorSpace;

  if (cvMat.elemSize() == 1) {
      colorSpace = CGColorSpaceCreateDeviceGray();
  } else {
      colorSpace = CGColorSpaceCreateDeviceRGB();
  }

  CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

  // Creating CGImage from cv::Mat
  CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                     cvMat.rows,                                 //height
                                     8,                                          //bits per component
                                     8 * cvMat.elemSize(),                       //bits per pixel
                                     cvMat.step[0],                            //bytesPerRow
                                     colorSpace,                                 //colorspace
                                     kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                     provider,                                   //CGDataProviderRef
                                     NULL,                                       //decode
                                     false,                                      //should interpolate
                                     kCGRenderingIntentDefault                   //intent
                                     );


  // Getting UIImage from CGImage
  UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
  CGImageRelease(imageRef);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpace);

  return finalImage;
}
*/
@end
