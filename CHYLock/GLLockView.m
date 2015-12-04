//
//  GLLockView.m
//  CHYLock
//
//  Created by chenyun on 15/11/24.
//  Copyright © 2015年 chenyun. All rights reserved.
//

#import "GLLockView.h"
#import "UIColor+HexColor.h"

#define SCREEN_WIDTH        [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT       [UIScreen mainScreen].bounds.size.height
#define IS_Iphone4          (SCREEN_HEIGHT == 480)
#define IS_Iphone5          (SCREEN_HEIGHT == 568)
#define IS_Iphone6          (SCREEN_HEIGHT == 667)
#define IS_Iphone6p         (SCREEN_HEIGHT == 736)
#define USERCENTER          [NSUserDefaults standardUserDefaults]
#define DEFAULTPAASWORDKEY  @"DefaultUserPassWordKey"
#define USERTRYCOUNTKEY     @"UserTryCountKey"

NSString *const CanResetNotice = @"GLLockViewResetNotice";
NSString *const SetSuccessNotice = @"GLLockViewSetSuccessNotice";

NSString *const StartDraw = @"绘制解锁图案";

NSString *const LengthWrong = @"至少连接4个点，请重新输入";

NSString *const SecondDraw = @"在次绘制解锁图案";

NSString *const Inconsisterncy = @"两次绘制不一致，请重新绘制";

NSString *const CompleteDraw = @"设置完成";

NSString *const ModifyDraw = @"请输入原手势密码";

typedef NS_ENUM(NSUInteger, CHYLockSettingStep) {
    CHYLockSettingStepZero = 1,
    CHYLockSettingStepFirst,
    CHYLockSettingStepSecond,
};

typedef NS_ENUM(NSUInteger, CHYLockDrawWrongType) {
    CHYLockDrawWrongTypeLength = 1,
    CHYLockDrawWrongTypePassword,
};

typedef NS_ENUM(NSUInteger, CHYLockModifyStep) {
    CHYLockModifyStepUnlock = 1,
    CHYLockModifyStepSetting,
};

typedef NS_ENUM(NSUInteger, CHYLockClearStep) {
    CHYLockClearStepUnlcok = 1,
    CHYLockClearStepClear,
};

typedef NS_ENUM(NSUInteger, CHYLockUnLockStep) {
    CHYLockUnLockStepFirst = 1,
    CHYLockUnLockStepSecond,
};

@interface GLLockView()
@property (nonatomic, strong) NSMutableArray *lockViews;
@property (nonatomic, strong) UIImageView *showLogoImageView;
@property (nonatomic, strong) UILabel *showTitleLabel;
@property (nonatomic, strong) UILabel *showSubTitleLabel;
@property (nonatomic, strong) UIButton *showBottomButton;
@property (nonatomic, strong) UIView *topContenterView;
@property (nonatomic, strong) UIView *bottomContenterView;
@property (nonatomic, strong) NSMutableArray *lockviewSubVies;
@property (nonatomic, assign) CHYLockSettingStep settingStep;
@property (nonatomic, assign) CHYLockModifyStep modifyStep;
@property (nonatomic, copy)   NSString *firstPassword;
@end

@implementation GLLockView{
    CGPoint _currentPoint;
    BOOL _isWrong;
    BOOL _isEndDraw;
    NSUInteger _mistakes;
}

- (NSMutableArray *) lockViews{
    if (!_lockViews) {
        _lockViews = [[NSMutableArray alloc]init];
    }
    return _lockViews;
}

- (NSMutableArray *)lockviewSubVies{
    if (!_lockviewSubVies) {
        _lockviewSubVies = [NSMutableArray array];
    }
    return _lockviewSubVies;
}

- (instancetype) initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self createCircle];
        [self buildUI];
    }
    return self;
}

