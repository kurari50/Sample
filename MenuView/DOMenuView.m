//
//  DOMenuView.m
//

#import "DOMenuView.h"

#define MARGIN          10

@interface DOMenuItem ()

@property (nonatomic, strong) DOMenuItemView *view;

@end

@implementation DOMenuItem

- (void)setText:(NSString *)text
{
    _text = text;
    
    [self.view setText:text];
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    
    [self.view setTextColor:textColor];
}

- (void)setIcon:(UIImage *)icon
{
    _icon = icon;
    
    [self.view setIcon:icon];
}

@end

@interface DOMenuItemView ()

@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIView *indicatorView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *iconWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textWidthConstraint;

@end

@implementation DOMenuItemView

- (void)setItem:(DOMenuItem *)item
{
    self.text = item.text;
    [self setTextColor:item.textColor];
    self.icon = item.icon;
}

- (void)setIcon:(UIImage *)icon
{
    _icon = icon;
    
    [self.iconImageView setImage:icon];
    
    if (icon) {
        self.iconImageView.hidden = NO;
        self.iconWidthConstraint.constant = 22;
    } else {
        self.iconImageView.hidden = YES;
        self.iconWidthConstraint.constant = 0;
    }
}

- (void)setTextColor:(UIColor *)color
{
    _textColor = color;
    
    [self.textLabel setTextColor:color];
}

- (void)setText:(NSString *)text
{
    _text = text;
    
    [self.textLabel setText:text];
    
    CGRect bounds = [self.textLabel.text boundingRectWithSize:CGSizeZero options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: self.textLabel.font} context:nil];
    
    self.textWidthConstraint.constant = bounds.size.width + 2;
}

- (CGFloat)contentWidth
{
    CGFloat ret = self.textWidthConstraint.constant;
    
    ret += self.iconWidthConstraint.constant;
    
    return ret;
}

- (CGFloat)contentAndMarginWidth
{
    return [self contentWidth] + MARGIN * 2;
}

- (void)alignToCenter:(CGFloat)over
{
    if (self.frame.size.width - [self contentAndMarginWidth] > over) {
        // 重ならないので中心でOK
        [self alignCenter];
    } else {
        // 重なるので、移動
        // 右端が重ならなければOK
        self.leadingConstraint.constant = self.frame.size.width - over - ([self contentWidth] + MARGIN);
    }
}

- (void)alignFromCenter:(CGFloat)over
{
    if (self.frame.size.width - [self contentAndMarginWidth] > over) {
        // 重ならないので中心でOK
        [self alignCenter];
    } else {
        // 重なるので、移動
        // 左端が重ならなければOK
        self.leadingConstraint.constant = over + MARGIN;
    }
}

- (void)alignCenter
{
    self.leadingConstraint.constant = (self.frame.size.width - [self contentWidth]) / 2.0;
}

- (void)setIsCurrent:(BOOL)current
{
    self.indicatorView.hidden = !current;
}

@end

@interface DOMenuView ()

@property (nonatomic, assign) CGFloat blockWidth;
@property (nonatomic, assign) CGFloat blockHeight;

@property (nonatomic, strong) NSMutableArray *views;

@property (nonatomic, strong) UIColor *indicatorViewBackgroundColor;
@property (nonatomic, weak) UIView *lineView;

@end

@implementation DOMenuView

- (instancetype)init
{
    self = [super init];
    if (self) {
        _items = [NSMutableArray array];
        _views = [NSMutableArray array];
    }
    return self;
}

- (NSInteger)indexWithGesture:(UIGestureRecognizer *)gesture
{
    CGPoint p = [gesture locationInView:self];
    CGFloat x = p.x - self.blockWidth;
    NSInteger index = -1;
    for (;x > 0; x -= self.blockWidth * 2) {
        index++;
    }
    return index;
}

