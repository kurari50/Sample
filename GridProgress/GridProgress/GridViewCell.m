//
//  GridViewCell.m
//  GridProgress
//
//  Created by kura on 2017/01/09.
//  Copyright © 2017年 kura. All rights reserved.
//

#import "GridViewCell.h"
#import "DOLinearLayout.h"
#import "CircleProgress.h"

@interface GridViewCell ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *currentValueLabel;
@property (nonatomic) UILabel *maxValueLabel;
@property (nonatomic) UILabel *progressLabel;

@property (nonatomic) CircleProgress *circleProgress;

@end

@implementation GridViewCell

- (void)setup
{
    self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    
    self.do_enableLinearLayout = YES;
    
    DOLinearLayout *linearLayout = [[DOLinearLayout alloc] init];
    linearLayout.do_weight = 1;
    linearLayout.layoutOrientation = DOLinearLayoutOrientationVertical;
    linearLayout.layoutGravity = DOLinearLayoutGravityCenter;
    [self addSubview:linearLayout];
    
    self.titleLabel = [[UILabel alloc] init];
    self.currentValueLabel = [[UILabel alloc] init];
    self.maxValueLabel = [[UILabel alloc] init];
    self.progressLabel = [[UILabel alloc] init];
    self.progressLabel.textAlignment = NSTextAlignmentCenter;
    self.circleProgress = [[CircleProgress alloc] init];
    [self.circleProgress setup];
    self.circleProgress.circleImage = [UIImage imageNamed:@"circle"];
    self.circleProgress.circleColor = [UIColor clearColor];
    self.circleProgress.backgroundColor = [UIColor clearColor];
    
    self.titleLabel.do_weight = 1;
    self.currentValueLabel.do_weight = 1;
    self.maxValueLabel.do_weight = 1;
    self.progressLabel.do_weight = 1;
    self.circleProgress.do_weight = 1;
    
    self.titleLabel.do_layoutParam = [DOLinearLayoutParam paramWrapContent];
    self.currentValueLabel.do_layoutParam = [DOLinearLayoutParam paramWrapContent];
    self.maxValueLabel.do_layoutParam = [DOLinearLayoutParam paramWrapContent];
    self.circleProgress.do_layoutParam = [DOLinearLayoutParam paramWithWidth:50 height:50];
    self.progressLabel.do_layoutParam = [DOLinearLayoutParam paramSamePositionToView:self.circleProgress];
    
    UIView *topSpace = [[UIView alloc] init];
    topSpace.do_weight = 1;
    [linearLayout addSubview:topSpace];
    [linearLayout addSubview:self.titleLabel];
    [linearLayout addSubview:self.circleProgress];
    [linearLayout addSubview:self.progressLabel];
    [linearLayout addSubview:self.currentValueLabel];
    [linearLayout addSubview:self.maxValueLabel];
    UIView *bottomSpace = [[UIView alloc] init];
    bottomSpace.do_weight = 1;
    [linearLayout addSubview:bottomSpace];
}

- (void)setItem:(GridViewItem *)item
{
    self.titleLabel.text = item.title;
    self.currentValueLabel.text = [@(item.currentValue) description];
    self.maxValueLabel.text = [@(item.maxValue) description];
    self.progressLabel.text = [NSString stringWithFormat:@"%.1f%%", item.progress * 100];
    self.circleProgress.progress = item.progress;
}

@end
