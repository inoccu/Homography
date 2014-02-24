//
//  ViewController.m
//  Homography
//
//  Created by 井上 研一 on 2014/02/24.
//  Copyright (c) 2014年 Artisan Edge LLC. All rights reserved.
//
// http://cflat-inc.hatenablog.com/entry/2014/01/14/204911

#import "ViewController.h"

@interface ViewController ()
{
    std::vector<cv::Point2f> m_selected_pnts;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.imageView.image = nil;
    self.imageView.contentMode = UIViewContentModeScaleToFill;
    m_selected_pnts.clear();
    
    self.view1 = [self viewWithRect:CGRectMake(40, 40, 60, 60) withColor:[UIColor colorWithRed:0 green:0 blue:1 alpha:0.5]];
    self.view2 = [self viewWithRect:CGRectMake(40, 300, 60, 60) withColor:[UIColor colorWithRed:0 green:1 blue:0 alpha:0.5]];
    self.view3 = [self viewWithRect:CGRectMake(200, 300, 60, 60) withColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:0.5]];
    self.view4 = [self viewWithRect:CGRectMake(200, 40, 60, 60) withColor:[UIColor colorWithRed:1 green:1 blue:0 alpha:0.5]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.view1 removeFromSuperview];
    [self.view2 removeFromSuperview];
    [self.view3 removeFromSuperview];
    [self.view4 removeFromSuperview];
}

- (UIView *)viewWithRect:(CGRect)rect withColor:(UIColor *)color
{
    UIView *view = [[UIView alloc] initWithFrame:rect];
    view.backgroundColor = color;
    [self.imageView addSubview:view];
    
    CGFloat len = 4;
    UIView *p = [[UIView alloc] initWithFrame:CGRectMake(0.5 * (rect.size.width - len), 0.5 * (rect.size.height - len), len, len)];
    p.backgroundColor = color;
    [view addSubview:p];
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragView:)];
    [view addGestureRecognizer:panGestureRecognizer];
    
    return view;
}

- (void)dragView:(UIPanGestureRecognizer *)sender
{
    UIView *targetView = sender.view;
    CGPoint p = [sender translationInView:targetView];
    CGPoint movedPoint = CGPointMake(targetView.center.x + p.x, targetView.center.y + p.y);
    targetView.center = movedPoint;
    [sender setTranslation:CGPointZero inView:targetView];
}

- (IBAction)cameraButtonPushed:(id)sender
{
    self.picker = [[UIImagePickerController alloc] init];
    self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.picker.delegate = self;
    [self presentViewController:self.picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.picker dismissViewControllerAnimated:YES completion:nil];
    self.imageView.image = [info objectForKey:UIImagePickerControllerOriginalImage];
}

- (UIImage *)projectiveTransform:(UIImage *)image
{
    CGFloat min_x = FLT_MAX;
    CGFloat max_x = FLT_MIN;
    CGFloat min_y = FLT_MAX;
    CGFloat max_y = FLT_MIN;
    
    for (auto it = m_selected_pnts.begin(); it != m_selected_pnts.end(); ++it) {
        min_x = MIN(min_x, it->x);
        max_x = MAX(max_x, it->x);
        min_y = MIN(min_y, it->y);
        max_y = MAX(max_y, it->y);
    }
    
    std::vector<cv::Point2f> dst_pnts;
    dst_pnts.push_back(cv::Point2f(min_x, min_y));
    dst_pnts.push_back(cv::Point2f(min_x, max_y));
    dst_pnts.push_back(cv::Point2f(max_x, max_y));
    dst_pnts.push_back(cv::Point2f(max_x, min_y));
    
    cv::Mat status;
    cv::Mat H = cv::findHomography(cv::Mat(m_selected_pnts), cv::Mat(dst_pnts), status);
    
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    cv::Mat inputImg;
    inputImg = [self cvMatFromUIImage:image];
    
    cv::Mat warpImg;
    cv::warpPerspective(inputImg, warpImg, H, inputImg.size());
    return [self UIImageFromCVMat:warpImg];
}

// http://docs.opencv.org/doc/tutorials/ios/image_manipulation/image_manipulation.html
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
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
    
    return cvMat;
}

// http://docs.opencv.org/doc/tutorials/ios/image_manipulation/image_manipulation.html
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

- (CGPoint)coordinateForCGImage:(UIImageView *)imageView coordinate:(CGPoint)coordinate
{
    CGImageRef cgImage = imageView.image.CGImage;
    CGFloat imageWidth = CGImageGetWidth(cgImage);
    CGFloat imageHeight = CGImageGetHeight(cgImage);
    float scaleY = imageWidth / imageView.frame.size.height;
    float scaleX = imageHeight / imageView.frame.size.width;
    return CGPointMake(coordinate.x * scaleX, coordinate.y * scaleY);
}

- (IBAction)decideButtonPushed:(id)sender
{
    CGPoint p1 = [self coordinateForCGImage:self.imageView coordinate:self.view1.center];
    CGPoint p2 = [self coordinateForCGImage:self.imageView coordinate:self.view2.center];
    CGPoint p3 = [self coordinateForCGImage:self.imageView coordinate:self.view3.center];
    CGPoint p4 = [self coordinateForCGImage:self.imageView coordinate:self.view4.center];
    
    m_selected_pnts.push_back(cv::Point2f(p1.x, p1.y));
    m_selected_pnts.push_back(cv::Point2f(p2.x, p2.y));
    m_selected_pnts.push_back(cv::Point2f(p3.x, p3.y));
    m_selected_pnts.push_back(cv::Point2f(p4.x, p4.y));
    
    self.imageView.image = [self projectiveTransform:self.imageView.image];
    m_selected_pnts.clear();
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
