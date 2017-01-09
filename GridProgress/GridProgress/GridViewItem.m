//
//  GridViewItem.m
//  GridProgress
//
//  Created by kura on 2017/01/09.
//  Copyright © 2017年 kura. All rights reserved.
//

#import "GridViewItem.h"

@implementation GridViewItem

+ (instancetype)itemWithTitle:(NSString *)title maxValue:(int)maxValue progress:(double)progress
{
    GridViewItem *gridViewItem = [[GridViewItem alloc] init];
    gridViewItem.title = title;
    gridViewItem.maxValue = maxValue;
    gridViewItem.progress = progress;
    return gridViewItem;
}

@end
