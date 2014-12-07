//
//  LinearLayout.h
//  ToastViewSample
//
//  Created by kura on 2014/12/06.
//  Copyright (c) 2014年 kura. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LinearLayout : UIView

@property (nonatomic, assign) CGSize separatorSize;

@property (nonatomic, assign) BOOL reverseLayout;

@property (nonatomic, assign) BOOL addTop;

@property (nonatomic, assign, readonly) CGFloat layoutedHeight;

@property (nonatomic, assign) BOOL scrollable;

@end
