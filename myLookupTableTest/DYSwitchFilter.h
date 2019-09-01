//
//  DYSwitchFilter.h
//  myLookupTableTest
//
//  Created by duoyi on 2019/8/22.
//  Copyright © 2019 duoyi. All rights reserved.
//

#import "GPUImageTwoInputFilter.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, OISwitchFilterDirection) {
    OISwitchFilterDirectionFromLeftToRight = 0, // 从左到右
    OISwitchFilterDirectionFromRightToLeft,     // 从右到左
    OISwitchFilterDirectionFromDownToUp,        // 从下到上
    OISwitchFilterDirectionFromUpToDown         // 从上到下
};

@interface DYSwitchFilter : GPUImageTwoInputFilter {
    GLint percentUniform, directionUniform;
}

@property (nonatomic, assign) float percent;
@property (nonatomic, assign) OISwitchFilterDirection direction;

@property (nonatomic, assign, getter =isFirstFilterVisible) BOOL firstFilterVisible;

@end

NS_ASSUME_NONNULL_END
