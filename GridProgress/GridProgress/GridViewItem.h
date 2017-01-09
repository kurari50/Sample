//
//  GridViewItem.h
//  GridProgress
//
//  Created by kura on 2017/01/09.
//  Copyright © 2017年 kura. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GridViewItem : NSObject

@property (nonatomic) NSString *title;

@property (nonatomic) int currentValue;
@property (nonatomic) int maxValue;

@property (nonatomic) double progress;

+ (instancetype)itemWithTitle:(NSString *)title maxValue:(int)maxValue progress:(double)progress;

@end
