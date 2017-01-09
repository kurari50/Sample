//
//  GridView.h
//  GridProgress
//
//  Created by kura on 2017/01/09.
//  Copyright © 2017年 kura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GridViewItem.h"

@interface GridView : UIView

@property (nonatomic) int numberOfColumn;

@property (nonatomic) int heightOfRow;

@property (nonatomic) NSArray<GridViewItem *> *dataArray;

- (void)reload;

@end
