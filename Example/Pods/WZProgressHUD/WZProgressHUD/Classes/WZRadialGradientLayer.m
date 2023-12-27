//
//  WZRadialGradientLayer.m
//  WZProgressHUD_Example
//
//  Created by xiaobin liu on 2019/11/7.
//  Copyright © 2019 LiuSky. All rights reserved.
//

#import "WZRadialGradientLayer.h"

@implementation WZRadialGradientLayer

- (void)drawInContext:(CGContextRef)context {
    
    size_t locationsCount = 2;
    CGFloat locations[2] = {0.0f, 1.0f};
    CGFloat colors[8] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.75f};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
    CGColorSpaceRelease(colorSpace);

    float radius = MIN(self.bounds.size.width , self.bounds.size.height);
    CGContextDrawRadialGradient (context, gradient, self.gradientCenter, 0, self.gradientCenter, radius, kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(gradient);
}

@end
