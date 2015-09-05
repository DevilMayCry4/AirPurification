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
#import "UICircularSlider.h"

#define ALERT_TAG_SHUTDOWN          1

static CGFloat const kAirVolumeMax = 14.0;
static CGFloat const kStatusHeight = 25.0;
static CGFloat const kPM2_5SmallFont = 80.0;
static CGFloat const kPM2_5BigFont = 112;;
static NSString *const kAirInfoString = @"我身边的空气指数：";

@interface AirPurificationController ()
{
    //提示框
    IoTAlertView *_alertView;
    
    //数据点的临时变量
    BOOL bSwitch;
    BOOL bSwitch_Plasma;
    BOOL bLED_Air_Quality;
    BOOL bChild_Security_Lock;
    NSInteger iFilter_Life;
    NSInteger Air_Volume;
    //临时数据
    NSArray *modeImages, *modeTexts;
    
    NSString *_location;
    UILabel        *_statusLabel;
    UILabel        *_pmLabel;
    UILabel        *_cityLabel;
    UILabel        *_temperatureLabel;
    UILabel        *_moistureLabel;
    UILabel        *_moisturePercentLabel;
    UILabel        *_pm25Label;
    UILabel        *_pm10Label;
    UILabel        *_airVolumeLabel;
    UIImageView    *_pm25ImageView;
    UIImageView    *_pm10ImageView;
    CircleProgressView *_filterProgress;
    UICircularSlider *_circleSlider;
    UIImageView     *_bgImageView;
}



