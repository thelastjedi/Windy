//
//  TodayViewController.m
//  Windy
//
//  Created by Harshita on 28/02/15.
//  Copyright (c) 2015 Harshita. All rights reserved.
//

#import "WindDataManager.h"
#import <CoreLocation/CoreLocation.h>

#import <NotificationCenter/NotificationCenter.h>
#import "TodayViewController.h"

#define PermissionDeniedText  @"Allow location services in Settings."
#define LocationErrorText     @"Try again later."
#define LocationLoadingText   @"Loading..."


@interface TodayViewController () <NCWidgetProviding, CLLocationManagerDelegate, WindDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation TodayViewController
@synthesize locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self  setupLocationManager];
    [[WindDataManager sharedManager] setWindDelegate:self];
}

-(void)setupLocationManager {
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate        = self;
    locationManager.distanceFilter  = 100;
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    
    //iOS 8: which is the minimum deployment target for a widget to exist
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - NCWidgetProviding

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler{
    [locationManager startUpdatingLocation];
    completionHandler(NCUpdateResultNewData);
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation: (CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    CGFloat latitude  = manager.location.coordinate.latitude;
    CGFloat longitude = manager.location.coordinate.longitude;
    [[WindDataManager sharedManager] updateWindDataForLatitude:latitude andLongitude:longitude];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    // kCLAuthorizationStatusDenied tells us that user denied permission
    if (status == kCLAuthorizationStatusDenied) {
        if([self shouldUpdateLabelWithSystemMsg]) {
            [self.windLabel setText:PermissionDeniedText];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if([self shouldUpdateLabelWithSystemMsg]) {
        [self.windLabel setText:LocationErrorText];
    }
    NSLog(@"Failed to get location : %@", error.debugDescription);
}

#pragma mark - WindDelegate

-(void)updateWindLabel:(NSString*)text {
    if (text) [self.windLabel setText:text];
}

#pragma mark 

-(BOOL)shouldUpdateLabelWithSystemMsg {
    return ([self.windLabel.text isEqualToString:LocationLoadingText]) || ([self.windLabel.text isEqualToString:LocationErrorText]);
}
@end