//
//  GridViewCell.h
//  GridProgress
//
//  Created by kura on 2017/01/09.
//  Copyright © 2017年 kura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GridViewItem.h"

@interface GridViewCell : UIView

@property (nonatomic) GridViewItem *item;

- (void)setup;

@end
