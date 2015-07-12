//
//  DOPopupView.h
//  PopupSample
//
//  Created by kura on 2015/06/06.
//  Copyright (c) 2015年 kura. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DOPopupView;

/**
 * ポップアップが閉じられた理由
 */
typedef NS_ENUM(int, DOPopupViewCloseReason) {
    DOPopupViewCloseReasonCalledCloseMethod = 1,    // closeがコールされた
};

/**
 * InnerViewをリサイズするモード
 */
typedef NS_ENUM(int, DOPopupViewResizingMode) {
    DOPopupViewResizingModeNone,                    // リサイズしない
    DOPopupViewResizingModeStrech,                  // リサイズする
};

@protocol DOPopupViewDelegate <NSObject>

@required

/**
 * ポップアップが閉じられたときに呼ばれる
 *
 * @see DOPopupViewCloseReason
 */
- (void)popup:(DOPopupView *)popup didCloseWithReason:(DOPopupViewCloseReason)reason;

@optional

/**
 * InnerViewのリサイズ時に呼ばれる
 *
 * InnerViewのサイズを返す
 *
 * @param size 表示可能最大サイズ
 * @return InnerViewのサイズ
 *
 * @see DOPopupViewResizingModeStrech
 */
- (CGSize)popup:(DOPopupView *)popup didChangeSize:(CGSize)size;

@end

@interface DOPopupView : UIView

@property (nonatomic, weak) id<DOPopupViewDelegate> delegate;       // delegate
@property (nonatomic, assign) BOOL enableUnderTopBar;               // ステータスバーおよびナビゲーションバーに重ねるかどうか
@property (nonatomic, strong) UIView *backgroundView;               // バックグラウンドのビュー
@property (nonatomic, copy) NSString *tagString;                    // 閉じるときに指定可能なタグ
@property (nonatomic, assign,readonly) BOOL isShowning;             // 表示中かどうか

/**
 * 必ずこのメソッドで初期化してください
 *
 * @param view 表示するビュー(InnerView)
 * @param resizingMode
 *
 * @see DOPopupViewResizingMode
 */
- (instancetype)initWithInnerView:(UIView *)view resizingMode:(DOPopupViewResizingMode)resizingMode;

/**
 * ポップアップを表示する
 *
 * @param view このビューを追加するビュー(UIWindowを想定)
 */
- (instancetype)showInView:(UIView *)view;

/**
 * ポップアップを表示する
 *
 * @param viewController このビューを追加する画面
 */
- (instancetype)showInViewController:(UIViewController *)viewController;

/**
 * ポップアップを閉じる
 */
- (void)close;

/**
 * すべてのポップアップを閉じる
 */
+ (void)closeAllPopup;

/**
 * タグを指定してポップアップを閉じる
 *
 * @see tagString
 */
+ (void)closeWithTag:(NSString *)tag;

@end