#pragma mark- UI创建
- (void)buildUI{
    self.backgroundColor = [UIColor whiteColor];
    [self addTopContenterView];
    [self addBottomContentView];
    switch (self.lockType) {
        case CHYLockViewTypeSetting:
        {
            [self setPassword:CHYLockSettingStepZero];
        }
            break;
            
        case CHYLockViewTypeUnlock:{
            NSString *lockKey = self.lockKey?self.lockKey:DEFAULTPAASWORDKEY;
            if ([self existUserPasswordKey:lockKey]) {
                [self unLockPassword:CHYLockUnLockStepFirst];
            } else {
                _lockType = CHYLockViewTypeSetting;
                [self setPassword:CHYLockSettingStepZero];
            }
        }
            break;
            
        case CHYLockViewTypeModify:{
            [self modifyPassword:CHYLockModifyStepUnlock];
        }
            break;
        case CHYLockViewTypeClear:{
            [self clearPassword:CHYLockClearStepUnlcok];
        }
            break;
        default:
            break;
    }
}

- (void) addTopContenterView{
    self.topContenterView = [[UIView alloc]initWithFrame:CGRectMake(0, 0,SCREEN_WIDTH,120)];
    self.topContenterView.backgroundColor = [UIColor clearColor];
    CGPoint center =CGPointMake(SCREEN_WIDTH / 2, self.topContenterView.frame.size.height);
    self.topContenterView.center = center;
    [self addSubview:self.topContenterView];
    [self addLogoView];
    [self addTitleLable];
    [self addSubTitleLabel];
}

- (void) addBottomContentView{
    self.bottomContenterView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 80)];
    CGPoint center = CGPointMake(SCREEN_WIDTH / 2, SCREEN_HEIGHT - 40);
    self.bottomContenterView.backgroundColor = [UIColor clearColor];
    self.bottomContenterView.center = center;
    [self addSubview:self.bottomContenterView];
    [self addBottomButton];
}

- (void) addBottomButton{
    self.showBottomButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 120, 44)];
    self.showBottomButton.backgroundColor = [UIColor clearColor];
    [self.showBottomButton setTitle:@"管理手势密码" forState:UIControlStateNormal];
    [self.showBottomButton setTitleColor:[UIColor colorWithHexString:@"2a2a2a" alpha:1.0] forState:UIControlStateNormal];
    [self.showBottomButton.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
    CGPoint center = CGPointMake(SCREEN_WIDTH / 2, self.bottomContenterView.frame.size.height / 2);
    self.showBottomButton.center = center;
    [self.showBottomButton addTarget:self action:@selector(bottomButoonEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomContenterView addSubview:self.showBottomButton];
}

- (void) addLogoView{
    self.showLogoImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    self.showLogoImageView.backgroundColor = [UIColor clearColor];
    CGPoint center = CGPointMake(self.topContenterView.bounds.size.width / 2, self.showLogoImageView.frame.size.height / 2 +15);
    self.showLogoImageView.center = center;
    self.showLogoImageView.backgroundColor = [UIColor redColor];
    [self.topContenterView addSubview:self.showLogoImageView];
}

- (void) addTitleLable{
    self.showTitleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH/2, 21)];
    self.showTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.showTitleLabel.textColor = [UIColor colorWithHexString:@"2a2a2a" alpha:1.0];
    self.showTitleLabel.font = [UIFont systemFontOfSize:12.0];
    CGPoint center = CGPointMake(self.topContenterView.bounds.size.width / 2, self.showLogoImageView.bounds.size.height + 25);
    self.showTitleLabel.center = center;
    [self setShowTitle:@"fdfdddfddd"];
    [self.topContenterView addSubview:self.showTitleLabel];
}

- (void) addSubTitleLabel{
    self.showSubTitleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH - 40, 30)];
    self.showSubTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.showSubTitleLabel.textColor = [UIColor colorWithHexString:@"2a2a2a" alpha:1.0];
    self.showSubTitleLabel.font = [UIFont systemFontOfSize:17.0];
    CGPoint center = CGPointMake(self.topContenterView.bounds.size.width / 2, self.showTitleLabel.frame.origin.y  + self.showTitleLabel.frame.size.height + 20);
    self.showSubTitleLabel.center = center;
    [self.topContenterView addSubview:self.showSubTitleLabel];
}

