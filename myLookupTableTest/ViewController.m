//
//  ViewController.m
//  myLookupTableTest
//
//  Created by duoyi on 2019/7/22.
//  Copyright © 2019 duoyi. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    CGRect screen = [UIScreen mainScreen].bounds;
    
    UIImage *image = [UIImage imageNamed:@"weixin_popover"];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    imageView.center = CGPointMake(screen.size.width/2.0, screen.size.height/2.0);
    [self.view addSubview:imageView];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *filterImage = [self applyFIlter:image];
        dispatch_sync(dispatch_get_main_queue(), ^{
            imageView.image = filterImage;
        });
    });
}

- (UIImage *)applyFIlter:(UIImage *)originalImg {
    UIImage *inputImage = originalImg;
    UIImage *outputImage = nil;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"155131625201709141958art38978/892801501567939852359ba6ee4d4ad8" ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    GPUImagePicture *lookupImg = [[GPUImagePicture alloc] initWithImage:image];
    
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:inputImage];
    
    GPUImageLookupFilter *lookUpFilter = [[GPUImageLookupFilter alloc] init];
    lookUpFilter.intensity = 1.0;
    
    [lookupImg addTarget:lookUpFilter atTextureLocation:1];
    [stillImageSource addTarget:lookUpFilter atTextureLocation:0];
    [lookUpFilter useNextFrameForImageCapture];
    
    if([lookupImg processImageWithCompletionHandler:nil] && [stillImageSource processImageWithCompletionHandler:nil]) {
        outputImage = [lookUpFilter imageFromCurrentFramebuffer];
    }
    
    return outputImage;
}

@end
