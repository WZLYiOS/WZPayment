//
//  WZProgressHUD.m
//  WZProgressHUD_Example
//
//  Created by xiaobin liu on 2019/11/7.
//  Copyright © 2019 LiuSky. All rights reserved.
//

#if !__has_feature(objc_arc)
#error WZProgressHUD is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#import "WZProgressHUD.h"
#import "WZRadialGradientLayer.h"
#import "WZProgressAnimatedView.h"
#import "WZIndefiniteAnimatedView.h"


NSString * const WZProgressHUDDidReceiveTouchEventNotification = @"WZProgressHUDDidReceiveTouchEventNotification";
NSString * const WZProgressHUDDidTouchDownInsideNotification = @"WZProgressHUDDidTouchDownInsideNotification";
NSString * const WZProgressHUDWillDisappearNotification = @"WZProgressHUDWillDisappearNotification";
NSString * const WZProgressHUDDidDisappearNotification = @"WZProgressHUDDidDisappearNotification";
NSString * const WZProgressHUDWillAppearNotification = @"WZProgressHUDWillAppearNotification";
NSString * const WZProgressHUDDidAppearNotification = @"WZProgressHUDDidAppearNotification";
NSString * const WZProgressHUDStatusUserInfoKey = @"WZProgressHUDStatusUserInfoKey";

static const CGFloat WZProgressHUDParallaxDepthPoints = 10.0f;
static const CGFloat WZProgressHUDUndefinedProgress = -1;
static const CGFloat WZProgressHUDDefaultAnimationDuration = 0.15f;
static const CGFloat WZProgressHUDVerticalSpacing = 12.0f;
static const CGFloat WZProgressHUDHorizontalSpacing = 12.0f;
static const CGFloat WZProgressHUDLabelSpacing = 8.0f;

@interface WZProgressHUD ()

@property (nonatomic, strong) NSTimer *graceTimer;
@property (nonatomic, strong) NSTimer *fadeOutTimer;

@property (nonatomic, strong) UIControl *controlView;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) WZRadialGradientLayer *backgroundRadialGradientLayer;
@property (nonatomic, strong) UIVisualEffectView *hudView;
@property (nonatomic, strong) UIBlurEffect *hudViewCustomBlurEffect;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIView *indefiniteAnimatedView;
@property (nonatomic, strong) WZProgressAnimatedView *ringView;
@property (nonatomic, strong) WZProgressAnimatedView *backgroundRingView;

@property (nonatomic, readwrite) CGFloat progress;
@property (nonatomic, readwrite) NSUInteger activityCount;

@property (nonatomic, readonly) CGFloat visibleKeyboardHeight;
@property (nonatomic, readonly) UIWindow *frontWindow;

#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
@property (nonatomic, strong) UINotificationFeedbackGenerator *hapticGenerator NS_AVAILABLE_IOS(10_0);
#endif

@end


@implementation WZProgressHUD {
    BOOL _isInitializing;
}

+ (WZProgressHUD*)sharedView {
    static dispatch_once_t once;
    
    static WZProgressHUD *sharedView;
#if !defined(WZ_APP_EXTENSIONS)
    dispatch_once(&once, ^{ sharedView = [[self alloc] initWithFrame:[[[UIApplication sharedApplication] delegate] window].bounds]; });
#else
    dispatch_once(&once, ^{ sharedView = [[self alloc] initWithFrame:[[UIScreen mainScreen] bounds]]; });
#endif
    return sharedView;
}

#pragma mark - Setters

+ (void)setStatus:(NSString*)status {
    [[self sharedView] setStatus:status];
}

+ (void)setDefaultStyle:(WZProgressHUDStyle)style {
    [self sharedView].defaultStyle = style;
}

+ (void)setDefaultMaskType:(WZProgressHUDMaskType)maskType {
    [self sharedView].defaultMaskType = maskType;
}

+ (void)setDefaultAnimationType:(WZProgressHUDAnimationType)type {
    [self sharedView].defaultAnimationType = type;
}

+ (void)setContainerView:(nullable UIView*)containerView {
    [self sharedView].containerView = containerView;
}

+ (void)setMinimumSize:(CGSize)minimumSize {
    [self sharedView].minimumSize = minimumSize;
}

+(void)setMaxSize:(CGSize)maxSize {
    [self sharedView].maxSize = maxSize;
}

+ (void)setRingThickness:(CGFloat)ringThickness {
    [self sharedView].ringThickness = ringThickness;
}

+ (void)setRingRadius:(CGFloat)radius {
    [self sharedView].ringRadius = radius;
}

+ (void)setRingNoTextRadius:(CGFloat)radius {
    [self sharedView].ringNoTextRadius = radius;
}

+ (void)setCornerRadius:(CGFloat)cornerRadius {
    [self sharedView].cornerRadius = cornerRadius;
}

+ (void)setBorderColor:(nonnull UIColor*)color {
    [self sharedView].hudView.layer.borderColor = color.CGColor;
}

+ (void)setBorderWidth:(CGFloat)width {
    [self sharedView].hudView.layer.borderWidth = width;
}

+ (void)setFont:(UIFont*)font {
    [self sharedView].font = font;
}

+ (void)setForegroundColor:(UIColor*)color {
    [self sharedView].foregroundColor = color;
    [self setDefaultStyle:WZProgressHUDStyleCustom];
}

+ (void)setForegroundImageColor:(UIColor *)color {
    [self sharedView].foregroundImageColor = color;
    [self setDefaultStyle:WZProgressHUDStyleCustom];
}

+ (void)setBackgroundColor:(UIColor*)color {
    [self sharedView].backgroundColor = color;
    [self setDefaultStyle:WZProgressHUDStyleCustom];
}

+ (void)setHudViewCustomBlurEffect:(UIBlurEffect*)blurEffect {
    [self sharedView].hudViewCustomBlurEffect = blurEffect;
    [self setDefaultStyle:WZProgressHUDStyleCustom];
}

+ (void)setBackgroundLayerColor:(UIColor*)color {
    [self sharedView].backgroundLayerColor = color;
}

+ (void)setImageViewSize:(CGSize)size {
    [self sharedView].imageViewSize = size;
}

+ (void)setShouldTintImages:(BOOL)shouldTintImages {
    [self sharedView].shouldTintImages = shouldTintImages;
}

+ (void)setInfoImage:(UIImage*)image {
    [self sharedView].infoImage = image;
}

+ (void)setSuccessImage:(UIImage*)image {
    [self sharedView].successImage = image;
}

+ (void)setErrorImage:(UIImage*)image {
    [self sharedView].errorImage = image;
}

+ (void)setViewForExtension:(UIView*)view {
    [self sharedView].viewForExtension = view;
}

+ (void)setGraceTimeInterval:(NSTimeInterval)interval {
    [self sharedView].graceTimeInterval = interval;
}

+ (void)setMinimumDismissTimeInterval:(NSTimeInterval)interval {
    [self sharedView].minimumDismissTimeInterval = interval;
}

+ (void)setMaximumDismissTimeInterval:(NSTimeInterval)interval {
    [self sharedView].maximumDismissTimeInterval = interval;
}