- (void) createCircle{
    for (NSUInteger i = 0; i < 9; i ++) {
        GLLockViewItem *circleView = [[GLLockViewItem alloc]init];
        circleView.number = @(i).stringValue;
        circleView.backgroundColor = [UIColor clearColor];
        [self addSubview:circleView];
        [self.lockviewSubVies addObject:circleView];
    }
}

- (void) layoutSubviews{
    [super layoutSubviews];
    for (NSUInteger i = 0; i < self.lockviewSubVies.count; i ++) {
        CGFloat row = i / 3;
        CGFloat col = i % 3;
        GLLockViewItem *lockView = self.lockviewSubVies[i];
        CGFloat marginX = 0;
        if (IS_Iphone4) {
            marginX = 20;
        }
        CGFloat height = (self.bounds.size.width - 150) / 3.0;
        CGFloat width = height;
        CGFloat padding = (self.bounds.size.width - 3 * width) /4 - marginX;
        
        CGFloat x = padding + (width + padding) * col + 2*marginX;
        CGFloat y = padding + (width + padding) * row + self.topContenterView.frame.size.height + 50;
        lockView.frame = CGRectMake(x,y, width, height);
    }
}

- (void)drawRect:(CGRect)rect{
    CGContextRef cx = UIGraphicsGetCurrentContext();
    for (NSUInteger i = 0; i < self.lockViews.count; i ++) {
        GLLockViewItem *view = self.lockViews[i];
        if (i == 0) {
            CGContextMoveToPoint(cx, view.center.x, view.center.y);
        }
        else {
            CGContextAddLineToPoint(cx, view.center.x, view.center.y);
        }
    }
    if (!_isEndDraw) {
        CGContextAddLineToPoint(cx, _currentPoint.x, _currentPoint.y);
    }
    CGContextSetLineWidth(cx, 2.0);
    UIColor *color;
    if (_isWrong) {
        color =  [UIColor colorWithHexString:@"FF5A5A" alpha:1.0];
    } else {
        color =  [UIColor colorWithHexString:@"ffbd18" alpha:1.0];
    }
    CGContextSetStrokeColorWithColor(cx, color.CGColor);
    CGContextStrokePath(cx);
}

#pragma mark- 触摸事件
- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self cancleTouch];
    GLLockViewItem *touchView = [self getTouchView:touches];
    if (touchView && ![touchView isTouched]) {
        [touchView setTouched:YES];
        [self addPasswordString:touchView];
        [touchView setNeedsDisplay];
    }
}

- (void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    GLLockViewItem *touchView = [self getTouchView:touches];
    _currentPoint = [touches.anyObject locationInView:self];
    [touchView setNeedsDisplay];
    if (![touchView isTouched] && touchView) {
        [touchView setTouched:YES];
        [self addPasswordString:touchView];
        [touchView setNeedsDisplay];
    }
    [self setNeedsDisplay];
}

- (void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self judgementPasswordLength];
}

- (void) touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    GLLockViewItem *touchView = [self getTouchView:touches];
    [touchView setTouched:NO];
}

#pragma mark- 逻辑方法
- (void) judgementPasswordLength{
    _isEndDraw = YES;
    if (self.lockViews.count == 0) {

    } else if (self.lockViews.count <4 && self.lockViews.count >= 1) {
        [self wrongDrawed:CHYLockDrawWrongTypeLength];
    } else {
        [self passedDraw];
    }
    __weak GLLockView *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self cancleTouch];
        [weakSelf setNeedsDisplay];
    });
}

- (void) wrongDrawed:(CHYLockDrawWrongType)wrongType{
    _isWrong = YES;
    [self setShowSubTitleColor:[UIColor redColor]];
    switch (wrongType) {
        case CHYLockDrawWrongTypeLength:
        {
            [self setShowSubTitle:LengthWrong];
            [self shakeAnimation];
        }
            break;
        case CHYLockDrawWrongTypePassword:{
            [self doFailedBlock];
        }
            break;
        default:
            break;
    }
    for (GLLockViewItem *circleView in self.lockViews) {
        [circleView setWrongUnlock:YES];
        [circleView setNeedsDisplay];
    }
    [self setNeedsDisplay];
}

