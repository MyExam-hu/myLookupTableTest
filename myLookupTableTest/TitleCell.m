//
//  TitleCell.m
//  myLookupTableTest
//
//  Created by duoyi on 2019/9/26.
//  Copyright © 2019 duoyi. All rights reserved.
//

#import "TitleCell.h"

@interface TitleCell()

@property (nonatomic, strong) UILabel *myTitleLable;

@end

@implementation TitleCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.myTitleLable = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.myTitleLable.textColor = [UIColor redColor];
        self.myTitleLable.textAlignment = NSTextAlignmentCenter;
        self.myTitleLable.numberOfLines = 0;
        [self addSubview:self.myTitleLable];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        self.backgroundColor = [UIColor blueColor];
    }else {
        self.backgroundColor = [UIColor clearColor];
    }
}

-(void)setTitleStr:(NSString *)titleStr {
    _titleStr = titleStr;
    self.myTitleLable.text = titleStr;
}

@end