//定位
@property (nonatomic, strong) CLLocationManager         *manager;
@property (nonatomic, strong) IoTShutdownStatus         * shutdownStatusCtrl;
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
    _bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg1.png"]];
    _bgImageView.frame = self.view.bounds;
    [self.view addSubview:_bgImageView];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_menu"] style:UIBarButtonItemStylePlain target:[SlideNavigationController sharedInstance] action:@selector(toggleLeftMenu)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_start"] style:UIBarButtonItemStylePlain target:self action:@selector(onPower)];
  
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
    scrollView.backgroundColor = [UIColor clearColor];
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
    
    //开启自动定位
    //判断是否开启了位置服务
    self.manager = [[CLLocationManager alloc]init];
    [self.manager requestWhenInUseAuthorization];
    self.manager.delegate = self;
    //设置精度
    [self.manager setDesiredAccuracy:kCLLocationAccuracyBest];
    //设置更新距离
    [self.manager setDistanceFilter:20];
    //开始更新经纬度
    [self.manager startUpdatingLocation];
    
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
            contentView.backgroundColor = [UIColor clearColor];
            contentView.center = CGPointMake(CGRectGetWidth(frame)/2, CGRectGetHeight(frame)/2);
            
            CGFloat const kStatusWidth = 172.0;
          
            _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake((kContentWidth - kStatusWidth)/2, 0, kStatusWidth, kStatusHeight)];
            _statusLabel.textAlignment = NSTextAlignmentCenter;
            _statusLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4];
            _statusLabel.layer.cornerRadius = kStatusHeight/2;
            _statusLabel.clipsToBounds = YES;
            _statusLabel.textColor = [UIColor whiteColor];
            _statusLabel.text = kAirInfoString;
            _statusLabel.font = [UIFont systemFontOfSize:13];
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
            _pmLabel.font = [self lightFont:80];
           
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
            
            _pm25Label = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(frame), CGRectGetMaxY(frame) + 4, CGRectGetWidth(frame), 20)];
            _pm25Label.textColor = [UIColor whiteColor];
            _pm25Label.font = [UIFont boldSystemFontOfSize:20];
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
            
            _pm10Label = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(frame), CGRectGetMaxY(frame) + 4, CGRectGetWidth(frame), 20)];
            _pm10Label.textColor = [UIColor whiteColor];
            _pm10Label.font = _pm25Label.font;
            _pm10Label.textAlignment = NSTextAlignmentCenter;
            _pm10Label.adjustsFontSizeToFitWidth = YES;
            [contentView addSubview:_pm10Label];
            
            CGFloat const kCityWidth = 123.0;
            _cityLabel = [[UILabel alloc] initWithFrame:CGRectMake((kContentWidth - kCityWidth)/2, CGRectGetMaxY(_statusLabel.frame)+140, kCityWidth, kStatusHeight)];
            _cityLabel.textAlignment = NSTextAlignmentCenter;
            _cityLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4];
            _cityLabel.layer.cornerRadius = kStatusHeight/2;
            _cityLabel.clipsToBounds = YES;
            _cityLabel.textColor = [UIColor whiteColor];
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
            
            _temperatureLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(frame) + 20, CGRectGetMinY(frame), 100, CGRectGetHeight(frame))];
            _temperatureLabel.textColor = [UIColor whiteColor];
            _temperatureLabel.text = @"60";
            _temperatureLabel.font = [UIFont systemFontOfSize:36];
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
            _moistureLabel.textColor = [UIColor whiteColor];
            _moistureLabel.textAlignment = NSTextAlignmentRight;
            _moistureLabel.text = @"60";
            _moistureLabel.font = [UIFont systemFontOfSize:36];
            [contentView addSubview:_moistureLabel];
            
            _moisturePercentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            _moisturePercentLabel.text = @"%";
            _moisturePercentLabel.textColor = [UIColor whiteColor];
            _moisturePercentLabel.font = [UIFont systemFontOfSize:18];
            [_moisturePercentLabel sizeToFit];
            frame = _moisturePercentLabel.frame;
            frame.origin.x = CGRectGetMaxX(_moistureLabel.frame);
            frame.origin.y = CGRectGetMinY(_moistureLabel.frame) - CGRectGetHeight(frame)/2 + 8;
            _moisturePercentLabel.frame = frame;
            [contentView addSubview:_moisturePercentLabel];
            
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
            
        case 2:
        {
            _circleSlider = [[UICircularSlider alloc] initWithFrame:CGRectMake(0, 0, 250, 250)];
            _circleSlider.backgroundColor = [UIColor clearColor];
            _circleSlider.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.4];
            _circleSlider.thumbTintColor = [UIColor colorWithRed:0.227  green:0.792  blue:0.976 alpha:1];
            _circleSlider.minimumTrackTintColor = [UIColor colorWithRed:0.012  green:0.537  blue:0.894 alpha:1];
            _circleSlider.continuous = NO;
            _circleSlider.maximumValue = kAirVolumeMax;
            [_circleSlider addTarget:self action:@selector(airVolumeChange:) forControlEvents:UIControlEventValueChanged];
            _circleSlider.center = CGPointMake(CGRectGetWidth(view.bounds)/2, CGRectGetHeight(view.bounds)/2);
            [view addSubview:_circleSlider];
            CGFloat height  = 90.0;
            _airVolumeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (CGRectGetHeight(_circleSlider.frame) - height)/2, CGRectGetWidth(_circleSlider.frame), height)];
            _airVolumeLabel.font = [UIFont systemFontOfSize:84];
            _airVolumeLabel.textColor = [UIColor whiteColor];
            _airVolumeLabel.textAlignment = NSTextAlignmentCenter;
            [_circleSlider addSubview:_airVolumeLabel];
            
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
    self.onTiming = 0;
 

//    [self selectSwitchPlasma:bSwitch_Plasma sendToDevice:NO];
//    [self selectChildSecurityLock:bChild_Security_Lock sendToDevice:NO];
//    [self selectLEDAirQuality:bLED_Air_Quality sendToDevice:NO];
//    [self selectWindVelocity:iWindVelocity sendToDevice:NO];
    
    self.view.userInteractionEnabled = bSwitch;
   
    
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
                     DATA_ENTITY: @{Data_Switch: value}};
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
            return [attributes valueForKey:Data_Switch];
            
        case IoTDeviceAlertAirQuality:
            return attributes[Data_AQI];
            break;
            
        case IoTDeviceAlertFilterLife:
            return attributes[Data_Cartridge_life];
            break;
            
        case IoTDeviceWriteWindVelocity:
            return attributes[Data_Air_Volume];
            break;
            
        case IoTDeviceWritPM2_5:
            return attributes[Data_PM2_5];
            break;
            
        case IoTDevicehumidity:
            return attributes[Data_humidity];
            break;
            
        case IoTDevice_model:
            return attributes[Data_model];
            break;
            
        case IoTDevice_temperature:
            return attributes[Data_temperature];
            break;
            
        default:
            NSLog(@"Error: read invalid datapoint, skip.");
            break;
            
    }
    return nil;
}

