//
//  DOMenuView.h
//

#import <UIKit/UIKit.h>

@interface DOMenuItem : NSObject

@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIImage *icon;

@end

@interface DOMenuItemView : UIView

@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIImage *icon;

@end

@interface DOMenuView : UIScrollView

@property (nonatomic, strong) NSMutableArray *items;

@property (nonatomic, assign) NSInteger currentIndex;

- (void)setCurrentIndex:(NSInteger)index animated:(BOOL)animated;

- (NSInteger)indexWithGesture:(UIGestureRecognizer *)gesture;

@end
