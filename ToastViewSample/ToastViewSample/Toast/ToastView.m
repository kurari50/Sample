//
//  ToastView.m
//  ToastViewSample
//
//  Created by kura on 2014/12/05.
//  Copyright (c) 2014年 kura. All rights reserved.
//

#import "ToastView.h"

@interface ToastView ()

@property (nonatomic, strong) UIView *toast;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIView *view;

@end

@implementation ToastView

- (instancetype)init
{
    self = [super init];
    if (self) {
        _toast = [[UINib nibWithNibName:@"ToastView" bundle:nil] instantiateWithOwner:nil options:nil][0];
        _label = (UILabel *)[_toast viewWithTag:1];
        _view = (UIView *)[_toast viewWithTag:2];
        
        _view.layer.cornerRadius = 5;
        
        [self addSubview:_toast];
    }
    return self;
}

+ (instancetype)makeToast:(NSString *)message
{
    ToastView *v = [[ToastView alloc] init];
    v.label.text = message;
    [v.label sizeToFit];
    return v;
}

- (void)showInView:(UIView *)view
{
    self.toast.frame = view.frame;
    self.view.alpha = 0;
    [view addSubview:self];
    
    __weak ToastView *weakSelf = self;
    [UIView animateWithDuration:0.1 animations:^{
        weakSelf.view.alpha = 1;
    } completion:NULL];
    
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:3];
}

- (void)dismiss
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
    
    __weak ToastView *weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.alpha = 0;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
    }];
}

@end
