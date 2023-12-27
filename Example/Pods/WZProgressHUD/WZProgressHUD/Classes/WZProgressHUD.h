//
//  WZProgressHUD.h
//  WZProgressHUD_Example
//
//  Created by xiaobin liu on 2019/11/7.
//  Copyright © 2019 LiuSky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>

extern NSString * _Nonnull const WZProgressHUDDidReceiveTouchEventNotification;
extern NSString * _Nonnull const WZProgressHUDDidTouchDownInsideNotification;
extern NSString * _Nonnull const WZProgressHUDWillDisappearNotification;
extern NSString * _Nonnull const WZProgressHUDDidDisappearNotification;
extern NSString * _Nonnull const WZProgressHUDWillAppearNotification;
extern NSString * _Nonnull const WZProgressHUDDidAppearNotification;
extern NSString * _Nonnull const WZProgressHUDStatusUserInfoKey;

/// MARK - WZProgressHUDStyle
typedef NS_ENUM(NSInteger, WZProgressHUDStyle) {
    WZProgressHUDStyleLight NS_SWIFT_NAME(light),   // 默认样式，白色抬头显示，黑色文本，抬头显示背景将模糊
    WZProgressHUDStyleDark NS_SWIFT_NAME(dark),     // 黑色抬头显示和白色文本，抬头显示背景将模糊
    WZProgressHUDStyleCustom NS_SWIFT_NAME(custom)  // 自定义 使用前景色和背景色属性
};

/// MARK - WZProgressHUDMaskType
typedef NS_ENUM(NSUInteger, WZProgressHUDMaskType) {
    WZProgressHUDMaskTypeNone NS_SWIFT_NAME(none) = 1,      // 默认遮罩类型，在显示HUD时允许用户交互
    WZProgressHUDMaskTypeClear NS_SWIFT_NAME(clear),        // 不允许用户与后台对象交互
    WZProgressHUDMaskTypeBlack NS_SWIFT_NAME(black),        // 不允许用户与背景对象进行交互，并在HUD的后面使UI变暗（如iOS 7和更高版本所示）
    WZProgressHUDMaskTypeGradient NS_SWIFT_NAME(gradient),  // 不允许用户与背景对象交互，并使用a-la UIAlertView背景渐变（如iOS 6所示）来减弱UI
    WZProgressHUDMaskTypeCustom NS_SWIFT_NAME(custom)       // 不允许用户与背景对象交互，并用自定义颜色模糊抬头显示器后面的用户界面
};

/// MARK - WZProgressHUDAnimationType
typedef NS_ENUM(NSUInteger, WZProgressHUDAnimationType) {
    WZProgressHUDAnimationTypeFlat NS_SWIFT_NAME(flat),     // 默认动画类型，自定义平面动画（不定动画环）
    WZProgressHUDAnimationTypeNative NS_SWIFT_NAME(native)  // iOS native UIActivityIndicatorView
};

typedef void (^WZProgressHUDShowCompletion)(void);
typedef void (^WZProgressHUDDismissCompletion)(void);


/// MARK - WZProgressHUD
@interface WZProgressHUD : UIView

#pragma mark - 定制

