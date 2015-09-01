//
//  AirPurificationController.m
//  AirPurification
//
//  Created by virgil on 15/8/31.
//  Copyright (c) 2015年 xpg. All rights reserved.
//

#import "AirPurificationController.h"
#import "IoTShutdownStatus.h"
#import "IoTTimingSelection.h"
#import "IoTRecord.h"
#import "IoTAdvancedFeatures.h"
#import "IoTAlertView.h"
#import "IoTMainMenu.h"
#import "UICircularSlider.h"
#import "IoTAdvancedFeatures.h"
#import "BJManegerHttpData.h"
#import "PredictScrollView.h"
#import "CircleProgressView.h"
#import <CoreLocation/CoreLocation.h>

#define ALERT_TAG_SHUTDOWN          1

@interface AirPurificationController ()
{
    //提示框
    IoTAlertView *_alertView;
    
    //数据点的临时变量
    BOOL bSwitch;
    BOOL bSwitch_Plasma;
    BOOL bLED_Air_Quality;
    BOOL bChild_Security_Lock;
    NSInteger iOnTiming;
    NSInteger iOffTiming;
    NSInteger iWindVelocity;
    NSInteger iAir_Sensitivity;
    NSInteger iFilter_Life;
    NSInteger iAir_Quality;
    
    //临时数据
    NSArray *modeImages, *modeTexts;
    
    //时间选择
    IoTTimingSelection *_timingSelection;
    
    UILabel        *_statusLabel;
    UILabel        *_pmLabel;
    UILabel        *_cityLabel;
    UILabel        *_temperatureLabel;
    UILabel        *_moistureLabel;
    UIImageView    *_pm25ImageView;
    UIImageView    *_pm10ImageView;
    CircleProgressView *_filterProgress;
}


@property (weak, nonatomic  ) IBOutlet UIView                    *globalView;

//室内空气质量情况
@property (weak, nonatomic  ) IBOutlet UIImageView               *imageStatus;
@property (weak, nonatomic  ) IBOutlet UIImageView               *imageStatusColor;

//模式
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnSleep;
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnStandard;
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnStrong;
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnAuto;

@property (weak, nonatomic  ) IBOutlet UISlider                  *Slider;

//定时关机
@property (weak, nonatomic  ) IBOutlet UILabel                   *textShutdown;
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnShutdown;

@property (weak, nonatomic  ) IBOutlet UIButton                  *btnSwitchPlasma;
@property (weak, nonatomic  ) IBOutlet UILabel                   *textSwitchPlasma;
@property (weak, nonatomic  ) IBOutlet UIImageView               *imageSwitchPlasma;
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnChildSecurityLock;
@property (weak, nonatomic  ) IBOutlet UILabel                   *textChildSecurityLock;
@property (weak, nonatomic  ) IBOutlet UIImageView               *imageChildSecurityLock;
@property (weak, nonatomic  ) IBOutlet UIButton                  *btnLEDAirQuality;
@property (weak, nonatomic  ) IBOutlet UILabel                   *textLEDAirQuality;
@property (weak, nonatomic  ) IBOutlet UIImageView               *imageLEDAirQuality;

@property (weak, nonatomic  ) IBOutlet UILabel                   *airQualityLabel;
@property (weak, nonatomic  ) IBOutlet UILabel                   *pm25Label;
@property (weak, nonatomic  ) IBOutlet UILabel                   *pm10Label;

@property (nonatomic, strong) IoTShutdownStatus         * shutdownStatusCtrl;

//定位
@property (nonatomic, strong) CLLocationManager         *manager;
@property (nonatomic, strong) UILabel                   * locationLabel;

@property (nonatomic, strong) NSArray                   * alerts;
@property (nonatomic, strong) NSArray                   * faults;
@property (strong, nonatomic) SlideNavigationController *navCtrl;

@end

@implementation AirPurificationController

- (instancetype)initWithDevice:(XPGWifiDevice *)device
{
    self = [super init];
    if(self)
    {
        if(nil == device)
        {
            NSLog(@"warning: device can't be null.");
            return nil;
        }
        self.device = device;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_menu"] style:UIBarButtonItemStylePlain target:[SlideNavigationController sharedInstance] action:@selector(toggleLeftMenu)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_start"] style:UIBarButtonItemStylePlain target:self action:@selector(onPower)];
    
    [self.Slider setThumbImage:[UIImage imageNamed:@"stripe_poin.png"] forState:(UIControlStateNormal)];
    [self.Slider setMinimumTrackImage:[UIImage imageNamed:@"stripe_min.png"] forState:(UIControlStateNormal)];
    [self.Slider setMaximumTrackImage:[UIImage imageNamed:@"stripe_min.png"] forState:(UIControlStateNormal)];
    self.Slider.userInteractionEnabled = NO;
    self.airSensitivity = 0;

    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat const bottomViewHeight = 58;
    CGRect frame = self.view.bounds;
    frame.size.height -= (bottomViewHeight+64);
    PageControlScrollView *scrollView = [[PageControlScrollView alloc] initWithFrame:frame];
    scrollView.delegate2 = self;
    [self.view addSubview:scrollView];
    scrollView.numberOfPages = 3;
    scrollView.currentPage = 1;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.backgroundColor = [UIColor lightGrayColor];
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(frame), CGRectGetWidth(frame), bottomViewHeight)];
    bottomView.backgroundColor = [UIColor colorWithRed:0.361  green:0.682  blue:0.910 alpha:1];
    [self.view addSubview:bottomView];
    
    CGFloat const buttonWidth = CGRectGetWidth(frame)/2;
    
    UIButton *storeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonWidth, bottomViewHeight)];
    [storeButton addTarget:self action:@selector(onStoreButtonPress) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:storeButton];
    UIButton *shareButton = [[UIButton alloc] initWithFrame:CGRectMake(buttonWidth, 0, buttonWidth, bottomViewHeight)];
    [shareButton addTarget:self action:@selector(onShareButtonPress) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:shareButton];
    
}

