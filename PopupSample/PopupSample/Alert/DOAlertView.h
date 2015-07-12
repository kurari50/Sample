//
//  DOAlertView.h
//  PopupSample
//
//  Created by kura on 2015/06/06.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DOPopupView.h"

@protocol DOAlertViewDelegate <DOPopupViewDelegate>

@optional

/**
 * ボタンがタップされたときに呼ばれる
 */
- (void)popup:(DOPopupView *)popup didTapButton:(UIButton *)button index:(NSUInteger)index;

@end

@interface DOAlertView : DOPopupView

+ (instancetype)alertViewWithTitle:(NSString *)title
                           message:(NSString *)message
                          delegate:(id<DOAlertViewDelegate>)delegate
                 cancelButtonTitle:(NSString *)cancelButtonTitle
               positiveButtonTitle:(NSString *)positiveButtonTitle
               negativeButtonTitle:(NSString *)negativeButtonTitle;

@end
