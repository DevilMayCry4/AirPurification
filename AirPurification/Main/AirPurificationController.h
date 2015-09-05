//
//  AirPurificationController.h
//  AirPurification
//
//  Created by virgil on 15/8/31.
//  Copyright (c) 2015年 xpg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IoTMainController.h"
//typedef enum
//{
//    // writable
//    IoTDeviceWriteUpdateData = 0,           //更新数据
//    IoTDeviceWriteOnOff,                    //开关
//    IoTDeviceWriteSwitchPlasma,             //等离子开关
//    IoTDeviceWriteChildSecurityLock,        //儿童锁
//    IoTDeviceWriteLEDAirQuality,            //空气指令指示灯
//    IoTDeviceWriteCountDownOnMin,           //倒计时开机
//    IoTDeviceWriteCountDownOffMin,          //倒计时关机
//    IoTDeviceWriteWindVelocity,             //风速
//    IoTDeviceWriteQuality,                  //空气质量
//    IoTDeviceWriteAirSensitivity,           //灵敏度
//    IoTDeviceWriteFilterLife,               //滤网寿命
//    
//    // alert
//    IoTDeviceAlertDust,                     //空气质量_粉尘
//    IoTDeviceAlertPeculiar,                 //空气质量_异味
//    IoTDeviceAlertFilterLife,               //滤芯寿命报警
//    IoTDeviceAlertAirQuality,               //空气质量警报
//    
//    // fault
//    IoTDeviceFaultMotor,                    //电机故障
//    IoTDeviceFaultAir,                      //空气传感器故障
//    IoTDeviceFaultDust,                     //灰尘传感器故障
//    
//}IoTDeviceDataPoint;

//typedef enum
//{
//    IoTDeviceCommandWrite    = 1,//写
//    IoTDeviceCommandRead     = 2,//读
//    IoTDeviceCommandResponse = 3,//读响应
//    IoTDeviceCommandNotify   = 4,//通知
//}IoTDeviceCommand;

#define DATA_CMD                        @"cmd"                  //命令
#define Data_Switch @"ON_OFF"
#define Data_Air_Volume @"Air_Volume"
#define Data_Cartridge_life @"Cartridge_life"
#define Data_PM2_5   @"PM2_5"
#define Data_humidity @"humidity"
#define Data_model @"model"
#define Data_temperature @"temperature"
#define Data_AQI @"AQI"


#define DebugAir  0

@protocol PredictScrollViewDelegate;

@interface AirPurificationController : UIViewController<XPGWifiDeviceDelegate,PredictScrollViewDelegate>

//用于切换设备
@property (nonatomic, strong) XPGWifiDevice *device;

//数据信息
@property (nonatomic, assign) NSInteger onTiming;       //开机定时
@property (nonatomic, assign) NSInteger airSensitivity; //空气灵敏度
@property (nonatomic, assign) NSInteger filterLife;     //滤网寿命

//写入数据接口
- (void)writeDataPoint:(IoTDeviceDataPoint)dataPoint value:(id)value;

- (id)initWithDevice:(XPGWifiDevice *)device;

//获取当前实例
+ (AirPurificationController *)currentController;

@end
