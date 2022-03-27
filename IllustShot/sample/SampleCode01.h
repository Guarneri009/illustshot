@interface TestOpenCVViewController : UIViewController
{
    IBOutlet UIImageView *cameraPreviewImageView;
    AVCaptureSession* session;
}

@property(strong, nonatomic) AVCaptureSession *session;
@property(strong, nonatomic) UIImageView *cameraPreviewImageView;

@end