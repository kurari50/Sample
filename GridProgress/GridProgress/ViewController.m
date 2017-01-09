//
//  ViewController.m
//  GridProgress
//
//  Created by kura on 2017/01/09.
//  Copyright © 2017年 kura. All rights reserved.
//

#import "ViewController.h"
#import "DOLinearLayout.h"
#import "GridView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.do_enableLinearLayout = YES;
    
    DOLinearLayout *linearLayout = [[DOLinearLayout alloc] init];
    linearLayout.do_weight = 1;
    linearLayout.layoutOrientation = DOLinearLayoutOrientationVertical;
    [self.view addSubview:linearLayout];
    
    UILabel *message = [[UILabel alloc] init];
    message.numberOfLines = 0;
    message.do_weight = 1;
    message.do_layoutParam = [DOLinearLayoutParam paramWithWidth:0 widthParam:UIViewLayoutParamMatchParent height:0 heightParam:UIViewLayoutParamWrapContent];
    message.text = @"アイウエオかきくけこサシスセソたちつてと";
    [linearLayout addSubview:message];
    
    GridView *gridView = [[GridView alloc] init];
    gridView.heightOfRow = 160;
    gridView.numberOfColumn = 3;
    gridView.dataArray = @[
                           [GridViewItem itemWithTitle:@"abc" maxValue:100 progress:0.521398],
                           [GridViewItem itemWithTitle:@"def" maxValue:200 progress:0.32189],
                           [GridViewItem itemWithTitle:@"ghi" maxValue:1000 progress:0.1237],
                           [GridViewItem itemWithTitle:@"jkl" maxValue:999 progress:0.09823],
                           ];
    gridView.do_weight = 1;
    gridView.do_layoutParam = [DOLinearLayoutParam paramMatchParent];
    [linearLayout addSubview:gridView];
    
    [gridView reload];
}

@end