+ (void)setFadeInAnimationDuration:(NSTimeInterval)duration {
    [self sharedView].fadeInAnimationDuration = duration;
}

+ (void)setFadeOutAnimationDuration:(NSTimeInterval)duration {
    [self sharedView].fadeOutAnimationDuration = duration;
}

+ (void)setMaxSupportedWindowLevel:(UIWindowLevel)windowLevel {
    [self sharedView].maxSupportedWindowLevel = windowLevel;
}

+ (void)setHapticsEnabled:(BOOL)hapticsEnabled {
    [self sharedView].hapticsEnabled = hapticsEnabled;
}

+ (void)setMotionEffectEnabled:(BOOL)motionEffectEnabled {
    [self sharedView].motionEffectEnabled = motionEffectEnabled;
}

#pragma mark - Show Methods

+ (void)show {
    [self showWithStatus:nil];
}

+ (void)showWithMaskType:(WZProgressHUDMaskType)maskType {
    WZProgressHUDMaskType existingMaskType = [self sharedView].defaultMaskType;
    [self setDefaultMaskType:maskType];
    [self show];
    [self setDefaultMaskType:existingMaskType];
}

+ (void)showWithStatus:(NSString*)status {
    [self showProgress:WZProgressHUDUndefinedProgress status:status];
}

+ (void)showWithStatus:(NSString*)status maskType:(WZProgressHUDMaskType)maskType {
    WZProgressHUDMaskType existingMaskType = [self sharedView].defaultMaskType;
    [self setDefaultMaskType:maskType];
    [self showWithStatus:status];
    [self setDefaultMaskType:existingMaskType];
}

+ (void)showProgress:(float)progress {
    [self showProgress:progress status:nil];
}

+ (void)showProgress:(float)progress maskType:(WZProgressHUDMaskType)maskType {
    WZProgressHUDMaskType existingMaskType = [self sharedView].defaultMaskType;
    [self setDefaultMaskType:maskType];
    [self showProgress:progress];
    [self setDefaultMaskType:existingMaskType];
}

+ (void)showProgress:(float)progress status:(NSString*)status {
    [[self sharedView] showProgress:progress status:status];
}

+ (void)showProgress:(float)progress status:(NSString*)status maskType:(WZProgressHUDMaskType)maskType {
    WZProgressHUDMaskType existingMaskType = [self sharedView].defaultMaskType;
    [self setDefaultMaskType:maskType];
    [self showProgress:progress status:status];
    [self setDefaultMaskType:existingMaskType];
}


#pragma mark - Show, then automatically dismiss methods

+ (void)showInfoWithStatus:(NSString*)status {
    [self showImage:[self sharedView].infoImage status:status];
    
#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
    if (@available(iOS 10.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self sharedView].hapticGenerator notificationOccurred:UINotificationFeedbackTypeWarning];
        });
    }
#endif
}

+ (void)showInfoWithStatus:(NSString*)status maskType:(WZProgressHUDMaskType)maskType {
    WZProgressHUDMaskType existingMaskType = [self sharedView].defaultMaskType;
    [self setDefaultMaskType:maskType];
    [self showInfoWithStatus:status];
    [self setDefaultMaskType:existingMaskType];
}

+ (void)showSuccessWithStatus:(NSString*)status {
    [self showImage:[self sharedView].successImage status:status];

#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
    if (@available(iOS 10, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self sharedView].hapticGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
        });
    }
#endif
}

+ (void)showSuccessWithStatus:(NSString*)status maskType:(WZProgressHUDMaskType)maskType {
    WZProgressHUDMaskType existingMaskType = [self sharedView].defaultMaskType;
    [self setDefaultMaskType:maskType];
    [self showSuccessWithStatus:status];
    [self setDefaultMaskType:existingMaskType];
    
#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
    if (@available(iOS 10.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self sharedView].hapticGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
        });
    }
#endif
}

+ (void)showErrorWithStatus:(NSString*)status {
    [self showImage:[self sharedView].errorImage status:status];
    
#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
    if (@available(iOS 10.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self sharedView].hapticGenerator notificationOccurred:UINotificationFeedbackTypeError];
        });
    }
#endif
}

+ (void)showErrorWithStatus:(NSString*)status maskType:(WZProgressHUDMaskType)maskType {
    WZProgressHUDMaskType existingMaskType = [self sharedView].defaultMaskType;
    [self setDefaultMaskType:maskType];
    [self showErrorWithStatus:status];
    [self setDefaultMaskType:existingMaskType];
    
#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
    if (@available(iOS 10.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self sharedView].hapticGenerator notificationOccurred:UINotificationFeedbackTypeError];
        });
    }
#endif
}

+ (void)showTextWithStatus:(nullable NSString*)status {
    NSTimeInterval displayInterval = [self displayDurationForString:status];
    [[self sharedView] showImage:nil status:status duration:displayInterval];
}

+ (void)showImage:(UIImage*)image status:(NSString*)status {
    NSTimeInterval displayInterval = [self displayDurationForString:status];
    [[self sharedView] showImage:image status:status duration:displayInterval];
}

+ (void)showImage:(UIImage*)image status:(NSString*)status maskType:(WZProgressHUDMaskType)maskType {
    WZProgressHUDMaskType existingMaskType = [self sharedView].defaultMaskType;
    [self setDefaultMaskType:maskType];
    [self showImage:image status:status];
    [self setDefaultMaskType:existingMaskType];
}


#pragma mark - Dismiss Methods

+ (void)popActivity {
    if([self sharedView].activityCount > 0) {
        [self sharedView].activityCount--;
    }
    if([self sharedView].activityCount == 0) {
        [[self sharedView] dismiss];
    }
}

+ (void)dismiss {
    [self dismissWithDelay:0.0 completion:nil];
}

+ (void)dismissWithCompletion:(WZProgressHUDDismissCompletion)completion {
    [self dismissWithDelay:0.0 completion:completion];
}

+ (void)dismissWithDelay:(NSTimeInterval)delay {
    [self dismissWithDelay:delay completion:nil];
}

+ (void)dismissWithDelay:(NSTimeInterval)delay completion:(WZProgressHUDDismissCompletion)completion {
    [[self sharedView] dismissWithDelay:delay completion:completion];
}

#pragma mark - Offset

+ (void)setOffsetFromCenter:(UIOffset)offset {
    [self sharedView].offsetFromCenter = offset;
}

+ (void)resetOffsetFromCenter {
    [self setOffsetFromCenter:UIOffsetZero];
}


#pragma mark - Instance Methods

