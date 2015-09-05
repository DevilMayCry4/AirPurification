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
        _thickness = 7.0;
        _completedColor = [UIColor colorWithRed:0.141  green:0.933  blue:0.455 alpha:1];
        _incompletedColor = [UIColor colorWithRed:0.471  green:0.549  blue:0.580 alpha:1];

        _progressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _progressLabel.font = [UIFont systemFontOfSize:34];
        _progressLabel.textColor = [UIColor whiteColor];
        [self addSubview:_progressLabel];
        
        _percentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _percentLabel.font = [UIFont systemFontOfSize:14];
        _percentLabel.textColor = [UIColor whiteColor];
        _percentLabel.text = @"%";
        [self addSubview:_percentLabel];
        [_percentLabel sizeToFit];
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

- (void)setProgressFont:(UIFont *)progressFont
{
    _progressFont = progressFont;
    _progressLabel.font = progressFont;
    self.progress = _progress;
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    NSString *progressString = [NSString stringWithFormat:@"%d",(int)(progress*100)];
    _progressLabel.text = progressString;
    [_progressLabel  sizeToFit];
    CGRect frame = _progressLabel.frame;
    frame.origin.x = (CGRectGetWidth(self.frame) - CGRectGetWidth(frame) - CGRectGetWidth(_percentLabel.frame))/2;
    frame.origin.y = (CGRectGetHeight(self.frame) - CGRectGetHeight(frame))/2;
    _progressLabel.frame = frame;
    
    frame = _percentLabel.frame;
    frame.origin.x = CGRectGetMaxX(_progressLabel.frame);
    frame.origin.y = CGRectGetMinY(_progressLabel.frame) + 4;
    _percentLabel.frame = frame;
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGSize viewSize = self.bounds.size;
    CGPoint center = CGPointMake(viewSize.width / 2, viewSize.height / 2);
    
    double radius = MIN(viewSize.width, viewSize.height) / 2 - self.thickness;
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineWidth(ctx, self.thickness);
    CGContextSetStrokeColorWithColor(ctx,  self.incompletedColor.CGColor);
    CGContextAddArc(ctx, center.x, center.y, radius, 0, DegreeToRadian(360), 0);
    CGContextDrawPath(ctx, kCGPathStroke);
    
    CGContextSetStrokeColorWithColor(ctx,  self.completedColor.CGColor);
    CGContextAddArc(ctx, center.x, center.y, radius, DegreeToRadian(0), DegreeToRadian(360 * self.progress ) , 0);
    CGContextDrawPath(ctx, kCGPathStroke);
}
@end
