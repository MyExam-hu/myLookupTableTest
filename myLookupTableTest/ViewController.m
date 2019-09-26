//
//  ViewController.m
//  myLookupTableTest
//
//  Created by duoyi on 2019/7/22.
//  Copyright © 2019 duoyi. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage.h>
#import "DYSwitchFilter.h"
#import "TitleCell.h"

@interface ViewController ()<UIGestureRecognizerDelegate,UICollectionViewDelegate,UICollectionViewDataSource>{
    CGPoint startPoint_;
    float switchFilterPercent_;
    CADisplayLink *displayLink_;
}

@property (nonatomic, strong) GPUImageVideoCamera *camera;

//@property (nonatomic, strong) DYSwitchFilter *switchFilter;
@property (nonatomic, strong) DYSwitchFilter *switchFilter;
@property (nonatomic, strong) GPUImageRGBFilter *redFilter;
@property (nonatomic, strong) GPUImageRGBFilter *blueFilter;

@property (nonatomic, strong) UIPanGestureRecognizer *camPanGesture;
@property (nonatomic, strong) UISlider *progressSlider;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSArray *dataSourceList;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib
    GPUImageView *imageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:imageView];
    [self.view addSubview:self.progressSlider];
    [self.view addSubview:self.collectionView];
    
    [self.camera addTarget:self.redFilter];
    [self.camera addTarget:self.blueFilter];
    
    [self.redFilter addTarget:self.switchFilter];
    [self.blueFilter addTarget:self.switchFilter];
    
    [self.switchFilter addTarget:imageView];
    
    [self.camera startCameraCapture];
    
    self.camPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(camPanGestureRecognizer:)];
    self.camPanGesture.delegate = self;
    [self.view addGestureRecognizer:self.camPanGesture];
    
    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionTop];
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

- (void)startSwitchFilterAnimation
{
    if (switchFilterPercent_ > 0.5) {
        switchFilterPercent_ += 0.1;
        if (switchFilterPercent_ >= 1.0) {
            switchFilterPercent_ = 1.0;
            [self stopDisplayLinkAnimation];
        }
    }else {
        switchFilterPercent_ -= 0.1;
        if (switchFilterPercent_ <= 0.0) {
            switchFilterPercent_ = 0.0;
            [self stopDisplayLinkAnimation];
        }
    }
    self.switchFilter.percent = switchFilterPercent_;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.progressSlider.value = 1.0 - self->switchFilterPercent_;
    });
}

- (void)startDisplayLinkAnimation {
    displayLink_ = [CADisplayLink displayLinkWithTarget:self selector:@selector(startSwitchFilterAnimation)];
    displayLink_.frameInterval = 2;
    [displayLink_ addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopDisplayLinkAnimation {
    if (displayLink_) {
        [displayLink_ invalidate];
    }
}

#pragma mark -- 懒加载

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        CGRect rect = [UIScreen mainScreen].bounds;
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(60.0, 60.0);
        layout.minimumLineSpacing = 5.0;
        layout.minimumInteritemSpacing = 5.0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0);
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0.0, rect.size.height - 70.0, rect.size.width, 70.0) collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        [_collectionView registerClass:[TitleCell class] forCellWithReuseIdentifier:NSStringFromClass([TitleCell class])];
    }
    return _collectionView;
}

- (NSArray *)dataSourceList {
    if (!_dataSourceList) {
        _dataSourceList = @[@"无效果",@"自定义光效",@"高斯模糊",@"ios7模糊",@"亮度",@"饱和度",@"旋转"];
    }
    return _dataSourceList;
}

- (GPUImageRGBFilter *)blueFilter {
    if (!_blueFilter) {
        _blueFilter = [[GPUImageRGBFilter alloc] init];
        _blueFilter.red = 0.0;
        _blueFilter.green = 0.0;
        _blueFilter.blue = 1.0;
    }
    return _blueFilter;
}

- (GPUImageRGBFilter *)redFilter {
    if (!_redFilter) {
        _redFilter = [[GPUImageRGBFilter alloc] init];
        _redFilter.red = 1.0;
        _redFilter.green = 0.0;
        _redFilter.blue = 0.0;
    }
    return _redFilter;
}

- (UISlider *)progressSlider {
    if (!_progressSlider) {
        CGRect screen = [UIScreen mainScreen].bounds;
        _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake((screen.size.width - 247) * .5f, screen.size.height*.5f- 50*.5f, 247, 50)];
        _progressSlider.maximumValue = 1.0;
        _progressSlider.minimumValue = 0.0;
        _progressSlider.value = 0.5;
        [_progressSlider addTarget:self action:@selector(sliderProgressChange:) forControlEvents:UIControlEventValueChanged];
        [_progressSlider addTarget:self
                                action:@selector(sliderProgressEnd:)
                      forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
    }
    return _progressSlider;
}

- (GPUImageVideoCamera *)camera {
    if (!_camera) {
        _camera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetMedium cameraPosition:AVCaptureDevicePositionBack];
        _camera.outputImageOrientation = UIInterfaceOrientationPortrait;
    }
    return _camera;
}

- (DYSwitchFilter *)switchFilter {
    if (!_switchFilter) {
        _switchFilter = [[DYSwitchFilter alloc] init];
        _switchFilter.percent = 0.5;
    }
    return _switchFilter;
}


#pragma mark -- UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSourceList.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TitleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([TitleCell class]) forIndexPath:indexPath];
    cell.titleStr = self.dataSourceList[indexPath.row];
    return cell;
}


#pragma mark -- UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}


#pragma mark -- 手势事件

- (void)camPanGestureRecognizer:(UIPanGestureRecognizer *)panGesture {
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        startPoint_ = [panGesture locationInView:panGesture.view];
    }else if(panGesture.state == UIGestureRecognizerStateChanged) {
        CGPoint currentPoint = [panGesture locationInView:panGesture.view];
        CGFloat x = currentPoint.x - startPoint_.x;
        CGFloat y = currentPoint.y - startPoint_.y;
        NSLog(@"x = %lf,y = %lf", x, y);
        
        CGRect rect = [UIScreen mainScreen].bounds;
        CGFloat markWidth = rect.size.width/2.0;
        if (x > 0.0) {
            //右边
            //            switchFilterPercent_ = x/markWidth;
        }else {
            //左边
        }
        
    }else if(panGesture.state == UIGestureRecognizerStateEnded || panGesture.state == UIGestureRecognizerStateCancelled) {
        
    }
}

- (void)sliderProgressChange:(UISlider *)slider {
    self.switchFilter.percent = 1.0 - slider.value;
    switchFilterPercent_ = self.switchFilter.percent;
}

- (void)sliderProgressEnd:(UISlider *)slider {
    [self stopDisplayLinkAnimation];
    [self startDisplayLinkAnimation];
    NSLog(@"sliderProgressEnd");
}

@end