- (instancetype)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
        _isInitializing = YES;
        
        self.userInteractionEnabled = NO;
        self.activityCount = 0;
        
        self.backgroundView.alpha = 0.0f;
        self.imageView.alpha = 0.0f;
        self.statusLabel.alpha = 0.0f;
        self.indefiniteAnimatedView.alpha = 0.0f;
        self.ringView.alpha = self.backgroundRingView.alpha = 0.0f;
        

        _backgroundColor = [UIColor whiteColor];
        _foregroundColor = [UIColor blackColor];
        _backgroundLayerColor = [UIColor colorWithWhite:0 alpha:0.4];
        
        // Set default values
        _defaultMaskType = WZProgressHUDMaskTypeNone;
        _defaultStyle = WZProgressHUDStyleLight;
        _defaultAnimationType = WZProgressHUDAnimationTypeNative;
        _minimumSize = CGSizeZero;
        _font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        
        _imageViewSize = CGSizeMake(36.0f, 36.0f);
        _shouldTintImages = YES;
        
        _infoImage = [UIImage imageNamed:@"WZProgressHUD.bundle/info"];
        _successImage = [UIImage imageNamed:@"WZProgressHUD.bundle/success"];
        _errorImage = [UIImage imageNamed:@"WZProgressHUD.bundle/error"];

        _ringThickness = 2.0f;
        _ringRadius = 18.0f;
        _ringNoTextRadius = 24.0f;
        
        _cornerRadius = 14.0f;
        
        _graceTimeInterval = 0.0f;
        _minimumDismissTimeInterval = 5.0;
        _maximumDismissTimeInterval = CGFLOAT_MAX;

        _fadeInAnimationDuration = WZProgressHUDDefaultAnimationDuration;
        _fadeOutAnimationDuration = WZProgressHUDDefaultAnimationDuration;
        
        _maxSupportedWindowLevel = UIWindowLevelNormal;
        
        _hapticsEnabled = NO;
        _motionEffectEnabled = YES;
        _maxSize = CGSizeMake(200, 300);
        // 辅助功能支持
        self.accessibilityIdentifier = @"WZProgressHUD";
        self.isAccessibilityElement = YES;
        
        _isInitializing = NO;
    }
    return self;
}

- (void)updateHUDFrame {
    
    // 检查是否显示图像或进度环
    BOOL imageUsed = (self.imageView.image) && !(self.imageView.hidden);
    BOOL progressUsed = self.imageView.hidden;
    
    // 计算弦大小
    CGRect labelRect = CGRectZero;
    CGFloat labelHeight = 0.0f;
    CGFloat labelWidth = 0.0f;
    
    if(self.statusLabel.text) {
        CGSize constraintSize = self.maxSize;
        labelRect = [self.statusLabel.text boundingRectWithSize:constraintSize
                                                        options:(NSStringDrawingOptions)(NSStringDrawingUsesFontLeading | NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin)
                                                     attributes:@{NSFontAttributeName: self.statusLabel.font}
                                                        context:NULL];
        labelHeight = ceilf(CGRectGetHeight(labelRect));
        labelWidth = ceilf(CGRectGetWidth(labelRect));
    }
    
    //根据内容计算hud大小
    //对于开始使用默认值，这些
    //如果字符串太大，可能会得到更新
    CGFloat hudWidth;
    CGFloat hudHeight;
    
    CGFloat contentWidth = 0.0f;
    CGFloat contentHeight = 0.0f;
    
    if(imageUsed || progressUsed) {
        contentWidth = CGRectGetWidth(imageUsed ? self.imageView.frame : self.indefiniteAnimatedView.frame);
        contentHeight = CGRectGetHeight(imageUsed ? self.imageView.frame : self.indefiniteAnimatedView.frame);
    }
    
    // |-间距-内容-间距-|
    hudWidth = WZProgressHUDHorizontalSpacing + MAX(labelWidth, contentWidth) + WZProgressHUDHorizontalSpacing;
    
    // |-间距-内容-(标签间距-标签-)间距-|
    hudHeight = WZProgressHUDVerticalSpacing + labelHeight + contentHeight + WZProgressHUDVerticalSpacing;
    if(self.statusLabel.text && (imageUsed || progressUsed)){
        // 如果同时使用内容和标签，则添加间距
        hudHeight += WZProgressHUDLabelSpacing;
    }
    
    // 更新子视图上的值
    self.hudView.bounds = CGRectMake(0.0f, 0.0f, MAX(self.minimumSize.width, hudWidth), MAX(self.minimumSize.height, hudHeight));
    
    // 动画值更新
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    // 微调器和图像视图
    CGFloat centerY;
    if(self.statusLabel.text) {
        CGFloat yOffset = MAX(WZProgressHUDVerticalSpacing, (self.minimumSize.height - contentHeight - WZProgressHUDLabelSpacing - labelHeight) / 2.0f);
        centerY = yOffset + contentHeight / 2.0f;
    } else {
        centerY = CGRectGetMidY(self.hudView.bounds);
    }
    self.indefiniteAnimatedView.center = CGPointMake(CGRectGetMidX(self.hudView.bounds), centerY);
    if(self.progress != WZProgressHUDUndefinedProgress) {
        self.backgroundRingView.center = self.ringView.center = CGPointMake(CGRectGetMidX(self.hudView.bounds), centerY);
    }
    self.imageView.center = CGPointMake(CGRectGetMidX(self.hudView.bounds), centerY);

    // 标签
    if(imageUsed || progressUsed) {
        centerY = CGRectGetMaxY(imageUsed ? self.imageView.frame : self.indefiniteAnimatedView.frame) + WZProgressHUDLabelSpacing + labelHeight / 2.0f;
    } else {
        centerY = CGRectGetMidY(self.hudView.bounds);
    }
    self.statusLabel.frame = labelRect;
    self.statusLabel.center = CGPointMake(CGRectGetMidX(self.hudView.bounds), centerY);
    
    [CATransaction commit];
}

#if TARGET_OS_IOS
- (void)updateMotionEffectForOrientation:(UIInterfaceOrientation)orientation {
    UIInterpolatingMotionEffectType xMotionEffectType = UIInterfaceOrientationIsPortrait(orientation) ? UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis : UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis;
    UIInterpolatingMotionEffectType yMotionEffectType = UIInterfaceOrientationIsPortrait(orientation) ? UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis : UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis;
    [self updateMotionEffectForXMotionEffectType:xMotionEffectType yMotionEffectType:yMotionEffectType];
}
#endif

- (void)updateMotionEffectForXMotionEffectType:(UIInterpolatingMotionEffectType)xMotionEffectType yMotionEffectType:(UIInterpolatingMotionEffectType)yMotionEffectType {
    UIInterpolatingMotionEffect *effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:xMotionEffectType];
    effectX.minimumRelativeValue = @(-WZProgressHUDParallaxDepthPoints);
    effectX.maximumRelativeValue = @(WZProgressHUDParallaxDepthPoints);
    
    UIInterpolatingMotionEffect *effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:yMotionEffectType];
    effectY.minimumRelativeValue = @(-WZProgressHUDParallaxDepthPoints);
    effectY.maximumRelativeValue = @(WZProgressHUDParallaxDepthPoints);
    
    UIMotionEffectGroup *effectGroup = [UIMotionEffectGroup new];
    effectGroup.motionEffects = @[effectX, effectY];
    
    // 清除旧的运动效果，然后添加新的运动效果
    self.hudView.motionEffects = @[];
    [self.hudView addMotionEffect:effectGroup];
}

