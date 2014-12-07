//
//  ViewController.m
//  ToastViewSample
//
//  Created by kura on 2014/12/05.
//  Copyright (c) 2014年 kura. All rights reserved.
//

#import "ViewController.h"

#import "Toast/ToastView.h"
#import "Layout/Layout.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet LinearLayout *layout;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    self.layout.reverseLayout = YES;
//    self.layout.addTop = YES;
    self.layout.scrollable = YES;
    
    self.layout.separatorSize = CGSizeMake(1, 1);
    
    LayoutableView *v1 = [[LayoutableView alloc] init];
    v1.weight = 1;
    v1.param = [LayoutParam layoutParamW:LayoutableViewLayoutParamMatchParent H:LayoutableViewLayoutParamWrapContent];
    v1.backgroundColor = [UIColor redColor];
    [self.layout addSubview:v1];
    LayoutableView *v2 = [[LayoutableView alloc] init];
    v2.frame = CGRectMake(0, 0, 100, 100);
    v2.backgroundColor = [UIColor greenColor];
    v2.gravity = [LayoutGravity layoutGravityH:LayoutableViewLayoutGravityRight V:LayoutableViewLayoutGravityRight];
    [self.layout addSubview:v2];
    LayoutableView *v5 = [[LayoutableView alloc] init];
    UIView *nib = [[UINib nibWithNibName:@"View" bundle:nil] instantiateWithOwner:nil options:nil][0];
    nib.frame = CGRectMake(0, 0, 0, 0);
    [v5 addSubview:nib];
    v5.weight = 0.5;
    v5.param = [LayoutParam layoutParamW:LayoutableViewLayoutParamWrapContent H:LayoutableViewLayoutParamWrapContent];
    v5.gravity = [LayoutGravity layoutGravityH:LayoutableViewLayoutGravityCenter V:LayoutableViewLayoutGravityCenter];
    v5.backgroundColor = [UIColor whiteColor];
    v5.frame = CGRectMake(0, 0, 200, 200);
//    v5.visibility = LayoutableViewLayoutVisibilityInvisible;
    [self.layout addSubview:v5];
//    [self.view addSubview:v5];
    UIView *v6 = [[UIView alloc] init];
    v6.backgroundColor = [UIColor blackColor];
    v6.frame = CGRectMake(0, 0, 50, 50);
    [self.layout addSubview:v6];
    LayoutableView *v3 = [[LayoutableView alloc] init];
    v3.frame = CGRectMake(0, 0, 50, 50);
    v3.backgroundColor = [UIColor blueColor];
    v3.gravity = [LayoutGravity layoutGravityH:LayoutableViewLayoutGravityCenter V:LayoutableViewLayoutGravityCenter];
    [self.layout addSubview:v3];
    LayoutableView *v4 = [[LayoutableView alloc] init];
    v4.weight = 1;
    v4.param = [LayoutParam layoutParamW:LayoutableViewLayoutParamMatchParent H:LayoutableViewLayoutParamWrapContent];
    v4.backgroundColor = [UIColor grayColor];
    [self.layout addSubview:v4];
}

- (IBAction)didPressButton:(id)sender {
    self.layout.reverseLayout = !self.layout.reverseLayout;
    
    int r = (int)arc4random_uniform(200);
    
    NSMutableString *str = [NSMutableString string];
    for (int i = 0; i <= r; i++) {
        [str appendFormat:@"%d", i];
    }
    
    ToastView *toast = [ToastView makeToast:str];
    [toast showInView:self.view];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = str;
    [label sizeToFit];
//    [self.layout addSubview:label];
    
    UIView *t = [[ToastView makeToast:str] performSelector:@selector(view)];
//    [self.layout addSubview:t];
    
    [label performSelector:@selector(removeFromSuperview) withObject:label afterDelay:3];
    [t performSelector:@selector(removeFromSuperview) withObject:t afterDelay:3];
}

@end