- (void)onStoreButtonPress
{}

- (void)onShareButtonPress
{}

static CGFloat const kContentHeigt = 336.0;
static CGFloat const kContentMargin = 15.0;
#pragma mark --- PredictScrollViewDelegate
- (UIView *)scrollView:(PredictScrollView *)scrollView viewForPage:(NSUInteger)index inFrame:(CGRect)frame
{
    UIView *view = [[UIView alloc] initWithFrame:frame];
    switch (index)
    {
        case  0:
        {
            
        }
            break;
            
        case 1:
        {
            view = [[UIView alloc] initWithFrame:frame];
            CGFloat kContentWidth = CGRectGetWidth(frame)-2*kContentMargin;
            UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kContentWidth, kContentHeigt)];
            [view addSubview:contentView];
            contentView.backgroundColor = [UIColor grayColor];
            contentView.center = CGPointMake(CGRectGetWidth(frame)/2, CGRectGetHeight(frame)/2);
            
            CGFloat const kStatusWidth = 172.0;
            CGFloat const kStatusHeight = 25.0;
            _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake((kContentWidth - kStatusWidth)/2, 0, kStatusWidth, kStatusHeight)];
            _statusLabel.textAlignment = NSTextAlignmentCenter;
            _statusLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4];
            _statusLabel.layer.cornerRadius = kStatusHeight/2;
            _statusLabel.clipsToBounds = YES;
            [contentView addSubview:_statusLabel];
            
            CGFloat const kPMImageWidth = 20.0;
            CGFloat const kPMImageY = 40.0 + CGRectGetMaxY(_statusLabel.frame);
            _pm25ImageView = [[UIImageView alloc] initWithFrame:CGRectMake((kContentWidth - kPMImageWidth)/2, kPMImageY, kPMImageWidth, kPMImageWidth)];
            _pm25ImageView.backgroundColor = [UIColor redColor];
            [contentView addSubview:_pm25ImageView];
            
            _pm10ImageView = [[UIImageView alloc] initWithFrame:CGRectMake((kContentWidth - kPMImageWidth)/2, CGRectGetMaxY(_pm25ImageView.frame) + 5, kPMImageWidth, kPMImageWidth)];
            _pm10ImageView.backgroundColor = [UIColor blueColor];
            [contentView addSubview:_pm10ImageView];
            
            CGFloat const kPadding = 10;
            _pmLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_statusLabel.frame)+22, CGRectGetMinX(_pm25ImageView.frame) - kPadding, 90)];
            _pmLabel.textAlignment = NSTextAlignmentCenter;
            _pmLabel.textColor = [UIColor whiteColor];
            _pmLabel.font = [self lightFont:112];
           
            [contentView addSubview:_pmLabel];
            
            _pmLabel.text = @"72";
            
            UILabel *pm25Label = [[UILabel alloc] initWithFrame:CGRectZero];
            pm25Label.font = [UIFont systemFontOfSize:15];
            pm25Label.textColor = [UIColor whiteColor];
            pm25Label.text = @"PM 2.5";
            [pm25Label sizeToFit];
            CGRect frame = pm25Label.frame;
            frame.origin.x = CGRectGetMaxX(_pm25ImageView.frame) + kPadding;
            frame.origin.y = CGRectGetMinY(_pmLabel.frame) + 4;
            pm25Label.frame = frame;
            [contentView addSubview:pm25Label];
            
            _pm25Label = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame) + 8, CGRectGetWidth(frame), 20)];
            _pm25Label.textColor = [UIColor whiteColor];
            _pm25Label.textAlignment = NSTextAlignmentCenter;
            _pm25Label.adjustsFontSizeToFitWidth = YES;
            [contentView addSubview:_pm25Label];
            
            UILabel *pm10Label = [[UILabel alloc] initWithFrame:CGRectZero];
            pm10Label.font = [UIFont systemFontOfSize:15];
            pm10Label.textColor = [UIColor whiteColor];
            pm10Label.text = @"PM 10";
            [pm10Label sizeToFit];
            frame = pm25Label.frame;
            frame.origin.x = CGRectGetMaxX(_pm25ImageView.frame) + kPadding;
            frame.origin.y = CGRectGetMinY(_pmLabel.frame) + 52;
            pm10Label.frame = frame;
            [contentView addSubview:pm10Label];
            
            _pm10Label = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame) + 8, CGRectGetWidth(frame), 20)];
            _pm10Label.textColor = [UIColor whiteColor];
            _pm10Label.textAlignment = NSTextAlignmentCenter;
            _pm10Label.adjustsFontSizeToFitWidth = YES;
            [contentView addSubview:_pm10Label];
            
            CGFloat const kCityWidth = 123.0;
            _cityLabel = [[UILabel alloc] initWithFrame:CGRectMake((kContentWidth - kCityWidth)/2, CGRectGetMaxY(_statusLabel.frame)+140, kCityWidth, kStatusHeight)];
            _cityLabel.textAlignment = NSTextAlignmentCenter;
            _cityLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4];
            _cityLabel.layer.cornerRadius = kStatusHeight/2;
            _cityLabel.clipsToBounds = YES;
            _cityLabel.font = [UIFont systemFontOfSize:14];
            [contentView addSubview:_cityLabel];
            
            CGFloat const kTemperatureMaring = 10.0;
            UILabel *temperatureLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            temperatureLabel.text = @"温\n度";
            temperatureLabel.numberOfLines = 2;
            [temperatureLabel sizeToFit];
            temperatureLabel.textColor = [UIColor whiteColor];
            frame = temperatureLabel.frame;
            frame.origin.x = kTemperatureMaring;
            frame.origin.y = CGRectGetMaxY(_cityLabel.frame) + 29.0;
            temperatureLabel.frame = frame;
            [contentView addSubview:temperatureLabel];
            
            _temperatureLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(frame) + 20, CGRectGetMinY(frame), 50, CGRectGetHeight(frame))];
            _temperatureLabel.font  = [UIFont systemFontOfSize:CGRectGetHeight(frame)];
            _temperatureLabel.textColor = [UIColor whiteColor];
            _temperatureLabel.textAlignment = NSTextAlignmentRight;
            _temperatureLabel.text = @"60";
            [contentView addSubview:_temperatureLabel];
            
            
            UILabel *moistureLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            moistureLabel.text = @"湿\n度";
            moistureLabel.numberOfLines = 2;
            [moistureLabel sizeToFit];
            moistureLabel.textColor = [UIColor whiteColor];
            frame = moistureLabel.frame;
            frame.origin.x = kTemperatureMaring;
            frame.origin.y = CGRectGetMaxY(temperatureLabel.frame) + 29.0;
            moistureLabel.frame = frame;
            [contentView addSubview:moistureLabel];
            
            _moistureLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(frame) + 20, CGRectGetMinY(frame), 50, CGRectGetHeight(frame))];
            _moistureLabel.font  = [UIFont systemFontOfSize:CGRectGetHeight(frame)];
            _moistureLabel.textColor = [UIColor whiteColor];
            _moistureLabel.textAlignment = NSTextAlignmentRight;
            _moistureLabel.text = @"60";
            [contentView addSubview:_moistureLabel];
            
            UILabel *precentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            precentLabel.text = @"%";
            precentLabel.textColor = [UIColor whiteColor];
            precentLabel.font = [UIFont systemFontOfSize:18];
            [precentLabel sizeToFit];
            frame = precentLabel.frame;
            frame.origin.x = CGRectGetMaxX(_moistureLabel.frame);
            frame.origin.y = CGRectGetMinY(_moistureLabel.frame) - CGRectGetHeight(frame)/2 + 8;
            precentLabel.frame = frame;
            [contentView addSubview:precentLabel];
            
            CGFloat const kLineWidth = 2.0;
            UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake((kContentWidth - kLineWidth)/2, CGRectGetMaxY(_cityLabel.frame) + 20, kLineWidth, 122)];
            lineView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4];
            [contentView addSubview:lineView];
            
            CGFloat width = kContentWidth - CGRectGetMaxX(lineView.frame);
            UILabel *leftLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            leftLabel.font = _cityLabel.font;
            leftLabel.text = @"滤芯剩余量";
            leftLabel.textColor = [UIColor whiteColor];
            [leftLabel sizeToFit];
            frame = leftLabel.frame;
            frame.origin.x = (width - CGRectGetMaxX(frame))/2 + CGRectGetMaxX(lineView.frame);
            frame.origin.y = CGRectGetMinY(temperatureLabel.frame) - 10;
            leftLabel.frame = frame;
            [contentView addSubview:leftLabel];
            
            CGFloat const kCircleWidth = 100;
            _filterProgress = [[CircleProgressView alloc] initWithFrame:CGRectMake((width - kCircleWidth)/2 + CGRectGetMaxX(lineView.frame), CGRectGetMaxY(leftLabel.frame) + 10, kCircleWidth, kCircleWidth)];
            _filterProgress.progress = 0.6;
            _filterProgress.progressFont = _temperatureLabel.font;
            [contentView addSubview:_filterProgress];
            
        }
            break;
            
        default:
            break;
    }
    return view;
}