- (void)updateViewHierarchy {
    // 必要时将覆盖添加到应用程序窗口
    if(!self.controlView.superview) {
        if(self.containerView){
            [self.containerView addSubview:self.controlView];
        } else {
#if !defined(WZ_APP_EXTENSIONS)
            [self.frontWindow addSubview:self.controlView];
#else
            // 如果WZProgressHUD用于应用程序扩展，请将其添加到给定视图中
            if(self.viewForExtension) {
                [self.viewForExtension addSubview:self.controlView];
            }
#endif
        }
    } else {
        //平视显示器已经在屏幕上了，但可能不在前面因此
        //确保覆盖将位于rootViewController的顶部（可能
        //在运行时更改）
        [self.controlView.superview bringSubviewToFront:self.controlView];
    }
    
    // 将self添加到覆盖视图
    if(!self.superview) {
        [self.controlView addSubview:self];
    }
}

- (void)setStatus:(NSString*)status {
    self.statusLabel.text = status;
    self.statusLabel.hidden = status.length == 0;
    [self updateHUDFrame];
}

- (void)setGraceTimer:(NSTimer*)timer {
    if(_graceTimer) {
        [_graceTimer invalidate];
        _graceTimer = nil;
    }
    if(timer) {
        _graceTimer = timer;
    }
}

- (void)setFadeOutTimer:(NSTimer*)timer {
    if(_fadeOutTimer) {
        [_fadeOutTimer invalidate];
        _fadeOutTimer = nil;
    }
    if(timer) {
        _fadeOutTimer = timer;
    }
}


#pragma mark - Notifications and their handling

- (void)registerNotifications {
#if TARGET_OS_IOS
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
#endif
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(positionHUD:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (NSDictionary*)notificationUserInfo {
    return (self.statusLabel.text ? @{WZProgressHUDStatusUserInfoKey : self.statusLabel.text} : nil);
}

- (void)positionHUD:(NSNotification*)notification {
    CGFloat keyboardHeight = 0.0f;
    double animationDuration = 0.0;

#if !defined(WZ_APP_EXTENSIONS) && TARGET_OS_IOS
    self.frame = [[[UIApplication sharedApplication] delegate] window].bounds;
    UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
#elif !defined(WZ_APP_EXTENSIONS) && !TARGET_OS_IOS
    self.frame= [UIApplication sharedApplication].keyWindow.bounds;
#else
    if (self.viewForExtension) {
        self.frame = self.viewForExtension.frame;
    } else {
        self.frame = UIScreen.mainScreen.bounds;
    }
#if TARGET_OS_IOS
    UIInterfaceOrientation orientation = CGRectGetWidth(self.frame) > CGRectGetHeight(self.frame) ? UIInterfaceOrientationLandscapeLeft : UIInterfaceOrientationPortrait;
#endif
#endif
    
#if TARGET_OS_IOS
    // 根据当前状态获取键盘高度
    if(notification) {
        NSDictionary* keyboardInfo = [notification userInfo];
        CGRect keyboardFrame = [keyboardInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        animationDuration = [keyboardInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        if(notification.name == UIKeyboardWillShowNotification || notification.name == UIKeyboardDidShowNotification) {
            keyboardHeight = CGRectGetWidth(keyboardFrame);
            
            if(UIInterfaceOrientationIsPortrait(orientation)) {
                keyboardHeight = CGRectGetHeight(keyboardFrame);
            }
        }
    } else {
        keyboardHeight = self.visibleKeyboardHeight;
    }
#endif
    
    // 获取显示的当前活动帧（取决于方向）
    CGRect orientationFrame = self.bounds;

#if !defined(WZ_APP_EXTENSIONS) && TARGET_OS_IOS
    CGRect statusBarFrame = UIApplication.sharedApplication.statusBarFrame;
#else
    CGRect statusBarFrame = CGRectZero;
#endif
    
    if (_motionEffectEnabled) {
#if TARGET_OS_IOS
        // 更新有关方向的运动效果
        [self updateMotionEffectForOrientation:orientation];
#else
        [self updateMotionEffectForXMotionEffectType:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis yMotionEffectType:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
#endif
    }
    
    // 计算显示的可用高度
    CGFloat activeHeight = CGRectGetHeight(orientationFrame);
    if(keyboardHeight > 0) {
        activeHeight += CGRectGetHeight(statusBarFrame) * 2;
    }
    activeHeight -= keyboardHeight;
    
    CGFloat posX = CGRectGetMidX(orientationFrame);
    CGFloat posY = floorf(activeHeight*0.45f);

    CGFloat rotateAngle = 0.0;
    CGPoint newCenter = CGPointMake(posX, posY);
    
    if(notification) {
        // 如果存在通知，则设置更新动画
        [UIView animateWithDuration:animationDuration
                              delay:0
                            options:(UIViewAnimationOptions) (UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
                             [self moveToPoint:newCenter rotateAngle:rotateAngle];
                             [self.hudView setNeedsDisplay];
                         } completion:nil];
    } else {
        [self moveToPoint:newCenter rotateAngle:rotateAngle];
    }
}

- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle {
    self.hudView.transform = CGAffineTransformMakeRotation(angle);
    if (self.containerView) {
        self.hudView.center = CGPointMake(self.containerView.center.x + self.offsetFromCenter.horizontal, self.containerView.center.y + self.offsetFromCenter.vertical);
    } else {
        self.hudView.center = CGPointMake(newCenter.x + self.offsetFromCenter.horizontal, newCenter.y + self.offsetFromCenter.vertical);
    }
}


#pragma mark - Event handling

- (void)controlViewDidReceiveTouchEvent:(id)sender forEvent:(UIEvent*)event {
    [[NSNotificationCenter defaultCenter] postNotificationName:WZProgressHUDDidReceiveTouchEventNotification
                                                        object:self
                                                      userInfo:[self notificationUserInfo]];
    
    UITouch *touch = event.allTouches.anyObject;
    CGPoint touchLocation = [touch locationInView:self];
    
    if(CGRectContainsPoint(self.hudView.frame, touchLocation)) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WZProgressHUDDidTouchDownInsideNotification
                                                            object:self
                                                          userInfo:[self notificationUserInfo]];
    }
}


#pragma mark - Master show/dismiss methods

- (void)showProgress:(float)progress status:(NSString*)status {
    __weak WZProgressHUD *weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        __strong WZProgressHUD *strongSelf = weakSelf;
        if(strongSelf){
            if(strongSelf.fadeOutTimer) {
                strongSelf.activityCount = 0;
            }
            
            // 停止时间
            strongSelf.fadeOutTimer = nil;
            strongSelf.graceTimer = nil;
            
            // 更新/检查视图层次结构以确保HUD可见
            [strongSelf updateViewHierarchy];
            
            // 如果当前显示图像，则重置图像视图并淡出计时器
            strongSelf.imageView.hidden = YES;
            strongSelf.imageView.image = nil;
            
            // 更新文本并将进度设置为给定值
            strongSelf.statusLabel.hidden = status.length == 0;
            strongSelf.statusLabel.text = status;
            strongSelf.progress = progress;
            
            // 根据进度选择“右”指示器
            if(progress >= 0) {
                // 取消不确定的动画视图，然后显示环层
                [strongSelf cancelIndefiniteAnimatedViewAnimation];
                
                // 将环添加到抬头显示器
                if(!strongSelf.ringView.superview){
                    [strongSelf.hudView.contentView addSubview:strongSelf.ringView];
                }
                if(!strongSelf.backgroundRingView.superview){
                    [strongSelf.hudView.contentView addSubview:strongSelf.backgroundRingView];
                }
                
                // 设置进度动画
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                strongSelf.ringView.strokeEnd = progress;
                [CATransaction commit];
                
                // 更新活动计数
                if(progress == 0) {
                    strongSelf.activityCount++;
                }
            } else {
                // 取消ringLayer动画，然后显示indefiniteAnimatedView
                [strongSelf cancelRingLayerAnimation];
                
                // 将indefiniteAnimatedView添加到HUD
                [strongSelf.hudView.contentView addSubview:strongSelf.indefiniteAnimatedView];
                if([strongSelf.indefiniteAnimatedView respondsToSelector:@selector(startAnimating)]) {
                    [(id)strongSelf.indefiniteAnimatedView startAnimating];
                }
                
                // 更新活动计数
                strongSelf.activityCount++;
            }
            
            // 如果设置了宽限期，则延迟淡入
            if (self.graceTimeInterval > 0.0 && self.backgroundView.alpha == 0.0f) {
                strongSelf.graceTimer = [NSTimer timerWithTimeInterval:self.graceTimeInterval target:strongSelf selector:@selector(fadeIn:) userInfo:nil repeats:NO];
                [[NSRunLoop mainRunLoop] addTimer:strongSelf.graceTimer forMode:NSRunLoopCommonModes];
            } else {
                [strongSelf fadeIn:nil];
            }
            
            // 告诉触觉生成器准备反馈，反馈可能很快就会到来
#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
            if (@available(iOS 10.0, *)) {
                [strongSelf.hapticGenerator prepare];
            }
#endif
        }
    }];
}

- (void)showImage:(UIImage*)image status:(NSString*)status duration:(NSTimeInterval)duration {
    __weak WZProgressHUD *weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        __strong WZProgressHUD *strongSelf = weakSelf;
        if(strongSelf){
            // 停止计时器
            strongSelf.fadeOutTimer = nil;
            strongSelf.graceTimer = nil;
            
            // 更新/检查视图层次结构以确保HUD可见
            [strongSelf updateViewHierarchy];
            
            // 重置进度并取消任何正在运行的动画
            strongSelf.progress = WZProgressHUDUndefinedProgress;
            [strongSelf cancelRingLayerAnimation];
            [strongSelf cancelIndefiniteAnimatedViewAnimation];
            
            // 更新imageView
            if (self.shouldTintImages) {
                if (image.renderingMode != UIImageRenderingModeAlwaysTemplate) {
                    strongSelf.imageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                }
                strongSelf.imageView.tintColor = strongSelf.foregroundImageColorForStyle;
            } else {
                strongSelf.imageView.image = image;
            }
            strongSelf.imageView.hidden = NO;
            
            // 更新文本
            strongSelf.statusLabel.hidden = status.length == 0;
            strongSelf.statusLabel.text = status;
            
            //如果设置了宽限期，则延迟淡入
            //图像将被自动删除因此，将持续时间作为userInfo传递。
            if (self.graceTimeInterval > 0.0 && self.backgroundView.alpha == 0.0f) {
                strongSelf.graceTimer = [NSTimer timerWithTimeInterval:self.graceTimeInterval target:strongSelf selector:@selector(fadeIn:) userInfo:@(duration) repeats:NO];
                [[NSRunLoop mainRunLoop] addTimer:strongSelf.graceTimer forMode:NSRunLoopCommonModes];
            } else {
                [strongSelf fadeIn:@(duration)];
            }
        }
    }];
}


