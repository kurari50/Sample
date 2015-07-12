//
//  DOAlertView.m
//  PopupSample
//
//  Created by kura on 2015/06/06.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import "DOAlertView.h"
#import "DOAlertInnerView.h"

@interface DOAlertView ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *cancelButtonTitle;
@property (nonatomic, copy) NSString *positiveButtonTitle;
@property (nonatomic, copy) NSString *negativeButtonTitle;

@property (nonatomic, weak) DOAlertInnerView *alertInnerView;

@end

@implementation DOAlertView

+ (instancetype)alertViewWithTitle:(NSString *)title
                           message:(NSString *)message
                          delegate:(id<DOAlertViewDelegate>)delegate
                 cancelButtonTitle:(NSString *)cancelButtonTitle
{
    return [self.class alertViewWithTitle:title
                                  message:message
                                 delegate:delegate
                        cancelButtonTitle:cancelButtonTitle
                      positiveButtonTitle:nil
                      negativeButtonTitle:nil];
}

+ (instancetype)alertViewWithTitle:(NSString *)title
                           message:(NSString *)message
                          delegate:(id<DOAlertViewDelegate>)delegate
                 cancelButtonTitle:(NSString *)cancelButtonTitle
               positiveButtonTitle:(NSString *)positiveButtonTitle
{
    return [self.class alertViewWithTitle:title
                                  message:message
                                 delegate:delegate
                        cancelButtonTitle:cancelButtonTitle
                      positiveButtonTitle:positiveButtonTitle
                      negativeButtonTitle:nil];
}

+ (instancetype)alertViewWithTitle:(NSString *)title
                           message:(NSString *)message
                          delegate:(id<DOAlertViewDelegate>)delegate
                 cancelButtonTitle:(NSString *)cancelButtonTitle
               positiveButtonTitle:(NSString *)positiveButtonTitle
               negativeButtonTitle:(NSString *)negativeButtonTitle
{
    DOAlertInnerView *alertInnerView = [self.class alertInnerView];
    DOAlertView *alert = [[DOAlertView alloc] initWithInnerView:alertInnerView resizingMode:DOPopupViewResizingModeNone];
    alert.alertInnerView = alertInnerView;
    
    alert.title = title;
    alert.message = message;
    alert.cancelButtonTitle = cancelButtonTitle;
    alert.positiveButtonTitle = positiveButtonTitle;
    alert.negativeButtonTitle = negativeButtonTitle;
    alert.backgroundView = [self.class backgroundView];
    return alert;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    self.alertInnerView.title = title;
}

- (void)setMessage:(NSString *)message
{
    _message = message;
    
    self.alertInnerView.message = message;
}

- (void)setCancelButtonTitle:(NSString *)cancelButtonTitle
{
    _cancelButtonTitle = cancelButtonTitle;
    
    self.alertInnerView.cancelButtonTitle = cancelButtonTitle;
}

- (void)setPositiveButtonTitle:(NSString *)positiveButtonTitle
{
    _positiveButtonTitle = positiveButtonTitle;
    
    self.alertInnerView.positiveButtonTitle = positiveButtonTitle;
}

- (void)setNegativeButtonTitle:(NSString *)negativeButtonTitle
{
    _negativeButtonTitle = negativeButtonTitle;
    
    self.alertInnerView.negativeButtonTitle = negativeButtonTitle;
}

+ (UIView *)backgroundView
{
    UIView *background = [[UIView alloc] init];
    background.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    return background;
}

+ (DOAlertInnerView *)alertInnerView
{
    DOAlertInnerView *alert = [[UINib nibWithNibName:@"DOAlertInnerView" bundle:nil] instantiateWithOwner:self options:nil][0];
    return alert;
}

@end
