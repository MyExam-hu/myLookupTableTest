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
    float switchFilterPercent;
    CADisplayLink *displayLink_;
}
//相机
@property (nonatomic, strong) GPUImageVideoCamera *camera;
//输出节点
@property (nonatomic, strong) GPUImageView *showCameraView;

//切换工具类
@property (nonatomic, strong) DYSwitchFilter *switchFilter;
//自定义光效滤镜
@property (nonatomic, strong) GPUImageLookupFilter *lookUpFilter;
@property (nonatomic, strong) GPUImagePicture *lookupImg;
//高斯模糊
@property (nonatomic, strong) GPUImageGaussianBlurFilter *gaussianBlurFilter;
//ios7模糊
@property (nonatomic, strong) GPUImageiOSBlurFilter *iOSBlurFilter;
//亮度
@property (nonatomic, strong) GPUImageBrightnessFilter *brightnessFilter;
//饱和度
@property (nonatomic, strong) GPUImageSaturationFilter *saturationFilter;
//旋转
@property (nonatomic, strong) GPUImageSwirlFilter *swirlFilter;
//空滤镜
@property (nonatomic, strong) GPUImageFilter *emptyFilter;

@property (nonatomic, strong) UIPanGestureRecognizer *camPanGesture;
@property (nonatomic, strong) UISlider *progressSlider;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSArray *dataSourceList;
@property (nonatomic, strong) NSArray<GPUImageOutput<GPUImageInput> *> *filterList;

@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *leftFilter;
@property (nonatomic, strong) GPUImageOutput<GPUImageInput> *rightFilter;

@property (nonatomic, assign) NSInteger selectIndex;
@property (nonatomic, assign) OISwitchFilterDirection switchDirection;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib
    [self.view addSubview:self.showCameraView];
    [self.view addSubview:self.progressSlider];
    [self.view addSubview:self.collectionView];
    
    [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionTop];
    self.selectIndex = 0;
    
    [self.camera addTarget:self.emptyFilter];
    [self.emptyFilter addTarget:self.showCameraView];
    
    self.camPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(camPanGestureRecognizer:)];
    self.camPanGesture.delegate = self;
    [self.view addGestureRecognizer:self.camPanGesture];
    
    [self.camera startCameraCapture];
}

- (void)startSwitchFilterAnimation {
    if (switchFilterPercent > 0.5) {
        switchFilterPercent += 0.1;
        if (switchFilterPercent >= 1.0) {
            switchFilterPercent = 1.0;
            [self stopDisplayLinkAnimation];
            [self recoverFilter];
        }
    }else {
        switchFilterPercent -= 0.1;
        if (switchFilterPercent <= 0.0) {
            switchFilterPercent = 0.0;
            [self stopDisplayLinkAnimation];
            [self recoverFilter];
        }
    }
    self.switchFilter.percent = switchFilterPercent;
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

- (void)removeAllFilterTargets {
    [self.camera removeAllTargets];
    [self.switchFilter removeAllTargets];
    [self.lookupImg removeAllTargets];
    
    [self.filterList enumerateObjectsUsingBlock:^(GPUImageOutput<GPUImageInput> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeAllTargets];
    }];
}

- (void)changeSwitchTargets {
    if ((self.switchDirection == OISwitchFilterDirectionFromRightToLeft && self.selectIndex >= self.filterList.count - 1)
        ||(self.switchDirection == OISwitchFilterDirectionFromLeftToRight && self.selectIndex <= 0)) {
        //边界判断
        return;
    }
    
    if (self.switchDirection != self.switchFilter.direction) {
        [self removeAllFilterTargets];
        self.switchFilter.direction = self.switchDirection;
        
        if (self.switchDirection == OISwitchFilterDirectionFromRightToLeft) {
            //左边
            self.leftFilter = self.filterList[self.selectIndex];
            self.rightFilter = self.filterList[self.selectIndex + 1];
        }else if (self.switchDirection == OISwitchFilterDirectionFromLeftToRight) {
            self.leftFilter = self.filterList[self.selectIndex - 1];
            self.rightFilter = self.filterList[self.selectIndex];
        }
        
        if ([self.rightFilter isKindOfClass:[GPUImageLookupFilter class]]) {
            //自定义特效滤镜需要特殊处理
            [self.lookupImg addTarget:self.rightFilter atTextureLocation:1];
            [self.lookupImg processImageWithCompletionHandler:nil];
        }
        
        if ([self.leftFilter isKindOfClass:[GPUImageLookupFilter class]]) {
            //自定义特效滤镜需要特殊处理
            [self.lookupImg addTarget:self.leftFilter atTextureLocation:1];
            [self.lookupImg processImageWithCompletionHandler:nil];
        }
        
        [self.camera addTarget:self.leftFilter];
        [self.camera addTarget:self.rightFilter];
        
        [self.leftFilter addTarget:self.switchFilter];
        [self.rightFilter addTarget:self.switchFilter];
        
        [self.switchFilter addTarget:self.showCameraView];
    }
    
    self.switchFilter.percent = switchFilterPercent;
}