- (void)scrollView:(PredictScrollView *)scrollView scrollToPage:(NSUInteger)index
{}


- (void)initDevice{
    //加载页面时，清除旧的故障报警记录
    [[IoTRecord sharedInstance] clearAllRecord];
    [self onUpdateAlarm];
    
    bSwitch       = 0;
    iWindVelocity = -1;
    self.onTiming = 0;
    iOffTiming    = 0;
    iOnTiming     = 0;

//    [self selectSwitchPlasma:bSwitch_Plasma sendToDevice:NO];
//    [self selectChildSecurityLock:bChild_Security_Lock sendToDevice:NO];
//    [self selectLEDAirQuality:bLED_Air_Quality sendToDevice:NO];
//    [self selectWindVelocity:iWindVelocity sendToDevice:NO];
    
    self.view.userInteractionEnabled = bSwitch;
    
    //更新关机时间
    [self onUpdateShutdownText];
    
    self.device.delegate = self;
}

- (void)writeDataPoint:(IoTDeviceDataPoint)dataPoint value:(id)value{
    
    NSDictionary *data = nil;
    
    switch (dataPoint)
    {
        case IoTDeviceWriteUpdateData:
            data = @{DATA_CMD: @(IoTDeviceCommandRead)};
            break;
        case IoTDeviceWriteOnOff:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_SWITCH: value}};
            break;
        case IoTDeviceWriteCountDownOnMin:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_COUNTDOWN_ON_MIN: value}};
            break;
        case IoTDeviceWriteCountDownOffMin:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_COUNTDOWN_OFF_MIN: value}};
            break;
        case IoTDeviceWriteChildSecurityLock:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_CHILD_SECURITY_LOCK: value}};
            break;
        case IoTDeviceWriteLEDAirQuality:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_LED_AIR_QUALITY: value}};
            break;
        case IoTDeviceWriteSwitchPlasma:
            data = @{DATA_CMD:@(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_SWITCH_PLASMA: value}};
            break;
        case IoTDeviceWriteWindVelocity:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_WIND_VELOCITY: value}};
            break;
        case IoTDeviceWriteQuality:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_AIR_QUALITY: value}};
            break;
        case IoTDeviceWriteAirSensitivity:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_AIR_SENSITIVITY: value}};
            break;
        case IoTDeviceWriteFilterLife:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_FILTER_LIFE: value}};
            NSLog(@"dataPoint = %u",dataPoint);
            break;
            
        default:
            NSLog(@"Error: write invalid datapoint, skip.");
            return;
    }
    NSLog(@"Write data: %@", data);
    [self.device write:data];
}

