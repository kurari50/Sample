//
//  CircleProgress.h
//  GridProgress
//
//  Created by kura on 2017/01/10.
//  Copyright © 2017年 kura. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircleProgress : UIView

@property (nonatomic) UIImage *circleImage;
@property (nonatomic) UIColor *circleColor;

@property (nonatomic) double progress;

- (void)setup;

@end
