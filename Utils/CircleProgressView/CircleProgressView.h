//
//  CardProgressView.h
//  Grwth
//
//  Created by meego on 15-6-3.
//  Copyright (c) 2015年 xtownmobile.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CircleProgressView : UIControl
{
    UILabel *_progressLabel;
    UILabel *_percentLabel;
}
@property (nonatomic, assign) CGFloat thickness;
@property (nonatomic, strong) UIColor *completedColor;
@property (nonatomic, strong) UIColor *incompletedColor;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong) UIFont  *progressFont;

@end