- (void)fadeIn:(id)data {
    // 将抬头显示器框架更新为新内容并定位抬头显示器
    [self updateHUDFrame];
    [self positionHUD:nil];
    
    // 更新可访问性和用户交互
    // \n导致读取文本两次，因此在设置可访问性标签之前删除“\n”新行字符
    NSString *accessibilityString = [[self.statusLabel.text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    if(self.defaultMaskType != WZProgressHUDMaskTypeNone) {
        self.controlView.userInteractionEnabled = YES;
        self.accessibilityLabel =  accessibilityString ?: NSLocalizedString(@"Loading", nil);
        self.isAccessibilityElement = YES;
        self.controlView.accessibilityViewIsModal = YES;
    } else {
        self.controlView.userInteractionEnabled = NO;
        self.hudView.accessibilityLabel = accessibilityString ?: NSLocalizedString(@"Loading", nil);
        self.hudView.isAccessibilityElement = YES;
        self.controlView.accessibilityViewIsModal = NO;
    }
    
    // 获取持续时间
    id duration = [data isKindOfClass:[NSTimer class]] ? ((NSTimer *)data).userInfo : data;
    
    // 如果尚未显示，则显示
    if(self.backgroundView.alpha != 1.0f) {
        // 发布通知通知用户
        [[NSNotificationCenter defaultCenter] postNotificationName:WZProgressHUDWillAppearNotification
                                                            object:self
                                                          userInfo:[self notificationUserInfo]];
        
        // 缩小HUD以制作一个漂亮的显示/弹出动画
        self.hudView.transform = self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 1/1.5f, 1/1.5f);
        
        __block void (^animationsBlock)(void) = ^{
            // 将平视显示器放大一点以制作一个漂亮的显示/弹出动画
            self.hudView.transform = CGAffineTransformIdentity;
            
            // 淡入所有效果（颜色、模糊等）
            [self fadeInEffects];
        };
        
        __block void (^completionBlock)(void) = ^{
            //检查我们是否真的实现了显示HUD（<=>alpha）
            //而这些价值的变化并没有被取消，例如，由于解雇
            if(self.backgroundView.alpha == 1.0f){
                // 注册观察员<=>我们现在必须处理方位变化等。
                [self registerNotifications];
                
                // 发布通知通知用户
                [[NSNotificationCenter defaultCenter] postNotificationName:WZProgressHUDDidAppearNotification
                                                                    object:self
                                                                  userInfo:[self notificationUserInfo]];
                
                // 更新辅助功能
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, self.statusLabel.text);
                
                // 如果持续时间作为userInfo传递，则自动关闭我们开始计时
                // 然后在预定义的持续时间之后调用dismise
                if(duration){
                    self.fadeOutTimer = [NSTimer timerWithTimeInterval:[(NSNumber *)duration doubleValue] target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
                    [[NSRunLoop mainRunLoop] addTimer:self.fadeOutTimer forMode:NSRunLoopCommonModes];
                }
            }
        };
        
        // 设置外观动画
        if (self.fadeInAnimationDuration > 0) {
            // 设置外观动画
            [UIView animateWithDuration:self.fadeInAnimationDuration
                                  delay:0
                                options:(UIViewAnimationOptions) (UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState)
                             animations:^{
                                 animationsBlock();
                             } completion:^(BOOL finished) {
                                 completionBlock();
                             }];
        } else {
            animationsBlock();
            completionBlock();
        }
        
        // 通知iOS重新绘制视图层次结构
        [self setNeedsDisplay];
    } else {
        // 更新辅助功能
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, self.statusLabel.text);
        
        // 如果持续时间作为userInfo传递，则自动关闭我们开始计时
        // 然后在预定义的持续时间之后调用dismise
        if(duration){
            self.fadeOutTimer = [NSTimer timerWithTimeInterval:[(NSNumber *)duration doubleValue] target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:self.fadeOutTimer forMode:NSRunLoopCommonModes];
        }
    }
}

