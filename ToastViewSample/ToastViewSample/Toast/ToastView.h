//
//  ToastView.h
//  ToastViewSample
//
//  Created by kura on 2014/12/05.
//  Copyright (c) 2014年 kura. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ToastView : UIView

+ (instancetype)makeToast:(NSString *)message;

- (void)showInView:(UIView *)view;

@end