@property (assign, nonatomic) WZProgressHUDStyle defaultStyle UI_APPEARANCE_SELECTOR;                   // 默认WZProgressHUDStyleLight
@property (assign, nonatomic) WZProgressHUDMaskType defaultMaskType UI_APPEARANCE_SELECTOR;             // 默认WZProgressHUDMaskTypeNone
@property (assign, nonatomic) WZProgressHUDAnimationType defaultAnimationType UI_APPEARANCE_SELECTOR;   //默认WZProgressHUDAnimationTypeNative
@property (strong, nonatomic, nullable) UIView *containerView;                                  // 容器视图, 如果为空，则使用默认窗口级别
@property (assign, nonatomic) CGSize minimumSize UI_APPEARANCE_SELECTOR;                        //最小大小,默认值是CGSizeZero，可用于避免为较大的消息调整大小
@property (assign, nonatomic) CGSize maxSize UI_APPEARANCE_SELECTOR;// 文本最大size(默认(200,300))
@property (assign, nonatomic) CGFloat ringThickness UI_APPEARANCE_SELECTOR;                     // 环厚度(2 pt)
@property (assign, nonatomic) CGFloat ringRadius UI_APPEARANCE_SELECTOR;                        // 环半径(18 pt)
@property (assign, nonatomic) CGFloat ringNoTextRadius UI_APPEARANCE_SELECTOR;                  // 环形无文本半径(24 pt)
@property (assign, nonatomic) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;                      // 角半径(14 pt)
@property (strong, nonatomic, nonnull) UIFont *font UI_APPEARANCE_SELECTOR;                     // 字体([UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline])
@property (strong, nonatomic, nonnull) UIColor *backgroundColor UI_APPEARANCE_SELECTOR;         // 背景颜色(默认[UIColor whiteColor])
@property (strong, nonatomic, nonnull) UIColor *foregroundColor UI_APPEARANCE_SELECTOR;         // 前景颜色(默认[UIColor blackColor])
@property (strong, nonatomic, nullable) UIColor *foregroundImageColor UI_APPEARANCE_SELECTOR;   // 前景图像颜色(默认foregroundColor)
@property (strong, nonatomic, nonnull) UIColor *backgroundLayerColor UI_APPEARANCE_SELECTOR;    // 背景图层颜色(默认[UIColor colorWithWhite:0 alpha:0.4])
@property (assign, nonatomic) CGSize imageViewSize UI_APPEARANCE_SELECTOR;                      // 图片视图大小(默认36*36)
@property (assign, nonatomic) BOOL shouldTintImages UI_APPEARANCE_SELECTOR;                     // 是否启用TintColor来改变图片颜色(默认Yes)
@property (strong, nonatomic, nonnull) UIImage *infoImage UI_APPEARANCE_SELECTOR;               // 警告图片
@property (strong, nonatomic, nonnull) UIImage *successImage UI_APPEARANCE_SELECTOR;            // 成功图片
@property (strong, nonatomic, nonnull) UIImage *errorImage UI_APPEARANCE_SELECTOR;              // 错误图片
@property (strong, nonatomic, nonnull) UIView *viewForExtension UI_APPEARANCE_SELECTOR;         // 目前还不清楚
@property (assign, nonatomic) NSTimeInterval graceTimeInterval;                                 // 时间间隔(默认0秒)
@property (assign, nonatomic) NSTimeInterval minimumDismissTimeInterval;                        // 最小消失时间(默认5秒)
@property (assign, nonatomic) NSTimeInterval maximumDismissTimeInterval;                        // 最大消失时间间隔(默认CGFLOAT_MAX)
@property (assign, nonatomic) UIOffset offsetFromCenter UI_APPEARANCE_SELECTOR; // 据剧中偏移量(默认0)
@property (assign, nonatomic) NSTimeInterval fadeInAnimationDuration UI_APPEARANCE_SELECTOR;    // 淡入动画持续时间(默认0.15)
@property (assign, nonatomic) NSTimeInterval fadeOutAnimationDuration UI_APPEARANCE_SELECTOR;   // 淡出动画持续时间(默认0.15)
@property (assign, nonatomic) UIWindowLevel maxSupportedWindowLevel; // 最大支持窗口级别(默认UIWindowLevelNormal)
@property (assign, nonatomic) BOOL hapticsEnabled;      // 触觉启用(默认为false)
@property (assign, nonatomic) BOOL motionEffectEnabled; // 运动效果启用(默认为YES)