//数据入口
- (void)XPGWifiDevice:(XPGWifiDevice *)device didReceiveData:(NSDictionary *)data result:(int)result{
    
    if(![device.did isEqualToString:self.device.did])
        return;
    
    [IoTAppDelegate.hud hide:YES];
    //[self.shutdownStatusCtrl hide:YES];
    /**
     * 数据部分
     */
    NSDictionary *_data = [data valueForKey:@"data"];
    if(nil != _data)
    {
        bSwitch  = [[self readDataPoint:IoTDeviceWriteOnOff data:_data] boolValue];
        NSString *AQI  = [self readDataPoint:IoTDeviceAlertAirQuality data:_data];
        iFilter_Life = [[self readDataPoint:IoTDeviceAlertFilterLife data:_data] integerValue];
        Air_Volume = [[self readDataPoint:IoTDeviceWriteWindVelocity  data:_data] integerValue];
       
         self.view.userInteractionEnabled = bSwitch;
        
        NSInteger airVolume = [[self readDataPoint:IoTDeviceWriteWindVelocity data:_data] integerValue];
        _circleSlider.value = airVolume;
        NSInteger maxAir = 254;
        NSArray *airQualityWords = @[@"健康",@"亚健康",@"不健康"];
        NSString *qualityString = @"";
        NSInteger iAir_Quality = AQI.integerValue;
        
        if (iAir_Quality <= maxAir/airQualityWords.count)
        {
            qualityString = [airQualityWords firstObject];
        }
        else if(iAir_Quality <= maxAir/airQualityWords.count*2)
        {
            qualityString = airQualityWords[2];
        }
        else
        {
            qualityString = [airQualityWords lastObject];
        }
        NSString *bgName = [NSString stringWithFormat:@"bg%lu",[airQualityWords indexOfObject:qualityString]+1];
        _bgImageView.image = [UIImage imageNamed:bgName];
        //TODO::更新界面
        
        _filterProgress.progress = iFilter_Life/100.0;
     
        if (iAir_Quality < airQualityWords.count-1)
        {
            qualityString = airQualityWords[iAir_Quality];
        }
        
        NSMutableAttributedString *mAttrString = [[NSMutableAttributedString alloc] initWithString:[kAirInfoString stringByAppendingString:qualityString]];
        NSRange qualityRange = NSMakeRange(mAttrString.length-qualityString.length, qualityString.length);
        [mAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.694  green:0.039  blue:0.078 alpha:1] range:qualityRange];
        [mAttrString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15] range:qualityRange];
        _statusLabel.attributedText = mAttrString;
        
        CGPoint center = _statusLabel.center;
        [_statusLabel sizeToFit];
        CGRect frame = _statusLabel.frame;
        frame.size.width += 40;
        frame.size.height = kStatusHeight;
        _statusLabel.frame = frame;
        _statusLabel.center = center;
  
//        机器pm2.5
        _pmLabel.text = [self readDataPoint:IoTDeviceWritPM2_5 data:_data];
        _pmLabel.font = [self lightFont:_pmLabel.text.length < 3 ? kPM2_5BigFont : kPM2_5SmallFont];
        center = _pmLabel.center;
        [_pmLabel sizeToFit];
        frame = _pmLabel.frame;
        _pmLabel.frame = frame;
        _pmLabel.center = center;
        
//    温度
        _temperatureLabel.text = [self readDataPoint:IoTDevice_temperature data:_data];
 
