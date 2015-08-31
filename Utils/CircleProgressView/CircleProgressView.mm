//
//  CardProgressView.m
//  Grwth
//
//  Created by meego on 15-6-3.
//  Copyright (c) 2015年 xtownmobile.com. All rights reserved.
//
#define DegreeToRadian(radian)            ((radian)*(M_PI/180.0))
#import "CircleProgressView.h"

@implementation CircleProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        _thickness = 3.5;
        _completedColor = [UIColor redColor];
        _incompletedColor = [UIColor grayColor];
    }
    return self;
}

- (void)setThickness:(CGFloat)thickness
{
    _thickness = thickness;
    [self setNeedsDisplay];
}

- (void)setCompletedColor:(UIColor *)completedColor
{
    _completedColor = completedColor;
    [self setNeedsDisplay];
}

- (void)setIncompletedColor:(UIColor *)incompletedColor
{
    _incompletedColor = incompletedColor;
    [self setNeedsDisplay];
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGSize viewSize = self.bounds.size;
    CGPoint center = CGPointMake(viewSize.width / 2, viewSize.height / 2);
    
    double radius = MIN(viewSize.width, viewSize.height) / 2 - self.thickness;
    
    CGContextSetLineWidth(ctx, self.thickness);
    CGContextSetStrokeColorWithColor(ctx,  self.incompletedColor.CGColor);
    CGContextAddArc(ctx, center.x, center.y, radius, 0, DegreeToRadian(360), 0);
    CGContextDrawPath(ctx, kCGPathStroke);
    
    CGContextSetStrokeColorWithColor(ctx,  self.completedColor.CGColor);
    CGContextAddArc(ctx, center.x, center.y, radius, DegreeToRadian(- 90), DegreeToRadian(360 * self.progress - 90) , 0);
    CGContextDrawPath(ctx, kCGPathStroke);
}
@end