- (void) passedDraw{
    _isWrong = NO;
    [self setShowSubTitleColor:[UIColor blackColor]];
    [self setNeedsDisplay];
    switch (self.lockType) {
        case CHYLockViewTypeSetting:
        {
            self.settingStep += 1;
            [self setPassword:self.settingStep];
            if (self.settingStep == CHYLockSettingStepSecond) {
                self.settingStep = CHYLockSettingStepZero;
            }
        }
            break;
            
        case CHYLockViewTypeUnlock:{
            [self unLockPassword:CHYLockUnLockStepSecond];
        }
            break;
        case CHYLockViewTypeModify:{
            if ([self isPassWordCorrect]) {
                NSLog(@"解锁成功");
                [self modifyPassword:CHYLockModifyStepSetting];
            } else {
                NSLog(@"解锁失败");
                [self doFailedBlock];
            }
        }
            break;
        case CHYLockViewTypeClear:{
            if ([self isPassWordCorrect]) {
                [self clearPassword:CHYLockClearStepClear];
            } else {
                [self doFailedBlock];
            }
        }
            break;
        default:
            break;
    }
}

- (GLLockViewItem *) getTouchView:(NSSet *)touches{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    for (GLLockViewItem *view in self.lockviewSubVies) {
        if (CGRectContainsPoint(view.frame, touchPoint)) {
            return  view;
        }
    }
    return nil;
}

- (void) cancleTouch{
    [self.lockViews removeAllObjects];
    _isWrong = NO;
    _isEndDraw = NO;
    for (GLLockViewItem *view in self.lockviewSubVies) {
        [view setTouched:NO];
        [view setWrongUnlock:NO];
        [view setDirect:0];
        [view setNeedsDisplay];
    }
}

- (void) addPasswordString:(UIView *)view{
    [self.lockViews addObject:view];
    [self calculateDirect];
    NSLog(@"%@ ",[self getCurrentPasswordString]);
}

- (NSString *) getCurrentPasswordString {
    NSString *string = @"";
    for (GLLockViewItem *aview in self.lockViews) {
        string = [string stringByAppendingString:aview.number];
    }
    NSLog(@"%@ ",string);
    return string;
}

- (void) setPassword:(CHYLockSettingStep)step{
    self.settingStep = step;
    switch (step) {
        case CHYLockSettingStepZero:
        {
            [self setShowSubTitle:StartDraw];
        }
            break;
        case CHYLockSettingStepFirst:
        {
            [self setShowSubTitle:SecondDraw];
            self.firstPassword = [self getCurrentPasswordString];
            
        }
            break;
            
        case CHYLockSettingStepSecond:{
            NSString *secondString = [self getCurrentPasswordString];
            if ([self.firstPassword isEqualToString:secondString]) {
                [self setShowSubTitle:CompleteDraw];
                [USERCENTER setObject:secondString forKey:DEFAULTPAASWORDKEY];
                [self doSuccessBlock];
                [[NSNotificationCenter defaultCenter]postNotificationName:SetSuccessNotice object:nil];

            } else {
                [self setShowSubTitle:Inconsisterncy];
                self.settingStep = CHYLockSettingStepFirst;
                [[NSNotificationCenter defaultCenter]postNotificationName:CanResetNotice object:nil];
            }
        }
            break;
        default:
            break;
    }
}

- (void) unLockPassword:(CHYLockUnLockStep) step {
    switch (step) {
        case CHYLockUnLockStepFirst:
        {
            NSLog(@"开始解锁");
        }
            break;
        case CHYLockUnLockStepSecond:{
            if ([self isPassWordCorrect]) {
                _mistakes = -1;
                [self saveMistakeNumber];
                [self setShowSubTitle:@"解锁成功"];
                NSLog(@"解锁成功");
                [self doSuccessBlock];
            } else {
                NSLog(@"解锁失败");
                [self doFailedBlock];
            }
        }
            break;
        default:
            break;
    }
    
}