//     湿度
        CGPoint origin = _moistureLabel.frame.origin;
        _moistureLabel.text = [self readDataPoint:IoTDevicehumidity data:_data];
        [_moistureLabel sizeToFit];
        frame = _moistureLabel.frame;
        frame.origin = origin;
        _moistureLabel.frame = frame;
       
        
        frame = _moisturePercentLabel.frame;
        frame.origin.x = CGRectGetMaxX(_moistureLabel.frame);
        _moisturePercentLabel.frame = frame;
        
        //没有开机，切换页面
        if(!bSwitch)
        {
            [self onPower];
            return;
        }
    }
    
    
    /**
     * 报警和错误
     */
    if([self.navigationController.viewControllers lastObject] != self)
        return ;
       /**
     * 清理旧报警及故障
     */
    [[IoTRecord sharedInstance] clearAllRecord];
    
 
 
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
    
 
}

#pragma mark - Properties
- (NSInteger)onTiming
{
    return 1;
  //  return iOnTiming;
}

- (void)setOnTiming:(NSInteger)onTiming
{
   // iOnTiming  = onTiming;
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
- (void)airVolumeChange:(UICircularSlider *)slider
{
    _airVolumeLabel.text = [@((int)(slider.value + 0.5)) stringValue];
}

- (void)onDisconnected
{
    //断线且页面在控制页面时才弹框
    UIViewController *currentController = self.navigationController.viewControllers.lastObject;
    
    if(!self.device.isConnected &&
       ([currentController isKindOfClass:[AirPurificationController class]] ||
        [currentController isKindOfClass:[IoTShutdownStatus class]]))
    {
        [IoTAppDelegate.hud hide:YES];
        [_alertView hide:YES];
       
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
    
}

////============风速===========
//- (IBAction)onStrong:(id)sender
//{
//    if(iWindVelocity != 0)
//        [self selectWindVelocity:0 sendToDevice:YES];
//    [self getFanTextColor:YES];
//}
//- (IBAction)onSleep:(id)sender
//{
//    if(iWindVelocity != 2)
//        [self selectWindVelocity:2 sendToDevice:YES];
//    
//}
//- (IBAction)onStandard:(id)sender
//{
//    if(iWindVelocity != 1)
//        [self selectWindVelocity:1 sendToDevice:YES];
//    [self getFanTextColor:YES];
//}

- (IBAction)onAuto:(id)sender
{
//    if(iWindVelocity != 3)
//        [self selectWindVelocity:3 sendToDevice:YES];
//    [self getFanTextColor:YES];
}

#pragma mark - Group Selection
- (UIColor *)getFanTextColor:(BOOL)bSelected
{
    if(bSelected)
        return [UIColor blueColor];
    return [UIColor grayColor];
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
//    if(value == 24)
//        iOffTiming = 0;
//    else
//        iOffTiming = (value+1) * 60 ;
//    [self writeDataPoint:IoTDeviceWriteCountDownOffMin value:@(iOffTiming)];
//    [self onUpdateShutdownText];
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
           _location = (NSString *)obj;
            if ([obj length])
            {
                NSString *string = [obj stringByAppendingString:@"的空气质量"];
                CGSize size = [string sizeWithFont:_cityLabel.font];
                CGPoint center = _cityLabel.center;
                CGRect frame = _cityLabel.frame;
                frame.size.width = size.width += 40;
                _cityLabel.frame = frame;
                _cityLabel.center = center;
                _cityLabel.text = [obj stringByAppendingString:@"的空气质量"];
            }
            else
            {
                _cityLabel.text = nil;
            }
            [self loadingEnvirenInfo];//加载室外空气数据
        });
    }];
}

- (void)loadingEnvirenInfo{
    [BJManegerHttpData requestAirQualifyInfo:_location complation:^(id obj) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *resultDic = (NSDictionary *)obj;
            NSDictionary *city = resultDic[@"aqi"][@"city"];
            if (city)
            {
                _pm25Label.text = city[@"pm25"];
                _pm10Label.text = city[@"pm10"];
            }
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
