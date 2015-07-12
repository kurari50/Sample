//
//  ViewController.m
//  PopupSample
//
//  Created by kura on 2015/06/06.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "DOPopupView.h"
#import "DOAlertView.h"

@interface ViewController () <DOPopupViewDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *enableStrechSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *enableUnderTopBarSwitch;

@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(loop) userInfo:nil repeats:YES];
}

- (void)loop
{
    self.navigationController.navigationBarHidden = !self.navigationController.navigationBarHidden;
}

- (UIView *)inflateInnerView
{
    return [[UINib nibWithNibName:@"InnerView" bundle:nil] instantiateWithOwner:self options:nil][0];
}

- (DOPopupViewResizingMode)mode
{
    return (self.enableStrechSwitch.isOn)? DOPopupViewResizingModeStrech:DOPopupViewResizingModeNone;
}

- (IBAction)didPressAddToViewControllerButton:(id)sender
{
    DOPopupView *popup = [[DOPopupView alloc] initWithInnerView:[self inflateInnerView] resizingMode:[self mode]];
    popup.backgroundView = [self inflateInnerView];
    popup.enableUnderTopBar = self.enableUnderTopBarSwitch.isOn;
    popup.delegate = self;
    [popup showInViewController:self];
    [self addTarget:popup];
}

- (IBAction)didPressAddToWindowButton:(id)sender
{
    DOPopupView *popup = [[DOPopupView alloc] initWithInnerView:[self inflateInnerView] resizingMode:[self mode]];
    popup.backgroundView = [self inflateInnerView];
    popup.enableUnderTopBar = self.enableUnderTopBarSwitch.isOn;
    popup.delegate = self;
    popup.tagString = @"a";
    UIWindow *window = ((AppDelegate *)[UIApplication sharedApplication].delegate).window;
    [popup showInView:window];
    [self addTarget:popup];
}

- (void)addTarget:(UIView *)view
{
    NSMutableArray *q = [view.subviews mutableCopy];
    for (int i = 0, len = (int)q.count; i < len; i++) {
        [q addObjectsFromArray:[q[i] subviews]];
    }
    for (int i = 0, len = (int)q.count; i < len; i++) {
        [q addObjectsFromArray:[q[i] subviews]];
    }
    for (int i = 0, len = (int)q.count; i < len; i++) {
        [q addObjectsFromArray:[q[i] subviews]];
    }
    for (int i = 0, len = (int)q.count; i < len; i++) {
        [q addObjectsFromArray:[q[i] subviews]];
    }
    for (int i = 0, len = (int)q.count; i < len; i++) {
        [q addObjectsFromArray:[q[i] subviews]];
    }
    
    for (int i = 0; i < q.count; i++) {
        UIView *sv = q[i];
        if ([sv isKindOfClass:[UIButton class]]) {
            [(UIButton *)sv addTarget:self action:@selector(tap) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)tap
{
    [DOPopupView closeAllPopup];
//    [DOPopupView closeWithTag:@"a"];
}

- (void)popup:(DOPopupView *)popup didCloseWithReason:(DOPopupViewCloseReason)reason
{
}

- (CGSize)popup:(DOPopupView *)popup didChangeSize:(CGSize)size
{
    return CGSizeMake(size.width / 2, size.height / 2);
}

- (IBAction)didPressAlertButton:(id)sender
{
    DOAlertView *alert = [DOAlertView alertViewWithTitle:@"title\n\na" message:@"message\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\na" delegate:self cancelButtonTitle:@"cancel ___________________________\na" positiveButtonTitle:@"positive\n\na" negativeButtonTitle:@"negative"];
    [alert showInViewController:self];
}

@end
