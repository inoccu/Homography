//
//  ViewController.h
//  Homography
//
//  Created by 井上 研一 on 2014/02/24.
//  Copyright (c) 2014年 Artisan Edge LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UIImagePickerController *picker;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) UIView *view1;
@property (nonatomic, weak) UIView *view2;
@property (nonatomic, weak) UIView *view3;
@property (nonatomic, weak) UIView *view4;

- (IBAction)cameraButtonPushed:(id)sender;
- (IBAction)decideButtonPushed:(id)sender;

@end