+ (void)setDefaultStyle:(WZProgressHUDStyle)style;                      // 默认WZProgressHUDStyleLight
+ (void)setDefaultMaskType:(WZProgressHUDMaskType)maskType;             // 默认WZProgressHUDMaskTypeNone
+ (void)setDefaultAnimationType:(WZProgressHUDAnimationType)type;       // 默认WZProgressHUDAnimationTypeNative
+ (void)setContainerView:(nullable UIView*)containerView;               // 容器视图, 如果为空，则使用默认窗口级别
+ (void)setMinimumSize:(CGSize)minimumSize;                             // 最小大小,默认值是CGSizeZero，可用于避免为较大的消息调整大小
+ (void)setMaxSize:(CGSize)maxSize;                                     // 最大大小,默认(200,300)
+ (void)setRingThickness:(CGFloat)ringThickness;                        // 环厚度(2 pt)
+ (void)setRingRadius:(CGFloat)radius;                                  // 环半径(18 pt)
+ (void)setRingNoTextRadius:(CGFloat)radius;                            // 环形无文本半径(24 pt)
+ (void)setCornerRadius:(CGFloat)cornerRadius;                          // 角半径(14 pt)
+ (void)setBorderColor:(nonnull UIColor*)color;                         // 设置边框颜色(默认为nil)
+ (void)setBorderWidth:(CGFloat)width;                                  // 设置边框宽度(默认为0)
+ (void)setFont:(nonnull UIFont*)font;                                  // 字体([UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline])
+ (void)setForegroundColor:(nonnull UIColor*)color;                     // 前景颜色(默认[UIColor blackColor])
+ (void)setForegroundImageColor:(nullable UIColor*)color;               // 默认值为nil==foregroundColor，仅用于WZProgressHUDStyleCustom
+ (void)setBackgroundColor:(nonnull UIColor*)color;                     // 默认为[UIColor whiteColor], 仅用于WZProgressHUDStyleCustom
+ (void)setHudViewCustomBlurEffect:(nullable UIBlurEffect*)blurEffect;  // 默认为nil, 仅用于WZProgressHUDStyleCustom, 可与背景色结合使用
+ (void)setBackgroundLayerColor:(nonnull UIColor*)color;                // 默认为[UIColor colorWithWhite:0 alpha:0.5], 仅用于 WZProgressHUDMaskTypeCustom
+ (void)setImageViewSize:(CGSize)size;                                  // 图片视图大小(默认36*36)
+ (void)setShouldTintImages:(BOOL)shouldTintImages;                     // 是否启用TintColor来改变图片颜色(默认Yes)
+ (void)setInfoImage:(nonnull UIImage*)image;                           // 警告图片
+ (void)setSuccessImage:(nonnull UIImage*)image;                        // 成功图片
+ (void)setErrorImage:(nonnull UIImage*)image;                          // 错误图片
+ (void)setViewForExtension:(nonnull UIView*)view;                      // 目前还不清楚
+ (void)setGraceTimeInterval:(NSTimeInterval)interval;                  // 时间间隔(默认0秒)
+ (void)setMinimumDismissTimeInterval:(NSTimeInterval)interval;         // 最小消失时间(默认5秒)
+ (void)setMaximumDismissTimeInterval:(NSTimeInterval)interval;         // 最大消失时间间隔(默认CGFLOAT_MAX)
+ (void)setFadeInAnimationDuration:(NSTimeInterval)duration;            // 淡入动画持续时间(默认0.15)
+ (void)setFadeOutAnimationDuration:(NSTimeInterval)duration;           // 淡出动画持续时间(默认0.15)
+ (void)setMaxSupportedWindowLevel:(UIWindowLevel)windowLevel;          // 最大支持窗口级别(默认UIWindowLevelNormal)
+ (void)setHapticsEnabled:(BOOL)hapticsEnabled;                         // 触觉启用(默认为false)
+ (void)setMotionEffectEnabled:(BOOL)motionEffectEnabled;               // 运动效果启用(默认为YES)


#pragma mark - 显示方法

+ (void)show;
+ (void)showWithStatus:(nullable NSString*)status;

+ (void)showProgress:(float)progress;
+ (void)showProgress:(float)progress status:(nullable NSString*)status;

+ (void)setStatus:(nullable NSString*)status; // 显示时更改抬头显示器加载状态

// 停止活动指示器，显示警告，成功，错误等状态，稍后关闭HUD
+ (void)showInfoWithStatus:(nullable NSString*)status;
+ (void)showSuccessWithStatus:(nullable NSString*)status;
+ (void)showErrorWithStatus:(nullable NSString*)status;
+ (void)showTextWithStatus:(nullable NSString *)status;

// 显示图像+状态，将白色PNG与imageViewSize一起使用（默认为28x28 pt）
+ (void)showImage:(nonnull UIImage*)image status:(nullable NSString*)status;

// 设置偏移量
+ (void)setOffsetFromCenter:(UIOffset)offset;
// 重置偏移
+ (void)resetOffsetFromCenter;

// 减少活动计数，如果活动计数=0，则取消HUD
+ (void)popActivity;

// 隐藏
+ (void)dismiss;

// 隐藏完成回调
+ (void)dismissWithCompletion:(nullable WZProgressHUDDismissCompletion)completion;

// 延迟隐藏
+ (void)dismissWithDelay:(NSTimeInterval)delay;

// 延迟隐藏完成回调
+ (void)dismissWithDelay:(NSTimeInterval)delay completion:(nullable WZProgressHUDDismissCompletion)completion;

// 是否可见
+ (BOOL)isVisible;

// 显示字符串的持续时间(计算出字符串的时间)
+ (NSTimeInterval)displayDurationForString:(nullable NSString*)string;

@end