- (void)addSubview:(UIView *)view
{
    DOMenuItem *item = [[DOMenuItem alloc] init];
    if ([view respondsToSelector:@selector(titleLabel)]) {
        // アイテム
        id titleLabel = [view performSelector:@selector(titleLabel)];
        if ([titleLabel respondsToSelector:@selector(text)]) {
            item.text = [titleLabel performSelector:@selector(text)];
        }
        if ([titleLabel respondsToSelector:@selector(textColor)]) {
            item.textColor = [titleLabel performSelector:@selector(textColor)];
        }
        
        [self.items addObject:item];
        [self.views addObject:[[UINib nibWithNibName:@"DOMenuItemView" bundle:nil] instantiateWithOwner:nil options:nil][0]];
        
        [super addSubview:self.views.lastObject];
    } else {
        // インジケータ
        self.indicatorViewBackgroundColor = view.backgroundColor;
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
        self.lineView = lineView;
        self.lineView.backgroundColor = view.backgroundColor;
        [super addSubview:self.lineView];
    }
    
    view.hidden = YES;
    
    [super addSubview:view];
    
    [self setContentSize:CGSizeZero];
}

- (void)setContentSize:(CGSize)contentSize
{
    // 計算値で固定
    contentSize = CGSizeMake(self.blockWidth + (self.blockWidth * 2) * self.items.count + self.blockWidth, self.blockHeight);
    [super setContentSize:contentSize];
    
    self.lineView.frame = CGRectMake(0, self.frame.size.height - self.lineView.frame.size.height, self.contentSize.width, self.lineView.frame.size.height);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self layoutSubMenuViewsWithAnimated:NO inLayoutSubviews:YES];
}

- (void)setCurrentIndex:(NSInteger)index animated:(BOOL)animated
{
    _currentIndex = index;
    
    [self layoutSubMenuViewsWithAnimated:animated inLayoutSubviews:NO];
}

- (void)setCurrentIndex:(NSInteger)currentIndex
{
    [self setCurrentIndex:currentIndex animated:YES];
}

- (void)layoutSubMenuViewsWithAnimated:(BOOL)animated inLayoutSubviews:(BOOL)inLayoutSubviews
{
    if (inLayoutSubviews) {
        self.blockWidth = self.frame.size.width / 4.0;
        self.blockHeight = self.frame.size.height;
        
        [self setContentSize:CGSizeZero];
    }
    
    NSInteger currentIndex = self.currentIndex;
    
    if (self.items.count == 0) {
        return;
    }
    if (currentIndex < 0) {
        return;
    }
    if (self.items.count <= currentIndex) {
        return;
    }
    
    if (inLayoutSubviews) {
        // 全Viewを整列
        CGFloat x = self.blockWidth;
        for (int i = 0; i < self.items.count; i++) {
            [self.views[i] setFrame:CGRectMake(x, 0, self.blockWidth * 2, self.blockHeight)];
            x = CGRectGetMaxX([self.views[i] frame]);
        }
    }
    
    for (int i = 0; i < self.items.count; i++) {
        if (i == currentIndex) {
            [self.views[i] setIsCurrent:YES];
            [[self.views[i] indicatorView] setBackgroundColor:self.indicatorViewBackgroundColor];
        } else {
            [self.views[i] setIsCurrent:NO];
        }
    }
    
    NSInteger prevIndex = currentIndex - 1;
    NSInteger nextIndex = currentIndex + 1;
    
    DOMenuItem *prevItem = (prevIndex >= 0) ? self.items[prevIndex] : nil;
    DOMenuItem *currentItem = self.items[currentIndex];
    DOMenuItem *nextItem = (nextIndex < self.items.count) ? self.items[nextIndex] : nil;
    
    DOMenuItemView *prevView = (prevIndex >= 0) ? self.views[prevIndex] : nil;
    DOMenuItemView *currentView = self.views[currentIndex];
    DOMenuItemView *nextView = (nextIndex < self.views.count) ? self.views[nextIndex] : nil;
    
    [prevView setItem:prevItem];
    [currentView setItem:currentItem];
    [nextView setItem:nextItem];
    
    CGFloat over = (currentView.contentAndMarginWidth - self.blockWidth * 2) / 2.0;
    if (over > 0) {
        [prevView alignToCenter:over];
        [currentView alignCenter];
        [nextView alignFromCenter:over];
    } else {
        [prevView alignCenter];
        [currentView alignCenter];
        [nextView alignCenter];
    }
    
    CGPoint offset = CGPointMake((self.blockWidth * 2) * currentIndex , 0);
    if (inLayoutSubviews) {
        // layoutSubviewsが頻繁に呼ばれるので、offsetは変更しない
    } else {
        [super setContentOffset:offset animated:animated];
    }
}

@end
