using namespace cv;

@interface TestOpenCVViewController ()

@end

@implementation TestOpenCVViewController

@synthesize session;
@synthesize cameraPreviewImageView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"viewDidLoad");
    // Do any additional setup after loading the view from its nib.
    // ビデオキャプチャデバイスの取得
    AVCaptureDevice*    device;
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // オートフォーカスモードを解消
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            [device unlockForConfiguration];
        }
    }
    // デバイス入力の取得
    AVCaptureDeviceInput*   deviceInput;
    deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:NULL];
    // ビデオデータ出力の作成
    NSMutableDictionary*        settings;
    AVCaptureVideoDataOutput*   dataOutput;
    settings = [NSMutableDictionary dictionary];
    [settings setObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                 forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    //    [dataOutput autorelease];
    dataOutput.videoSettings = settings;
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    // セッションの作成
    self.session = [[AVCaptureSession alloc] init];
    // 画質の制御
    self.session.sessionPreset = AVCaptureSessionPreset640x480;
    [self.session addInput:deviceInput];
    [self.session addOutput:dataOutput];
    
    // ステータスバーを隠す
    [UIApplication sharedApplication].statusBarHidden = YES;
    self.view.bounds = [UIScreen mainScreen].bounds;
    
    // カメラの開始
    [self.session startRunning];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/***** カメラの動作 *****/
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // キャプチャしたフレームからCGImageを作成
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    cv::Mat imageMat = [self cvMatFromUIImage:image];
    
    /* あとはimageMatをOpenCVで煮るなり焼くなり */
    
    image = [self UIImageFromCVMat:imageMat];
    cameraPreviewImageView.image = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationUp];
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
    //    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

- (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
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
                                        cvMat.step[0],                              //bytesPerRow
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