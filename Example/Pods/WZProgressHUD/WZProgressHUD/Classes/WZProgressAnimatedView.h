//
//  WZProgressAnimatedView.h
//  WZProgressHUD_Example
//
//  Created by xiaobin liu on 2019/11/7.
//  Copyright © 2019 LiuSky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


/// MARK - 进度动画视图
@interface WZProgressAnimatedView : UIView

@property (nonatomic, assign) CGFloat radius; //半径
@property (nonatomic, assign) CGFloat strokeThickness;//条纹的厚度
@property (nonatomic, strong) UIColor *strokeColor;//条纹颜色
@property (nonatomic, assign) CGFloat strokeEnd;//行程结束
@end

NS_ASSUME_NONNULL_END