- (void)recoverFilter {
    [self removeAllFilterTargets];
    GPUImageOutput<GPUImageInput> * currentFilter = self.filterList[self.selectIndex];
    if (self.selectIndex == 1) {
        //自定义特效滤镜需要特殊处理
        [self.lookupImg addTarget:self.lookUpFilter atTextureLocation:1];
        [self.lookupImg processImageWithCompletionHandler:nil];
    }
    
    [self.camera addTarget:currentFilter];
    [currentFilter addTarget:self.showCameraView];
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
    [self removeAllFilterTargets];
    GPUImageOutput<GPUImageInput> * currentFilter = self.filterList[indexPath.row];
    if (indexPath.row == 1) {
        //自定义特效滤镜需要特殊处理
        [self.lookupImg addTarget:self.lookUpFilter atTextureLocation:1];
        [self.lookupImg processImageWithCompletionHandler:nil];
    }
    
    [self.camera addTarget:currentFilter];
    [currentFilter addTarget:self.showCameraView];

    self.selectIndex = indexPath.row;
}


#pragma mark -- 手势事件

- (void)camPanGestureRecognizer:(UIPanGestureRecognizer *)panGesture {
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        startPoint_ = [panGesture locationInView:panGesture.view];
    }else if(panGesture.state == UIGestureRecognizerStateChanged) {
        CGRect rect = [UIScreen mainScreen].bounds;
        CGPoint currentPoint = [panGesture locationInView:panGesture.view];
        CGFloat x = currentPoint.x - startPoint_.x;
//        CGFloat y = currentPoint.y - startPoint_.y;
        float standardX = x/(rect.size.width * 2/3);
        
        if (standardX < 0) {
            //左边
            self.switchDirection = OISwitchFilterDirectionFromRightToLeft;
            switchFilterPercent = fabsf(standardX);
        } else {
            //右边
            self.switchDirection = OISwitchFilterDirectionFromLeftToRight;
            switchFilterPercent = 1.0 - fabsf(standardX);
        }
        NSLog(@"switchDirection = %d, standardX = %lf", self.switchDirection, standardX);

        [self changeSwitchTargets];
    }else if(panGesture.state == UIGestureRecognizerStateEnded || panGesture.state == UIGestureRecognizerStateCancelled) {
        [self stopDisplayLinkAnimation];
        [self startDisplayLinkAnimation];
        
        if ((switchFilterPercent > 0.5 && self.switchDirection == OISwitchFilterDirectionFromRightToLeft)
            || (switchFilterPercent < 0.5 && self.switchDirection == OISwitchFilterDirectionFromLeftToRight)) {
            if (self.switchDirection == OISwitchFilterDirectionFromRightToLeft) {
                self.selectIndex++;
            }else if (self.switchDirection == OISwitchFilterDirectionFromLeftToRight) {
                self.selectIndex--;
            }
            
            if (self.selectIndex < 0) {
                self.selectIndex = 0;
            }else if (self.selectIndex > self.filterList.count - 1) {
                self.selectIndex = self.filterList.count - 1;
            }
            
            [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectIndex inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        }
        
        self.switchDirection = OISwitchFilterDirectionFromUnknown;
        self.switchFilter.direction = OISwitchFilterDirectionFromUnknown;
    }
}

- (void)sliderProgressChange:(UISlider *)slider {
    dispatch_async(dispatch_get_main_queue(), ^{
        GPUImageOutput<GPUImageInput> * currentFilter = self.filterList[self.selectIndex];
        if ([currentFilter isKindOfClass:[GPUImageLookupFilter class]]) {
            GPUImageLookupFilter *filter = (GPUImageLookupFilter *)currentFilter;
            filter.intensity = slider.value * 1.0;
        }else if ([currentFilter isKindOfClass:[GPUImageGaussianBlurFilter class]]) {
            GPUImageGaussianBlurFilter *filter = (GPUImageGaussianBlurFilter *)currentFilter;
            filter.blurRadiusInPixels = slider.value * 80.0;
        }else if ([currentFilter isKindOfClass:[GPUImageiOSBlurFilter class]]) {
            GPUImageiOSBlurFilter *filter = (GPUImageiOSBlurFilter *)currentFilter;
            filter.blurRadiusInPixels = slider.value * 80.0;
            filter.rangeReductionFactor = slider.value;
        }else if ([currentFilter isKindOfClass:[GPUImageBrightnessFilter class]]) {
            GPUImageBrightnessFilter *filter = (GPUImageBrightnessFilter *)currentFilter;
            filter.brightness = (slider.value - 0.5) * 2.0;
        }else if ([currentFilter isKindOfClass:[GPUImageSaturationFilter class]]) {
            GPUImageSaturationFilter *filter = (GPUImageSaturationFilter *)currentFilter;
            filter.saturation = slider.value * 2.0;
        }else if ([currentFilter isKindOfClass:[GPUImageSwirlFilter class]]) {
            GPUImageSwirlFilter *filter = (GPUImageSwirlFilter *)currentFilter;
            filter.center = CGPointMake(slider.value, slider.value);
        }
    });
}