- (void)dismiss {
    [self dismissWithDelay:0.0 completion:nil];
}

- (void)dismissWithDelay:(NSTimeInterval)delay completion:(WZProgressHUDDismissCompletion)completion {
    __weak WZProgressHUD *weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        __strong WZProgressHUD *strongSelf = weakSelf;
        if(strongSelf){
            
            // 发布通知通知用户
            [[NSNotificationCenter defaultCenter] postNotificationName:WZProgressHUDWillDisappearNotification
                                                                object:nil
                                                              userInfo:[strongSelf notificationUserInfo]];
            
            // 重置活动计数
            strongSelf.activityCount = 0;
            
            __block void (^animationsBlock)(void) = ^{
                // 缩小平视显示器一点，使一个很好的消失动画
                strongSelf.hudView.transform = CGAffineTransformScale(strongSelf.hudView.transform, 1/1.3f, 1/1.3f);
                
                // 淡出所有效果（颜色、模糊等)
                [strongSelf fadeOutEffects];
            };
            
            __block void (^completionBlock)(void) = ^{
                // 检查我们是否真的实现了关闭抬头显示器（应用α值）
                // 这些数值的变化并没有被取消，例如，由于一个新的节目
                if(self.backgroundView.alpha == 0.0f){
                    // 清除视图层次结构（覆盖）
                    [strongSelf.controlView removeFromSuperview];
                    [strongSelf.backgroundView removeFromSuperview];
                    [strongSelf.hudView removeFromSuperview];
                    [strongSelf removeFromSuperview];
                    
                    // 重置进度并取消任何正在运行的动画
                    strongSelf.progress = WZProgressHUDUndefinedProgress;
                    [strongSelf cancelRingLayerAnimation];
                    [strongSelf cancelIndefiniteAnimatedViewAnimation];
                    
                    // 移除观察者<=>我们不必处理方位变化等
                    [[NSNotificationCenter defaultCenter] removeObserver:strongSelf];
                    
                    // 发布通知通知用户
                    [[NSNotificationCenter defaultCenter] postNotificationName:WZProgressHUDDidDisappearNotification
                                                                        object:strongSelf
                                                                      userInfo:[strongSelf notificationUserInfo]];
                    
                    // 告诉rootViewController更新StatusBar外观
#if !defined(WZ_APP_EXTENSIONS) && TARGET_OS_IOS
                    UIViewController *rootController = [[UIApplication sharedApplication] keyWindow].rootViewController;
                    [rootController setNeedsStatusBarAppearanceUpdate];
#endif
                    
                    // 运行 completionHandler
                    if (completion) {
                        completion();
                    }
                }
            };
            
            // UIViewAnimationOptionBeginFromCurrentState AND a delay doesn't always work as expected
            // When UIViewAnimationOptionBeginFromCurrentState is set, animateWithDuration: evaluates the current
            // values to check if an animation is necessary. The evaluation happens at function call time and not
            // after the delay => the animation is sometimes skipped. Therefore we delay using dispatch_after.
            
            dispatch_time_t dipatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
            dispatch_after(dipatchTime, dispatch_get_main_queue(), ^{
                
                // 停止时间
                strongSelf.graceTimer = nil;
                
                if (strongSelf.fadeOutAnimationDuration > 0) {
                    // 动画外观
                    [UIView animateWithDuration:strongSelf.fadeOutAnimationDuration
                                          delay:0
                                        options:(UIViewAnimationOptions) (UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState)
                                     animations:^{
                                         animationsBlock();
                                     } completion:^(BOOL finished) {
                                         completionBlock();
                                     }];
                } else {
                    animationsBlock();
                    completionBlock();
                }
            });
            
            // Inform iOS to redraw the view hierarchy
            [strongSelf setNeedsDisplay];
        }
    }];
}


#pragma mark - Ring progress animation

- (UIView*)indefiniteAnimatedView {
    // 为defaultAnimationType获取正确的微调器
    if(self.defaultAnimationType == WZProgressHUDAnimationTypeFlat){
        // 检查SPEnter是否存在并且是不同类的对象
        if(_indefiniteAnimatedView && ![_indefiniteAnimatedView isKindOfClass:[WZIndefiniteAnimatedView class]]){
            [_indefiniteAnimatedView removeFromSuperview];
            _indefiniteAnimatedView = nil;
        }
        
        if(!_indefiniteAnimatedView){
            _indefiniteAnimatedView = [[WZIndefiniteAnimatedView alloc] initWithFrame:CGRectZero];
        }
        
        // Update styling
        WZIndefiniteAnimatedView *indefiniteAnimatedView = (WZIndefiniteAnimatedView*)_indefiniteAnimatedView;
        indefiniteAnimatedView.strokeColor = self.foregroundImageColorForStyle;
        indefiniteAnimatedView.strokeThickness = self.ringThickness;
        indefiniteAnimatedView.radius = self.statusLabel.text ? self.ringRadius : self.ringNoTextRadius;
    } else {
        // Check if spinner exists and is an object of different class
        if(_indefiniteAnimatedView && ![_indefiniteAnimatedView isKindOfClass:[UIActivityIndicatorView class]]){
            [_indefiniteAnimatedView removeFromSuperview];
            _indefiniteAnimatedView = nil;
        }
        
        if(!_indefiniteAnimatedView){
            _indefiniteAnimatedView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        }
        
        // Update styling
        UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView*)_indefiniteAnimatedView;
        activityIndicatorView.color = self.foregroundImageColorForStyle;
    }
    [_indefiniteAnimatedView sizeToFit];
    
    return _indefiniteAnimatedView;
}

- (WZProgressAnimatedView*)ringView {
    if(!_ringView) {
        _ringView = [[WZProgressAnimatedView alloc] initWithFrame:CGRectZero];
    }
    
    // Update styling
    _ringView.strokeColor = self.foregroundImageColorForStyle;
    _ringView.strokeThickness = self.ringThickness;
    _ringView.radius = self.statusLabel.text ? self.ringRadius : self.ringNoTextRadius;
    
    return _ringView;
}

