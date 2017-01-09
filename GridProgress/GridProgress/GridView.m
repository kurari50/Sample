//
//  GridView.m
//  GridProgress
//
//  Created by kura on 2017/01/09.
//  Copyright © 2017年 kura. All rights reserved.
//

#import "GridView.h"
#import "DOLinearLayout.h"
#import "GridViewCell.h"

@interface GridView ()

@property (nonatomic) DOLinearLayout *linearLayout;

@end

@implementation GridView

- (int)numberOfData
{
    return (int)self.dataArray.count;
}

- (void)setup
{
    if (self.linearLayout) {
        return;
    }
    
    self.do_enableLinearLayout = YES;
    
    self.linearLayout = [[DOLinearLayout alloc] init];
    self.linearLayout.do_weight = 1;
    self.linearLayout.layoutOrientation = DOLinearLayoutOrientationVertical;
    [self addSubview:self.linearLayout];
}

- (DOLinearLayout *)rowLayoutWithCount:(int)count offset:(int)offset
{
    int heightOfRow = self.heightOfRow;
    int numberOfColumn = self.numberOfColumn;
    NSArray<GridViewItem *> *dataArray = self.dataArray;
    
    DOLinearLayout *rowLayout = [[DOLinearLayout alloc] init];
    rowLayout.do_weight = 1;
    rowLayout.layoutOrientation = DOLinearLayoutOrientationHorizontal;
    rowLayout.do_layoutParam = [DOLinearLayoutParam paramWithWidth:0 widthParam:UIViewLayoutParamMatchParent height:heightOfRow heightParam:UIViewLayoutParamWrapContent];
    rowLayout.do_layoutMargin = UIEdgeInsetsMake(6, 6, 6, 6);
    
    for (int i = 0; i < count; i++) {
        GridViewCell *cell = [[GridViewCell alloc] init];
        [cell setup];
        cell.item = [dataArray objectAtIndex:offset + i];
        cell.do_weight = 1;
        cell.do_layoutParam = [DOLinearLayoutParam paramWithWidth:0 widthParam:UIViewLayoutParamMatchParent height:heightOfRow heightParam:UIViewLayoutParamMatchParent];
        cell.do_layoutMargin = UIEdgeInsetsMake(6, 6, 6, 6);
        [rowLayout addSubview:cell];
    }
    if (count != numberOfColumn) {
        for (int i = 0; i < numberOfColumn - count; i++) {
            UIView *dummyCell = [[UIView alloc] init];
            dummyCell.do_weight = 1;
            dummyCell.do_layoutParam = [DOLinearLayoutParam paramWithWidth:0 widthParam:UIViewLayoutParamMatchParent height:heightOfRow heightParam:UIViewLayoutParamMatchParent];
            dummyCell.do_layoutMargin = UIEdgeInsetsMake(6, 6, 6, 6);
            [rowLayout addSubview:dummyCell];
        }
    }
    
    return rowLayout;
}

- (void)reload
{
    [self setup];
    
    for (UIView *v in [self.linearLayout subviews]) {
        [v removeFromSuperview];
    }
    
    int offset = 0;
    
    int numberOfData = self.numberOfData;
    int numberOfColumn = self.numberOfColumn;
    
    for (int remainDataCount = numberOfData; remainDataCount > 0; remainDataCount -= numberOfColumn) {
        DOLinearLayout *rowLayout = nil;
        if (remainDataCount > numberOfColumn) {
            rowLayout = [self rowLayoutWithCount:numberOfColumn offset:offset];
        } else {
            rowLayout = [self rowLayoutWithCount:remainDataCount offset:offset];
        }
        
        offset += numberOfColumn;
        
        [self.linearLayout addSubview:rowLayout];
    }
}

@end
