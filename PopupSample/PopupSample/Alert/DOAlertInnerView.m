//
//  DOAlertInnerView.m
//  PopupSample
//
//  Created by kura on 2015/06/06.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import "DOAlertInnerView.h"

#define DOALERTINNERVIEW_MAX_HEIGHT     (240)

@interface DOAlertInnerView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *positiveButton;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *buttonAreaView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonAreaViewHeightConstraint;

@end

@implementation DOAlertInnerView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.autoresizingMask = UIViewAutoresizingNone;
    
    self.cancelButton.titleLabel.numberOfLines = 0;
    self.positiveButton.titleLabel.numberOfLines = 0;
//    self.negativeButton.titleLabel.numberOfLines = 0;
    
    self.layer.cornerRadius = 10;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    self.titleLabel.text = title;
    [self.titleLabel sizeToFit];
    [self updateSelfLayout];
}

- (void)setMessage:(NSString *)message
{
    _message = message;
    
    self.messageLabel.text = message;
    [self.messageLabel sizeToFit];
    [self updateSelfLayout];
}

- (void)setCancelButtonTitle:(NSString *)cancelButtonTitle
{
    _cancelButtonTitle = cancelButtonTitle;
    
    [self.class setTitle:cancelButtonTitle to:self.cancelButton animated:NO];
    [self updateSelfLayout];
}

- (void)setPositiveButtonTitle:(NSString *)positiveButtonTitle
{
    _positiveButtonTitle = positiveButtonTitle;
    
    [self.class setTitle:positiveButtonTitle to:self.positiveButton animated:NO];
    [self updateSelfLayout];
}

- (void)setNegativeButtonTitle:(NSString *)negativeButtonTitle
{
    _negativeButtonTitle = negativeButtonTitle;
    
//    [self.class setTitle:negativeButtonTitle to:self.negativeButton animated:NO];
    [self updateSelfLayout];
}

+ (void)setTitle:(NSString *)title to:(UIButton *)button animated:(BOOL)animated
{
    if (!animated) {
        [UIView setAnimationsEnabled:NO];
    }
    [button setTitle:title forState:UIControlStateNormal];
    [button sizeToFit];
    if (!animated) {
        [button setNeedsLayout];
        [button layoutIfNeeded];
        [UIView setAnimationsEnabled:YES];
    }
}

- (void)updateSelfLayout
{
    CGRect bounds;
    CGSize size;
    
    self.buttonAreaViewHeightConstraint.constant = MAX(self.cancelButton.bounds.size.height, self.positiveButton.bounds.size.height) + 20;
    
    CGFloat height = 0;
    CGFloat heightExcludeMessageLabel = 0;
    height += 8;
    height += self.titleLabel.bounds.size.height;
    height += 8;
    height += 8;
    height += self.buttonAreaView.bounds.size.height;
    
    heightExcludeMessageLabel = height;
    
    height += self.messageLabel.bounds.size.height;
    
    if (height > DOALERTINNERVIEW_MAX_HEIGHT) {
        height = DOALERTINNERVIEW_MAX_HEIGHT;
        
        CGFloat messageLabelHeight = DOALERTINNERVIEW_MAX_HEIGHT - heightExcludeMessageLabel;
        if (messageLabelHeight < 0) {
            messageLabelHeight = 0;
        }
        
        bounds = self.messageLabel.bounds;
        size = CGSizeMake(bounds.size.width, messageLabelHeight);
        bounds.size = size;
        self.messageLabel.bounds = bounds;
    }
    
    bounds = self.bounds;
    size = CGSizeMake(bounds.size.width, height);
    bounds.size = size;
    self.bounds = bounds;
}

@end