- (WZProgressAnimatedView*)backgroundRingView {
    if(!_backgroundRingView) {
        _backgroundRingView = [[WZProgressAnimatedView alloc] initWithFrame:CGRectZero];
        _backgroundRingView.strokeEnd = 1.0f;
    }
    
    // Update styling
    _backgroundRingView.strokeColor = [self.foregroundImageColorForStyle colorWithAlphaComponent:0.1f];
    _backgroundRingView.strokeThickness = self.ringThickness;
    _backgroundRingView.radius = self.statusLabel.text ? self.ringRadius : self.ringNoTextRadius;
    
    return _backgroundRingView;
}

- (void)cancelRingLayerAnimation {
    // Animate value update, stop animation
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [self.hudView.layer removeAllAnimations];
    self.ringView.strokeEnd = 0.0f;
    
    [CATransaction commit];
    
    // Remove from view
    [self.ringView removeFromSuperview];
    [self.backgroundRingView removeFromSuperview];
}

- (void)cancelIndefiniteAnimatedViewAnimation {
    // Stop animation
    if([self.indefiniteAnimatedView respondsToSelector:@selector(stopAnimating)]) {
        [(id)self.indefiniteAnimatedView stopAnimating];
    }
    // Remove from view
    [self.indefiniteAnimatedView removeFromSuperview];
}


#pragma mark - Utilities

+ (BOOL)isVisible {
    // Checking one alpha value is sufficient as they are all the same
    return [self sharedView].backgroundView.alpha > 0.0f;
}


#pragma mark - Getters

+ (NSTimeInterval)displayDurationForString:(NSString*)string {
    CGFloat minimum = MAX((CGFloat)string.length * 0.06 + 0.5, [self sharedView].minimumDismissTimeInterval);
    return MIN(minimum, [self sharedView].maximumDismissTimeInterval);
}

- (UIColor*)foregroundColorForStyle {
    if(self.defaultStyle == WZProgressHUDStyleLight) {
        return [UIColor blackColor];
    } else if(self.defaultStyle == WZProgressHUDStyleDark) {
        return [UIColor whiteColor];
    } else {
        return self.foregroundColor;
    }
}

- (UIColor*)foregroundImageColorForStyle {
    if (self.foregroundImageColor) {
        return self.foregroundImageColor;
    } else {
        return [self foregroundColorForStyle];
    }
}

- (UIColor*)backgroundColorForStyle {
    if(self.defaultStyle == WZProgressHUDStyleLight) {
        return [UIColor whiteColor];
    } else if(self.defaultStyle == WZProgressHUDStyleDark) {
        return [UIColor blackColor];
    } else {
        return self.backgroundColor;
    }
}

- (UIControl*)controlView {
    if(!_controlView) {
        _controlView = [UIControl new];
        _controlView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _controlView.backgroundColor = [UIColor clearColor];
        _controlView.userInteractionEnabled = YES;
        [_controlView addTarget:self action:@selector(controlViewDidReceiveTouchEvent:forEvent:) forControlEvents:UIControlEventTouchDown];
    }
    
    // Update frames
#if !defined(WZ_APP_EXTENSIONS)
    CGRect windowBounds = [[[UIApplication sharedApplication] delegate] window].bounds;
    _controlView.frame = windowBounds;
#else
    _controlView.frame = [UIScreen mainScreen].bounds;
#endif
    
    return _controlView;
}

-(UIView *)backgroundView {
    if(!_backgroundView){
        _backgroundView = [UIView new];
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    if(!_backgroundView.superview){
        [self insertSubview:_backgroundView belowSubview:self.hudView];
    }
    
    // Update styling
    if(self.defaultMaskType == WZProgressHUDMaskTypeGradient){
        if(!_backgroundRadialGradientLayer){
            _backgroundRadialGradientLayer = [WZRadialGradientLayer layer];
        }
        if(!_backgroundRadialGradientLayer.superlayer){
            [_backgroundView.layer insertSublayer:_backgroundRadialGradientLayer atIndex:0];
        }
        _backgroundView.backgroundColor = [UIColor clearColor];
    } else {
        if(_backgroundRadialGradientLayer && _backgroundRadialGradientLayer.superlayer){
            [_backgroundRadialGradientLayer removeFromSuperlayer];
        }
        if(self.defaultMaskType == WZProgressHUDMaskTypeBlack){
            _backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        } else if(self.defaultMaskType == WZProgressHUDMaskTypeCustom){
            _backgroundView.backgroundColor = self.backgroundLayerColor;
        } else {
            _backgroundView.backgroundColor = [UIColor clearColor];
        }
    }

    // Update frame
    if(_backgroundView){
        _backgroundView.frame = self.bounds;
    }
    if(_backgroundRadialGradientLayer){
        _backgroundRadialGradientLayer.frame = self.bounds;
        
        // Calculate the new center of the gradient, it may change if keyboard is visible
        CGPoint gradientCenter = self.center;
        gradientCenter.y = (self.bounds.size.height - self.visibleKeyboardHeight)/2;
        _backgroundRadialGradientLayer.gradientCenter = gradientCenter;
        [_backgroundRadialGradientLayer setNeedsDisplay];
    }
    
    return _backgroundView;
}
- (UIVisualEffectView*)hudView {
    if(!_hudView) {
        _hudView = [UIVisualEffectView new];
        _hudView.layer.masksToBounds = YES;
        _hudView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    }
    if(!_hudView.superview) {
        [self addSubview:_hudView];
    }
    
    // Update styling
    _hudView.layer.cornerRadius = self.cornerRadius;
    
    return _hudView;
}

- (UILabel*)statusLabel {
    if(!_statusLabel) {
        _statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _statusLabel.backgroundColor = [UIColor clearColor];
        _statusLabel.adjustsFontSizeToFitWidth = YES;
        _statusLabel.textAlignment = NSTextAlignmentCenter;
        _statusLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        _statusLabel.numberOfLines = 0;
    }
    if(!_statusLabel.superview) {
      [self.hudView.contentView addSubview:_statusLabel];
    }
    
    // Update styling
    _statusLabel.textColor = self.foregroundColorForStyle;
    _statusLabel.font = self.font;

    return _statusLabel;
}

- (UIImageView*)imageView {
    if(_imageView && !CGSizeEqualToSize(_imageView.bounds.size, _imageViewSize)) {
        [_imageView removeFromSuperview];
        _imageView = nil;
    }
    
    if(!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, _imageViewSize.width, _imageViewSize.height)];
    }
    if(!_imageView.superview) {
        [self.hudView.contentView addSubview:_imageView];
    }
    
    return _imageView;
}


#pragma mark - Helper
    