- (void) modifyPassword:(CHYLockModifyStep)step {
    switch (step) {
        case CHYLockModifyStepUnlock:{
            [self setShowSubTitle:@"请绘制旧手势"];
        }
            break;
        case CHYLockModifyStepSetting:
        {
            _lockType = CHYLockViewTypeSetting;
            [self setPassword:CHYLockSettingStepZero];
        }
            break;
        default:
            break;
    }
    
}

- (void) clearPassword:(CHYLockClearStep)step{
    switch (step) {
        case CHYLockClearStepUnlcok:
        {
            [self setShowSubTitle:ModifyDraw];
        }
            break;
        case CHYLockClearStepClear:{
            NSString *lockKey = self.lockKey?self.lockKey:DEFAULTPAASWORDKEY;
            [USERCENTER removeObjectForKey:lockKey];
            [self setShowSubTitle:@"清除密码成功"];
            [self doSuccessBlock];
        }
            break;
        default:
            break;
    }
}

- (NSString *) getPassword {
    return [USERCENTER objectForKey:DEFAULTPAASWORDKEY];
}

- (NSUInteger) getMistakeNumber{
    NSUInteger mistakesTime = [[USERCENTER objectForKey:USERTRYCOUNTKEY] integerValue];
    if (mistakesTime <= 0) {
        mistakesTime = 1;
    }
    return mistakesTime;
}
- (void) saveMistakeNumber{
    [USERCENTER setObject:@(_mistakes + 1) forKey:USERTRYCOUNTKEY];
}

- (BOOL) isPassWordCorrect{
    if ([[self getCurrentPasswordString] isEqualToString:[self getPassword]]) {
        return YES;
    }
    return NO;
}

-(void)calculateDirect{
    
    NSUInteger count = self.lockViews.count;
    
    if(self.lockViews ==nil || count<=1) return;
    GLLockViewItem *item_1 = self.lockViews.lastObject;
    GLLockViewItem *item_2 =self.lockViews[count -2];
    
    CGFloat item_1_x = item_1.frame.origin.x;
    CGFloat item_1_y = item_1.frame.origin.y;
    CGFloat item_2_x = item_2.frame.origin.x;
    CGFloat item_2_y = item_2.frame.origin.y;
    
    //正上
    if(item_2_x == item_1_x && item_2_y > item_1_y) {
        item_2.direct = LockItemViewDirecTop;
    }
    
    //正左
    if(item_2_y == item_1_y && item_2_x > item_1_x) {
        item_2.direct = LockItemViewDirecLeft;
    }
    
    //正下
    if(item_2_x == item_1_x && item_2_y < item_1_y) {
        item_2.direct = LockItemViewDirecBottom;
    }
    
    //正右
    if(item_2_y == item_1_y && item_2_x < item_1_x) {
        item_2.direct = LockItemViewDirecRight;
    }
    
    //左上
    if(item_2_x > item_1_x && item_2_y > item_1_y) {
        item_2.direct = LockItemViewDirecLeftTop;
    }
    
    //右上
    if(item_2_x < item_1_x && item_2_y > item_1_y) {
        item_2.direct = LockItemViewDirecRightTop;
    }
    
    //左下
    if(item_2_x > item_1_x && item_2_y < item_1_y) {
        item_2.direct = LockItemViewDirecLeftBottom;
    }
    
    //右下
    if(item_2_x < item_1_x && item_2_y < item_1_y) {
        item_2.direct = LockItemViewDiretRightBottom;
    }
    
}

#pragma mark- setter
- (void) setShowTitle:(NSString *)showTitle{
    _showTitle = showTitle;
    self.showTitleLabel.text = _showTitle;
}

- (void) setShowSubTitle:(NSString *)showSubTitle{
    self.showSubTitleLabel.text = showSubTitle;
}

- (void) setBottomTitle:(NSString *)bottomTitle{
    _bottomTitle = bottomTitle;
    [self.showBottomButton setTitle:_bottomTitle forState:UIControlStateNormal];
}