- (id)readDataPoint:(IoTDeviceDataPoint)dataPoint data:(NSDictionary *)data
{
    if(![data isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Error: could not read data, error data format.");
        return nil;
    }
    
    NSNumber *nCommand = [data valueForKey:DATA_CMD];
    if(![nCommand isKindOfClass:[NSNumber class]])
    {
        NSLog(@"Error: could not read cmd, error cmd format.");
        return nil;
    }
    
    int nCmd = [nCommand intValue];
    if(nCmd != IoTDeviceCommandResponse && nCmd != IoTDeviceCommandNotify)
    {
        NSLog(@"Error: command is invalid, skip.");
        return nil;
    }
    
    NSDictionary *attributes = [data valueForKey:DATA_ENTITY];
    if(![attributes isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Error: could not read attributes, error attributes format.");
        return nil;
    }
    
    switch (dataPoint)
    {
        case IoTDeviceWriteOnOff:
            return [attributes valueForKey:DATA_ATTR_SWITCH];
        case IoTDeviceWriteCountDownOnMin:
            return [attributes valueForKey:DATA_ATTR_COUNTDOWN_ON_MIN];
        case IoTDeviceWriteCountDownOffMin:
            return [attributes valueForKey:DATA_ATTR_COUNTDOWN_OFF_MIN];
        case IoTDeviceWriteSwitchPlasma:
            return [attributes valueForKey:DATA_ATTR_SWITCH_PLASMA];
        case IoTDeviceWriteChildSecurityLock:
            return [attributes valueForKey:DATA_ATTR_CHILD_SECURITY_LOCK];
        case IoTDeviceWriteLEDAirQuality:
            return [attributes valueForKey:DATA_ATTR_LED_AIR_QUALITY];
        case IoTDeviceWriteWindVelocity:
            return [attributes valueForKey:DATA_ATTR_WIND_VELOCITY];
        case IoTDeviceWriteQuality:
            return [attributes valueForKey:DATA_ATTR_AIR_QUALITY];
        case IoTDeviceWriteAirSensitivity:
            return [attributes valueForKey:DATA_ATTR_AIR_SENSITIVITY];
        case IoTDeviceWriteFilterLife:
            return [attributes valueForKey:DATA_ATTR_FILTER_LIFE];
            
        default:
            NSLog(@"Error: read invalid datapoint, skip.");
            break;
            
    }
    return nil;
}

//数据入口
- (BOOL)XPGWifiDevice:(XPGWifiDevice *)device didReceiveData:(NSDictionary *)data result:(int)result{
    
    if(![device.did isEqualToString:self.device.did])
        return YES;
    
    [IoTAppDelegate.hud hide:YES];
    //[self.shutdownStatusCtrl hide:YES];
    /**
     * 数据部分
     */
    NSDictionary *_data = [data valueForKey:@"data"];
    if(nil != _data)
    {
        NSString *onOff             = [self readDataPoint:IoTDeviceWriteOnOff data:_data];
        NSString *switchPlasma      = [self readDataPoint:(IoTDeviceWriteSwitchPlasma) data:_data];
        NSString *LEDairQuality     = [self readDataPoint:(IoTDeviceWriteLEDAirQuality) data:_data];
        NSString *countDownOnMin    = [self readDataPoint:(IoTDeviceWriteCountDownOnMin) data:_data];
        NSString *countDownOffMin   = [self readDataPoint:(IoTDeviceWriteCountDownOffMin) data:_data];
        NSString *windVelocity      = [self readDataPoint:(IoTDeviceWriteWindVelocity) data:_data];
        NSString *childSecurityLock = [self readDataPoint:IoTDeviceWriteChildSecurityLock data:_data];
        NSString *airQuality        = [self readDataPoint:IoTDeviceWriteQuality data:_data];
        NSString *airSensitivity    = [self readDataPoint:IoTDeviceWriteAirSensitivity data:_data];
        NSString *filterLife        = [self readDataPoint:IoTDeviceWriteFilterLife data:_data];
        
        bSwitch                     = [self prepareForUpdateFloat:onOff value:bSwitch];
        iOnTiming                   = [self prepareForUpdateFloat:countDownOnMin value:iOnTiming];
        iOffTiming                  = [self prepareForUpdateFloat:countDownOffMin value:iOffTiming];
        bSwitch_Plasma              = [self prepareForUpdateFloat:switchPlasma value:bSwitch_Plasma];
        bLED_Air_Quality            = [self prepareForUpdateFloat:LEDairQuality value:bLED_Air_Quality];
        bChild_Security_Lock        = [self prepareForUpdateFloat:childSecurityLock value:bChild_Security_Lock];
        iWindVelocity               = [self prepareForUpdateFloat:windVelocity value:iWindVelocity];
        iAir_Quality                = [self prepareForUpdateFloat:airQuality value:iAir_Quality];
        iAir_Sensitivity            = [self prepareForUpdateFloat:airSensitivity value:iAir_Sensitivity];
        iFilter_Life                = [self prepareForUpdateFloat:filterLife value:iFilter_Life];
        
        self.airSensitivity         = iAir_Sensitivity;
        self.filterLife             = iFilter_Life;
        
        /**
         * 更新到 UI
         */
        [self selectSwitchPlasma:bSwitch_Plasma sendToDevice:NO];
        [self selectChildSecurityLock:bChild_Security_Lock sendToDevice:NO];
        [self selectLEDAirQuality:bLED_Air_Quality sendToDevice:NO];
        [self selectWindVelocity:iWindVelocity sendToDevice:NO];
        [self selectAirQuality:iAir_Quality];
        
        self.view.userInteractionEnabled = bSwitch;
        
        //更新关机时间
        [self onUpdateShutdownText];
        
        //没有开机，切换页面
        if(!bSwitch)
        {
            [self onPower];
            return YES;
        }
    }
    
    
    /**
     * 报警和错误
     */
    if([self.navigationController.viewControllers lastObject] != self)
        return YES;
    
    self.alerts = [data valueForKey:@"alerts"];
    self.faults = [data valueForKey:@"faults"];
    
    /**
     * 清理旧报警及故障
     */
    [[IoTRecord sharedInstance] clearAllRecord];
    
    if(self.alerts.count == 0 && self.faults.count == 0)
    {
        [self onUpdateAlarm];
        return YES;
    }
    
    /**
     * 添加当前故障
     */
    NSDate *date = [NSDate date];
    if(self.alerts.count > 0)
    {
        for(NSDictionary *dict in self.alerts)
        {
            for(NSString *name in dict.allKeys)
            {
                [[IoTRecord sharedInstance] addRecord:date information:name];
            }
        }
    }
    
    if(self.faults.count > 0)
    {
        for(NSDictionary *dict in self.faults)
        {
            for(NSString *name in dict.allKeys)
            {
                [[IoTRecord sharedInstance] addRecord:date information:name];
            }
        }
    }
    
    [self onUpdateAlarm];
    
    return YES;
}

- (CGFloat)prepareForUpdateFloat:(NSString *)str value:(CGFloat)value
{
    if([str isKindOfClass:[NSNumber class]] ||
       ([str isKindOfClass:[NSString class]] && str.length > 0))
    {
        CGFloat newValue = [str floatValue];
        if(newValue != value)
        {
            value = newValue;
        }
    }
    return value;
}

- (NSInteger)prepareForUpdateInteger:(NSString *)str value:(NSInteger)value
{
    if([str isKindOfClass:[NSNumber class]] ||
       ([str isKindOfClass:[NSString class]] && str.length > 0))
    {
        NSInteger newValue = [str integerValue];
        if(newValue != value)
        {
            value = newValue;
        }
    }
    return value;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initDevice];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //设备已解除绑定，或者断开连接，退出
    if(![self.device isBind:[IoTProcessModel sharedModel].currentUid] || !self.device.isConnected)
    {
        [self onDisconnected];
        return;
    }
    
    //更新侧边菜单数据
    [((IoTMainMenu *)[SlideNavigationController sharedInstance].leftMenu).tableView reloadData];
    
    //在页面加载后，自动更新数据
    if(self.device.isOnline)
    {
        IoTAppDelegate.hud.labelText = @"正在更新数据...";
        [IoTAppDelegate.hud showAnimated:YES whileExecutingBlock:^{
            sleep(61);
        }];
        [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
    }
    
    self.view.userInteractionEnabled = bSwitch;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if([self.navigationController.viewControllers indexOfObject:self] > self.navigationController.viewControllers.count)
        self.device.delegate = nil;
    
    //防止 delegate 出错，退出之前先关掉弹出框
    [_alertView hide:YES];
    [_timingSelection hide:YES];
    [_shutdownStatusCtrl hide:YES];
}

#pragma mark - Properties
- (NSInteger)onTiming
{
    return iOnTiming;
}

- (void)setOnTiming:(NSInteger)onTiming
{
    iOnTiming  = onTiming;
}

- (void)setDevice:(XPGWifiDevice *)device
{
    _device.delegate = nil;
    _device = device;
    [self initDevice];
}

#pragma mark - XPGWifiDeviceDelegate
- (void)XPGWifiDeviceDidDisconnected:(XPGWifiDevice *)device
{
    if(![device.did isEqualToString:self.device.did])
        return;
    
    [self onDisconnected];
}

- (void)onPower {
    //不在线就不能点
    if(!self.device.isOnline)
        return;
    
    if(bSwitch)
    {
        //关机
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"是否确定关机？" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        alertView.tag = ALERT_TAG_SHUTDOWN;
        [alertView show];
    }
    else
    {
        //开机
        self.shutdownStatusCtrl = [[IoTShutdownStatus alloc]init];
        self.shutdownStatusCtrl.mainCtrl = self;
        [self.shutdownStatusCtrl show:YES];
    }
}

#pragma mark - Actions
- (void)onDisconnected {
    //断线且页面在控制页面时才弹框
    UIViewController *currentController = self.navigationController.viewControllers.lastObject;
    
    if(!self.device.isConnected &&
       ([currentController isKindOfClass:[AirPurificationController class]] ||
        [currentController isKindOfClass:[IoTShutdownStatus class]]))
    {
        [IoTAppDelegate.hud hide:YES];
        [_alertView hide:YES];
        [self.shutdownStatusCtrl hide:YES];
        [[[IoTAlertView alloc] initWithMessage:@"连接已断开" delegate:nil titleOK:@"确定"] show:YES];
        
    }
    
    //退出到列表
    for(int i=(int)(self.navigationController.viewControllers.count-1); i>0; i--)
    {
        UIViewController *controller = self.navigationController.viewControllers[i];
        if([controller isKindOfClass:[IoTDeviceList class]])
        {
            [self.navigationController popToViewController:controller animated:YES];
        }
    }
}

//title按钮
- (void)onUpdateAlarm {
    //自定义标题
    CGRect rc = CGRectMake(0, 0, 200, 64);
    
    UILabel *label = [[UILabel alloc] initWithFrame:rc];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"空气净化器";
    label.font = [UIFont boldSystemFontOfSize:label.font.pointSize];
    
    UIButton *view = [UIButton buttonWithType:UIButtonTypeCustom];
    [view addTarget:self action:@selector(onAlarmList) forControlEvents:UIControlEventTouchUpInside];
    view.frame = rc;
    [view addSubview:label];
    
    //故障条目数，原则上不大于65535
    NSInteger count = [IoTRecord sharedInstance].recordedCount;
    if(count > 65535)
        count = 65535;
    //故障条数目的气泡写法
    if(count > 0)
    {
        double n = log10(count);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(145, 23, 22+n*8, 18)];
        imageView.image = [[UIImage imageNamed:@"fault_tips.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:0];
        [view addSubview:imageView];
        
        UILabel *labelBadge = [[UILabel alloc] initWithFrame:imageView.bounds];
        labelBadge.textColor = [UIColor colorWithRed:0.1484375 green:0.49609375 blue:0.90234375 alpha:1.00];
        labelBadge.textAlignment = NSTextAlignmentCenter;
        labelBadge.text = [NSString stringWithFormat:@"%@", @(count)];
        [imageView addSubview:labelBadge];
        
        //弹出报警提示
        [_alertView hide:YES];
        _alertView = [[IoTAlertView alloc] initWithMessage:@"设备故障" delegate:self titleOK:@"暂不处理" titleCancel:@"拨打客服"];
        [_alertView show:YES];
    }
    
    self.navigationItem.titleView = view;
}

//跳入警报详细页面
- (void)onAlarmList {
    if(self.alerts.count == 0 && self.faults.count == 0)
    {
        NSLog(@"没有报警");
    }else{
        IoTAdvancedFeatures *faultList = [[IoTAdvancedFeatures alloc] init];
        [self.navigationController pushViewController:faultList animated:YES];
    }
}

//============风速===========
- (IBAction)onStrong:(id)sender
{
    if(iWindVelocity != 0)
        [self selectWindVelocity:0 sendToDevice:YES];
    [self getFanTextColor:YES];
}
- (IBAction)onSleep:(id)sender
{
    if(iWindVelocity != 2)
        [self selectWindVelocity:2 sendToDevice:YES];
    
}
- (IBAction)onStandard:(id)sender
{
    if(iWindVelocity != 1)
        [self selectWindVelocity:1 sendToDevice:YES];
    [self getFanTextColor:YES];
}

- (IBAction)onAuto:(id)sender
{
    if(iWindVelocity != 3)
        [self selectWindVelocity:3 sendToDevice:YES];
    [self getFanTextColor:YES];
}

#pragma mark - Group Selection
- (UIColor *)getFanTextColor:(BOOL)bSelected
{
    if(bSelected)
        return [UIColor blueColor];
    return [UIColor grayColor];
}

//设置风速
- (void)selectWindVelocity:(NSInteger)index sendToDevice:(BOOL)send
{
    if(nil == self.btnSleep)
        return;
    
    NSArray *btnItems = @[self.btnStrong, self.btnStandard, self.btnSleep, self.btnAuto];
    
    //风速：睡眠，标准，强力，自动，就只能选择其中的一种
    if(index >= -1 && index <= 3)
    {
        iWindVelocity = index;
        for(int i=0; i<(btnItems.count); i++)
        {
            BOOL bSelected = (index == i);
            ((UIButton *)btnItems[i]).selected = bSelected;
        }
        
        //发送数据
        if(send && index != -1)
            [self writeDataPoint:IoTDeviceWriteWindVelocity value:@(iWindVelocity)];
    }
}

- (void)selectAirQuality:(NSInteger)index
{
    //空气质量状况：优，良，中，差其中一种
    NSArray *imageString = @[@"good_word",@"liang_word",@"middle_word",@"bad_word"];
    NSArray *imageString2 = @[@"good_bg",@"liang_bg",@"middle_bg",@"bad_bg"];
    self.imageStatus.image = [UIImage imageNamed:imageString[index]];
    self.imageStatusColor.image = [UIImage imageNamed:[imageString2 objectAtIndex:index]];
    
    if (index == 0)
    {
        self.Slider.value = 3;
        [SlideNavigationController sharedInstance].navigationBar.barTintColor =  [UIColor colorWithRed:0.1484375 green:0.49609375 blue:0.90234375 alpha:1.00];//导航颜色
    }
    else if (index == 1)
    {
        self.Slider.value = 2;
        [SlideNavigationController sharedInstance].navigationBar.barTintColor = [UIColor colorWithRed:0.29 green:0.79 blue:0.44 alpha:1];
    }
    else if (index == 2)
    {
        self.Slider.value = 1;
        [SlideNavigationController sharedInstance].navigationBar.barTintColor = [UIColor colorWithRed:0.67 green:0.69 blue:0.10 alpha:1];
    }
    else if (index == 3)
    {
        self.Slider.value = 0;
        [SlideNavigationController sharedInstance].navigationBar.barTintColor = [UIColor colorWithRed:0.85 green:0.58 blue:0.18 alpha:1];
    }
}

//点击向上箭头按钮，设置动画使view上移65
- (IBAction)sender:(id)sender
{
    CGRect frame = self.globalView.frame;
    if(frame.origin.y == 0)
        frame.origin.y = -65;
    else
        frame.origin.y = 0;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationsEnabled:YES];
    self.globalView.frame = frame;
    [UIView commitAnimations];
}

- (IBAction)btnSwitchPlasma:(UIButton *)sender
{
    [self selectSwitchPlasma:!bSwitch_Plasma sendToDevice:YES];
}

- (IBAction)btnChildSecurityLock:(UIButton *)sender
{
    [self selectChildSecurityLock:!bChild_Security_Lock sendToDevice:YES];
}

- (IBAction)btnLEDAirQuality:(UIButton *)sender
{
    [self selectLEDAirQuality:!bLED_Air_Quality sendToDevice:YES];
}

//设置等离子开关
- (void)selectSwitchPlasma:(BOOL)bSelected sendToDevice:(BOOL)send
{
    bSwitch_Plasma = bSelected;
    
    //发送数据
    if(send)
        [self writeDataPoint:IoTDeviceWriteSwitchPlasma value:@(bSelected)];
    
    self.btnSwitchPlasma.selected = bSelected;
    self.textSwitchPlasma.textColor = [self getFanTextColor:bSelected];
    self.imageSwitchPlasma.image = self.btnSwitchPlasma.selected == YES ? [UIImage imageNamed:@"anion_select.png"] : [UIImage imageNamed:@"anion_not_select.png"];
}

//设置童锁
- (void)selectChildSecurityLock:(BOOL)bSelected sendToDevice:(BOOL)send
{
    bChild_Security_Lock = bSelected;
    
    //发送数据
    if(send)
        [self writeDataPoint:IoTDeviceWriteChildSecurityLock value:@(bSelected)];
    
    self.btnChildSecurityLock.selected = bSelected;
    self.textChildSecurityLock.textColor = [self getFanTextColor:bSelected];
    self.imageChildSecurityLock.image = self.btnChildSecurityLock.selected == YES ? [UIImage imageNamed:@"lock_select.png"] : [UIImage imageNamed:@"lock_not_select.png"];
}

//设置LED空气质量指示灯
- (void)selectLEDAirQuality:(BOOL)bSelected sendToDevice:(BOOL)send
{
    bLED_Air_Quality = bSelected;
    
    //发送数据
    if(send)
        [self writeDataPoint:IoTDeviceWriteLEDAirQuality value:@(bSelected)];
    
    self.btnLEDAirQuality.selected = bSelected;
    self.textLEDAirQuality.textColor = [self getFanTextColor:bSelected];
    self.imageLEDAirQuality.image = self.btnLEDAirQuality.selected == YES ? [UIImage imageNamed:@"quality_select.png"] : [UIImage imageNamed:@"quality_not_select.png"];
}

//定时关机
- (IBAction)onTimeShut:(id)sender
{
    [_timingSelection hide:YES];
    _timingSelection = [[IoTTimingSelection alloc] initWithTitle:@"倒计时关机" delegate:self currentValue:iOffTiming==0?24:(iOffTiming/60 -1)];
    [_timingSelection show:YES];
}

- (void)onUpdateShutdownText
{
    self.textShutdown.text = iOffTiming == 0 ? @"倒计时关机" : [NSString stringWithFormat:@"%@小时后关", @(iOffTiming <= 60?1:iOffTiming/60)];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 1 && buttonIndex == 0)
    {
        IoTAppDelegate.hud.labelText = @"正在关机...";
        [IoTAppDelegate.hud showAnimated:YES whileExecutingBlock:^{
            sleep(61);
        }];
        [self writeDataPoint:IoTDeviceWriteOnOff value:@0];
        [self writeDataPoint:IoTDeviceWriteCountDownOffMin value:@0];
        [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
    }
}

- (void)IoTTimingSelectionDidConfirm:(IoTTimingSelection *)selection withValue:(NSInteger)value
{
    if(value == 24)
        iOffTiming = 0;
    else
        iOffTiming = (value+1) * 60 ;
    [self writeDataPoint:IoTDeviceWriteCountDownOffMin value:@(iOffTiming)];
    [self onUpdateShutdownText];
}

- (void)IoTAlertViewDidDismissButton:(IoTAlertView *)alertView withButton:(BOOL)isConfirm
{
    //拨打客服
    if(!isConfirm)
        [IoTAppDelegate callServices];
}

//获取当前经纬度
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    
    NSLog(@"***GPS***>>>%f-----%f",newLocation.coordinate.latitude,newLocation.coordinate.longitude);
    
    //通过经纬度获取城市名
    [BJManegerHttpData requestCityByCLLoacation:newLocation complation:^(id obj) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.locationLabel.text = (NSString *)obj;
            [self loadingEnvirenInfo];//加载室外空气数据
        });
    }];
}