- (CGFloat)visibleKeyboardHeight {
#if !defined(WZ_APP_EXTENSIONS)
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in UIApplication.sharedApplication.windows) {
        if(![testWindow.class isEqual:UIWindow.class]) {
            keyboardWindow = testWindow;
            break;
        }
    }
    
    for (__strong UIView *possibleKeyboard in keyboardWindow.subviews) {
        NSString *viewName = NSStringFromClass(possibleKeyboard.class);
        if([viewName hasPrefix:@"UI"]){
            if([viewName hasSuffix:@"PeripheralHostView"] || [viewName hasSuffix:@"Keyboard"]){
                return CGRectGetHeight(possibleKeyboard.bounds);
            } else if ([viewName hasSuffix:@"InputSetContainerView"]){
                for (__strong UIView *possibleKeyboardSubview in possibleKeyboard.subviews) {
                    viewName = NSStringFromClass(possibleKeyboardSubview.class);
                    if([viewName hasPrefix:@"UI"] && [viewName hasSuffix:@"InputSetHostView"]) {
                        CGRect convertedRect = [possibleKeyboard convertRect:possibleKeyboardSubview.frame toView:self];
                        CGRect intersectedRect = CGRectIntersection(convertedRect, self.bounds);
                        if (!CGRectIsNull(intersectedRect)) {
                            return CGRectGetHeight(intersectedRect);
                        }
                    }
                }
            }
        }
    }
#endif
    return 0;
}
    
- (UIWindow *)frontWindow {
#if !defined(WZ_APP_EXTENSIONS)
    NSEnumerator *frontToBackWindows = [UIApplication.sharedApplication.windows reverseObjectEnumerator];
    for (UIWindow *window in frontToBackWindows) {
        BOOL windowOnMainScreen = window.screen == UIScreen.mainScreen;
        BOOL windowIsVisible = !window.hidden && window.alpha > 0;
        BOOL windowLevelSupported = (window.windowLevel >= UIWindowLevelNormal && window.windowLevel <= self.maxSupportedWindowLevel);
        BOOL windowKeyWindow = window.isKeyWindow;
            
        if(windowOnMainScreen && windowIsVisible && windowLevelSupported && windowKeyWindow) {
            return window;
        }
    }
#endif
    return nil;
}
    
- (void)fadeInEffects {
    if(self.defaultStyle != WZProgressHUDStyleCustom) {
        // Add blur effect
        UIBlurEffectStyle blurEffectStyle = self.defaultStyle == WZProgressHUDStyleDark ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:blurEffectStyle];
        self.hudView.effect = blurEffect;
        
        // We omit UIVibrancy effect and use a suitable background color as an alternative.
        // This will make everything more readable. See the following for details:
        // https://www.omnigroup.com/developer/how-to-make-text-in-a-uivisualeffectview-readable-on-any-background
        
        self.hudView.backgroundColor = [self.backgroundColorForStyle colorWithAlphaComponent:0.6f];
    } else {
        self.hudView.effect = self.hudViewCustomBlurEffect;
        self.hudView.backgroundColor =  self.backgroundColorForStyle;
    }

    // Fade in views
    self.backgroundView.alpha = 1.0f;
    
    self.imageView.alpha = 1.0f;
    self.statusLabel.alpha = 1.0f;
    self.indefiniteAnimatedView.alpha = 1.0f;
    self.ringView.alpha = self.backgroundRingView.alpha = 1.0f;
}

- (void)fadeOutEffects
{
    if(self.defaultStyle != WZProgressHUDStyleCustom) {
        // Remove blur effect
        self.hudView.effect = nil;
    }

    // Remove background color
    self.hudView.backgroundColor = [UIColor clearColor];
    
    // Fade out views
    self.backgroundView.alpha = 0.0f;
    
    self.imageView.alpha = 0.0f;
    self.statusLabel.alpha = 0.0f;
    self.indefiniteAnimatedView.alpha = 0.0f;
    self.ringView.alpha = self.backgroundRingView.alpha = 0.0f;
}

#if TARGET_OS_IOS && __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
- (UINotificationFeedbackGenerator *)hapticGenerator NS_AVAILABLE_IOS(10_0) {
    // Only return if haptics are enabled
    if(!self.hapticsEnabled) {
        return nil;
    }
    
    if(!_hapticGenerator) {
        _hapticGenerator = [[UINotificationFeedbackGenerator alloc] init];
    }
    return _hapticGenerator;
}
#endif

    
#pragma mark - UIAppearance Setters

- (void)setDefaultStyle:(WZProgressHUDStyle)style {
    if (!_isInitializing) _defaultStyle = style;
}

- (void)setDefaultMaskType:(WZProgressHUDMaskType)maskType {
    if (!_isInitializing) _defaultMaskType = maskType;
}

- (void)setDefaultAnimationType:(WZProgressHUDAnimationType)animationType {
    if (!_isInitializing) _defaultAnimationType = animationType;
}

- (void)setContainerView:(UIView *)containerView {
    if (!_isInitializing) _containerView = containerView;
}

- (void)setMinimumSize:(CGSize)minimumSize {
    if (!_isInitializing) _minimumSize = minimumSize;
}

- (void)setRingThickness:(CGFloat)ringThickness {
    if (!_isInitializing) _ringThickness = ringThickness;
}

- (void)setRingRadius:(CGFloat)ringRadius {
    if (!_isInitializing) _ringRadius = ringRadius;
}

- (void)setRingNoTextRadius:(CGFloat)ringNoTextRadius {
    if (!_isInitializing) _ringNoTextRadius = ringNoTextRadius;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    if (!_isInitializing) _cornerRadius = cornerRadius;
}

- (void)setFont:(UIFont*)font {
    if (!_isInitializing) _font = font;
}

- (void)setForegroundColor:(UIColor*)color {
    if (!_isInitializing) _foregroundColor = color;
}

- (void)setForegroundImageColor:(UIColor *)color {
    if (!_isInitializing) _foregroundImageColor = color;
}

- (void)setBackgroundColor:(UIColor*)color {
    if (!_isInitializing) _backgroundColor = color;
}

- (void)setBackgroundLayerColor:(UIColor*)color {
    if (!_isInitializing) _backgroundLayerColor = color;
}

- (void)setShouldTintImages:(BOOL)shouldTintImages {
    if (!_isInitializing) _shouldTintImages = shouldTintImages;
}

- (void)setInfoImage:(UIImage*)image {
    if (!_isInitializing) _infoImage = image;
}

- (void)setSuccessImage:(UIImage*)image {
    if (!_isInitializing) _successImage = image;
}

- (void)setErrorImage:(UIImage*)image {
    if (!_isInitializing) _errorImage = image;
}

- (void)setViewForExtension:(UIView*)view {
    if (!_isInitializing) _viewForExtension = view;
}

- (void)setOffsetFromCenter:(UIOffset)offset {
    if (!_isInitializing) _offsetFromCenter = offset;
}

- (void)setMinimumDismissTimeInterval:(NSTimeInterval)minimumDismissTimeInterval {
    if (!_isInitializing) _minimumDismissTimeInterval = minimumDismissTimeInterval;
}

- (void)setFadeInAnimationDuration:(NSTimeInterval)duration {
    if (!_isInitializing) _fadeInAnimationDuration = duration;
}

- (void)setFadeOutAnimationDuration:(NSTimeInterval)duration {
    if (!_isInitializing) _fadeOutAnimationDuration = duration;
}

- (void)setMaxSupportedWindowLevel:(UIWindowLevel)maxSupportedWindowLevel {
    if (!_isInitializing) _maxSupportedWindowLevel = maxSupportedWindowLevel;
}

@end