- (void) setShowTitleColor:(UIColor *)showTitleColor{
    _showTitleColor = showTitleColor;
    [self.showTitleLabel setTextColor:_showTitleColor];
}

- (void) setShowSubTitleColor:(UIColor *)showSubTitleColor{
    [self.showSubTitleLabel setTextColor:showSubTitleColor];
}

- (void) setBottomTitleColor:(UIColor *)bottomTitleColor{
    _bottomTitleColor = bottomTitleColor;
    [self.showBottomButton setTitleColor:_bottomTitleColor forState:UIControlStateNormal];
}

- (void) setBottomView:(UIView *)bottomView{
    _bottomView = bottomView;
    if (_bottomView) {
        [self.bottomContenterView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.bottomContenterView addSubview:_bottomView];
    }
}

- (void) setLockType:(CHYLockViewType)lockType{
    _lockType = lockType;
    [self buildUI];
}

#pragma mark- Interface
- (void) showLogoByCircularMask:(BOOL)isShow{
    if (isShow) {
        [self.showLogoImageView.layer setCornerRadius:self.showLogoImageView.frame.size.width];
    }else{
        [self.showLogoImageView.layer setCornerRadius:0];
    }
}

- (BOOL) existUserPasswordKey:(NSString *)key{
    return [[USERCENTER objectForKey:key] boolValue];
}

- (BOOL) existDefaultPasswordKey{
    return [[USERCENTER objectForKey:DEFAULTPAASWORDKEY] boolValue];
}

- (void) resetSetting {
    [self setShowSubTitle:StartDraw];
    self.firstPassword = nil;
    [self setPassword:CHYLockSettingStepZero];
}

#pragma  mark- Actions
- (void) bottomButoonEvent:(id)sender{
    NSLog(@"First blood!");
}

- (void) doSuccessBlock{
    if (self.unLockSuccessBlock) {
        self.unLockSuccessBlock();
    }
}

- (void) doFailedBlock{
    _mistakes = [self getMistakeNumber];
    [self setShowSubTitleColor:[UIColor redColor]];
    [self setShowSubTitle:[NSString stringWithFormat:@"绘制错误，剩余%ld次",5 - _mistakes]];
    [self shakeAnimation];
    [self saveMistakeNumber];
    if (_mistakes == 5) {
        [self doMaxWrongBlock];
        _mistakes = -1;
        [self saveMistakeNumber];
        return;
    }
}

- (void) doMaxWrongBlock{
    if (self.maxWrongBlock) {
        self.maxWrongBlock();
    }
}

- (void) doForgotBlock{
    if (self.forgotPasswordBlock) {
        self.forgotPasswordBlock();
    }
}

#pragma mark- 动画
- (void)shakeAnimation{
    CGFloat centerX = self.showSubTitleLabel.center.x;
    CGFloat centerY = self.showSubTitleLabel.center.y;
    CGPoint left_1 = CGPointMake(centerX - 6, centerY);
    CGPoint left_2 = CGPointMake(centerX - 4, centerY);
    CGPoint left_3 = CGPointMake(centerX - 2, centerY);
    CGPoint right_1 = CGPointMake(centerX + 6, centerY);
    CGPoint right_2 = CGPointMake(centerX + 4, centerY);
    CGPoint right_3 = CGPointMake(centerX + 2, centerY);
    [NSValue valueWithCGPoint:left_1];
    
    NSArray *positions = @[[NSValue valueWithCGPoint:left_1],
                           [NSValue valueWithCGPoint:left_2],
                           [NSValue valueWithCGPoint:left_3],
                           [NSValue valueWithCGPoint:right_1],
                           [NSValue valueWithCGPoint:right_2],
                           [NSValue valueWithCGPoint:right_3]
];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.values = positions;
    animation.duration = .1;
    animation.repeatCount = 2;
    animation.removedOnCompletion = YES;
    [self.showSubTitleLabel.layer addAnimation:animation forKey:@"shakeAnimtion"];
}
@end