- (void)loadingEnvirenInfo{
    [BJManegerHttpData requestAirQualifyInfo:self.locationLabel.text complation:^(id obj) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *resultDic = (NSDictionary *)obj;
            
            //pm2.5
            double pm25 = [[resultDic valueForKey:@"pm2_5"] doubleValue];
            NSLog(@"pm2.5 --- %f",pm25);
            
            //空气质量
            double aqi = [[resultDic valueForKey:@"aqi"] doubleValue];
            NSString *airQualify;
            
            //0-50=优, 50-100=良, 100-150=轻度污染, 150-200=中度污染,200-300=重度污染, 300以上=严重污染
            if (aqi >= 0 && aqi <=50)
                airQualify = @"优";
            else if (aqi > 50 && aqi <= 100)
                airQualify = @"良好";
            else if (aqi > 100 && aqi <= 150)
                airQualify = @"轻度污染";
            else if (aqi > 150 && aqi <= 200)
                airQualify = @"中度污染";
            else if (aqi > 200 && aqi <= 300)
                airQualify = @"重度污染";
            else if (aqi > 300)
                airQualify = @"严重污染";
            else
                airQualify = @"-";
            
            NSLog(@"airQua --- %@",airQualify);
            NSLog(@"PM2.5/PM10: --- %@",resultDic);
            
            //pm10
            double pm10 = [[resultDic valueForKey:@"pm10"] doubleValue];
            
            self.airQualityLabel.text = airQualify;
            self.pm25Label.text = [NSString stringWithFormat:@"%.0f",pm25];
            self.pm10Label.text = [NSString stringWithFormat:@"%.0f",pm10];
        });
    }];
}

- (UIFont *)lightFont:(CGFloat)size
{
    return [UIFont fontWithName:@"Helvetica Light" size:size];
}

+ (AirPurificationController *)currentController
{
    SlideNavigationController *navCtrl = [SlideNavigationController sharedInstance];
    for(int i=(int)(navCtrl.viewControllers.count-1); i>0; i--)
    {
        if([navCtrl.viewControllers[i] isKindOfClass:[AirPurificationController class]])
            return navCtrl.viewControllers[i];
    }
    return nil;
}

@end