- (void)sliderProgressEnd:(UISlider *)slider {
    
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

-(NSArray<GPUImageOutput<GPUImageInput> *> *)filterList {
    if (!_filterList) {
        _filterList = @[self.emptyFilter,
                        self.lookUpFilter,
                        self.gaussianBlurFilter,
                        self.iOSBlurFilter,
                        self.brightnessFilter,
                        self.saturationFilter,
                        self.swirlFilter
                        ];
    }
    return _filterList;
}

- (UISlider *)progressSlider {
    if (!_progressSlider) {
        CGFloat colHeight = self.collectionView.frame.size.height;
        CGRect screen = [UIScreen mainScreen].bounds;
        _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake((screen.size.width - 247) * .5f, screen.size.height - 50.0 - colHeight, 247.0, 50.0)];
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
        _camera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
        _camera.outputImageOrientation = UIInterfaceOrientationPortrait;
    }
    return _camera;
}

- (GPUImageView *)showCameraView {
    if (!_showCameraView) {
        _showCameraView = [[GPUImageView alloc] initWithFrame:self.view.bounds];;
    }
    return _showCameraView;
}

- (GPUImageGaussianBlurFilter *)gaussianBlurFilter {
    if (!_gaussianBlurFilter) {
        _gaussianBlurFilter = [[GPUImageGaussianBlurFilter alloc] init];
        _gaussianBlurFilter.blurRadiusInPixels = 0.5 * 80.0;
    }
    return _gaussianBlurFilter;
}

- (GPUImageLookupFilter *)lookUpFilter {
    if (!_lookUpFilter) {
        _lookUpFilter = [[GPUImageLookupFilter alloc] init];
        _lookUpFilter.intensity = 1.0;
    }
    return _lookUpFilter;
}

- (GPUImagePicture *)lookupImg {
    if (!_lookupImg) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"155131625201709141958art38978/892801501567939852359ba6ee4d4ad8" ofType:@"png"];
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        _lookupImg = [[GPUImagePicture alloc] initWithImage:image];
    }
    return _lookupImg;
}

- (DYSwitchFilter *)switchFilter {
    if (!_switchFilter) {
        _switchFilter = [[DYSwitchFilter alloc] init];
        _switchFilter.percent = 0.5;
        _switchFilter.direction = OISwitchFilterDirectionFromUnknown;
    }
    return _switchFilter;
}

- (GPUImageiOSBlurFilter *)iOSBlurFilter {
    if (!_iOSBlurFilter) {
        _iOSBlurFilter = [[GPUImageiOSBlurFilter alloc] init];
        _iOSBlurFilter.rangeReductionFactor = 0.5;
        _iOSBlurFilter.blurRadiusInPixels = 0.5 * 80;
    }
    return _iOSBlurFilter;
}

- (GPUImageBrightnessFilter *)brightnessFilter {
    if (!_brightnessFilter) {
        _brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
        _brightnessFilter.brightness = 0.5;
    }
    return _brightnessFilter;
}

- (GPUImageSaturationFilter *)saturationFilter {
    if (!_saturationFilter) {
        _saturationFilter = [[GPUImageSaturationFilter alloc] init];
        _saturationFilter.saturation = 1.0 * 2.0;
    }
    return _saturationFilter;
}

- (GPUImageSwirlFilter *)swirlFilter {
    if (!_swirlFilter) {
        _swirlFilter = [[GPUImageSwirlFilter alloc] init];
        _swirlFilter.center = CGPointMake(0.5, 0.5);
    }
    return _swirlFilter;
}

- (GPUImageFilter *)emptyFilter {
    if (!_emptyFilter) {
        _emptyFilter = [[GPUImageFilter alloc] init];
    }
    return _emptyFilter;
}

@end
