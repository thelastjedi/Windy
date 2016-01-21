//
//  WindDataManager.m
//  Widget-Example
//
//  Created by Harshita on 26/02/15.
//  Copyright (c) 2015 Harshita. All rights reserved.
//


/**
 *  This project uses OpenWeatherMap which provides a really nice weather API for developers.
 *  The API has free and paid plans; for our requirement, free is sufficient.
 *  We make sure API isn't called more than once every 10 minutes.
 *
 *  More information here: openweathermap.org/appid
 *
 *  Sign up and replace the key in 'OPEN_WEATHER_MAP_API_KEY'
 *
 */



#define WIND_DIRECTION_KEY      @"windDirectionKey"
#define WIND_SPEED_KEY          @"windSpeedKey"
#define WIND_LONGITUDE_KEY      @"windLongitudeKey"
#define WIND_LATITUDE_KEY       @"windLatitudeKey"
#define WIND_LASTUPDATED_KEY    @"windLastUpdatedKey"
#define WIND_BSNUM_KEY          @"windBeaufortNumberKey"
#import "WindDataManager.h"

@interface Windy : NSObject
@property (nonatomic, retain) NSString	* speed;
@property (nonatomic, retain) NSString	* direction;
@property (nonatomic, retain) NSDate	* lastUpdated;
@property (nonatomic, assign) CGFloat	  longitude;
@property (nonatomic, assign) CGFloat	  latitude;
@property (nonatomic, assign) NSInteger	  beaufortNum;

@end

#define OPEN_WEATHER_RATE_LIMIT     10
#define WEATHER_API_CALLED_KEY      @"weather_api_key"
#define WEATHER_OBJECT_KEY          @"weather_obj_key"
#define OPEN_WEATHER_MAP_API_KEY    @"fe4fe9724fb8c6775d5ef2b61cbccce3"


@interface WindDataManager() {
    BOOL isUpdating;
}

@property (nonatomic, strong) Windy     * currentWind;
@end

@implementation  WindDataManager
@synthesize currentWind;

+ (id)sharedManager {
    static WindDataManager *sharedManager = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedManager = [[self alloc] init];
        });
    return sharedManager;
}

#pragma mark - Public

-(void)updateWindDataForLatitude:(CGFloat)latitude andLongitude:(CGFloat)longitude {
    
    if(![self shouldFetchWindData]||isUpdating) {
        [self loadLastSavedWind];
        return;
    }
    
    isUpdating = YES;

    [self getWindDataForLatitude:latitude andLongitude:longitude completion:^(BOOL done, id response) {

        [self apiWasCalled];
        isUpdating = NO;
        
        if(!done) {
            [self invokeDelegateWithMessage:response];
        }
        else {
            if(!currentWind) currentWind = [[Windy alloc] init];

            currentWind.latitude      = latitude;
            currentWind.longitude     = longitude;
            currentWind.lastUpdated   = [NSDate date];
            currentWind.direction     = [NSString stringWithFormat:@"%@", response[@"deg"]];
            currentWind.speed         = [NSString stringWithFormat:@"%@", response[@"speed"]];
            currentWind.beaufortNum   = [self beaufortNumberFor:currentWind.speed];
            [self windWasUpdated];
        }
    }];
}

#pragma mark

-(void)getWindDataForLatitude:(CGFloat)latitude andLongitude:(CGFloat)longitude completion:(void (^)(BOOL done, id response))dataCompletion {
    
    NSString * urlString = @"http://api.openweathermap.org/data/2.5/weather?lat=%d&lon=%d&appid=%@";
    urlString = [NSString stringWithFormat:urlString, (int)latitude, (int)longitude, OPEN_WEATHER_MAP_API_KEY];
    
    NSURL * url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest * request = [NSMutableURLRequest
                                     requestWithURL:url
                                     cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                     timeoutInterval:30];

    [request setHTTPMethod:@"GET"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data ,NSError *error) {
        
        NSDictionary * jsonData;
        
        if(data) {
            jsonData = (NSDictionary *)[NSJSONSerialization
                                        JSONObjectWithData:data
                                        options:kNilOptions
                                        error:&error];
        }
        
        if((error)||(!jsonData)) {
            dataCompletion(NO, error.localizedDescription);
        }
        else {
            if(!jsonData[@"wind"]) {
                dataCompletion(NO, nil);
            }
            else {
                NSLog(@"%@", jsonData);
                dataCompletion(YES, jsonData[@"wind"]);
            }
        }
    }];
}

#pragma mark - Beaufort Number

-(NSInteger)beaufortNumberFor:(NSString*)windSpeedString {
    
    NSInteger windSpeed = [windSpeedString floatValue];
    
    NSRange beaufortNumber0 = NSMakeRange (0.0f, 0.3f);
    NSRange beaufortNumber1 = NSMakeRange (0.3f, 1.5f);
    NSRange beaufortNumber2 = NSMakeRange (1.5f, 3.3f);
    NSRange beaufortNumber3 = NSMakeRange (3.3f, 5.5f);
    NSRange beaufortNumber4 = NSMakeRange (5.5f, 8.0f);
    NSRange beaufortNumber5 = NSMakeRange (8.0f, 10.8f);
    NSRange beaufortNumber6 = NSMakeRange (10.8f, 13.9f);
    NSRange beaufortNumber7 = NSMakeRange (13.9f, 17.2f);
    NSRange beaufortNumber8 = NSMakeRange (17.2f, 20.7f);
    NSRange beaufortNumber9 = NSMakeRange (20.7f, 24.5f);
    
    if (NSLocationInRange(windSpeed, beaufortNumber0)) {
        return 0;
    }
    else if (NSLocationInRange(windSpeed, beaufortNumber1)) {
        return 1;
    }
    else if (NSLocationInRange(windSpeed, beaufortNumber2)) {
        return 2;
    }
    else if (NSLocationInRange(windSpeed, beaufortNumber3)) {
        return 3;
    }
    else if (NSLocationInRange(windSpeed, beaufortNumber4)) {
        return 4;
    }
    else if (NSLocationInRange(windSpeed, beaufortNumber5)) {
        return 5;
    }
    else if (NSLocationInRange(windSpeed, beaufortNumber6)) {
        return 6;
    }
    else if (NSLocationInRange(windSpeed, beaufortNumber7)) {
        return 7;
    }
    else if (NSLocationInRange(windSpeed, beaufortNumber8)) {
        return 8;
    }
    else if (NSLocationInRange(windSpeed, beaufortNumber9)) {
        return 9;
    }
    else return 10;
}

-(CGFloat)getPinwheelSpeed {
    if(!currentWind) {
        return CGFLOAT_MAX;
    }
    else {
        CGFloat bfNum = currentWind.beaufortNum;
        if(bfNum < 2 ) {
            return CGFLOAT_MAX;
        }
        else if(bfNum < 5 ) {
            bfNum--;
        }
        
        return 0.5/bfNum;
    }
}

#pragma mark - Rate Limiting

-(void)apiWasCalled {
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:WEATHER_API_CALLED_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSDate*)lastApiCall {
    return [[NSUserDefaults standardUserDefaults] objectForKey:WEATHER_API_CALLED_KEY];
}

-(BOOL)shouldFetchWindData {
    /**
     * As per the section "How to work with API in more effective way" from openweathermap.org/appid
     */
    NSDate * now         = [NSDate date];
    NSDate * lastApiHit  = [self lastApiCall];
    
    if(!lastApiHit) {
        return YES;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSCalendarUnitMinute;
    
    NSDateComponents *dateComponent = [calendar components:unitFlags
                                                  fromDate:lastApiHit
                                                    toDate:now options:0];
    NSInteger minutesPassed  = [dateComponent minute];

    NSLog(@"Minutes Passed: %@", @(minutesPassed));
    
    return (minutesPassed > OPEN_WEATHER_RATE_LIMIT);
}

#pragma mark - Save Windy

-(void)loadLastSavedWind {
    NSData *windData = [[NSUserDefaults standardUserDefaults] objectForKey:WEATHER_OBJECT_KEY];
    if(!windData) {
        [self invokeDelegateWithMessage:@"Error"];
        return;
    }
    currentWind  = [NSKeyedUnarchiver unarchiveObjectWithData:windData];
    [self invokeDelegateWithMessage:[self getFormattedStringForDisplay]];
}

-(void)windWasUpdated {
    NSData *windData = [NSKeyedArchiver archivedDataWithRootObject:currentWind];
    [[NSUserDefaults standardUserDefaults] setObject:windData forKey:WEATHER_OBJECT_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self invokeDelegateWithMessage:[self getFormattedStringForDisplay]];
}

#pragma

-(void)invokeDelegateWithMessage:(NSString*)msg {
    if([self.windDelegate respondsToSelector:@selector(updateWindLabel:)]) {
        [self.windDelegate updateWindLabel:msg];
    }
}

-(NSString*)getFormattedStringForDisplay {
    NSString * windDirection = [self getWindDirection];
    NSString * updateString = [NSString stringWithFormat:@"Speed: %@ m/s\n\nDirection: %@", currentWind.speed, windDirection];
    return updateString;
}

-(NSString*)getWindDirection {
    NSArray * arr = @[@"N", @"NNE", @"NE", @"ENE", @"E", @"ESE", @"SE", @"SSE", @"S", @"SSW", @"SW", @"WSW", @"W", @"WNW", @"NW", @"NNW", @"N"];
    NSString *windDir = arr[(int)floor((([currentWind.direction floatValue] + 11.25)/22.5))];
    return windDir;
}

@end

@implementation Windy
@synthesize direction, speed;
@synthesize longitude, latitude, beaufortNum;
@synthesize lastUpdated;


- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if(self) {
        self.direction    = [decoder decodeObjectForKey:WIND_DIRECTION_KEY];
        self.speed		  = [decoder decodeObjectForKey:WIND_SPEED_KEY];
        self.longitude    = [decoder decodeFloatForKey :WIND_LONGITUDE_KEY];
        self.latitude     = [decoder decodeFloatForKey :WIND_LATITUDE_KEY];
        self.lastUpdated  = [decoder decodeObjectForKey:WIND_LASTUPDATED_KEY];
        self.beaufortNum  = [decoder decodeIntegerForKey:WIND_BSNUM_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.direction     forKey:WIND_DIRECTION_KEY];
    [encoder encodeObject:self.speed         forKey:WIND_SPEED_KEY];
    [encoder encodeFloat:self.longitude      forKey:WIND_LONGITUDE_KEY];
    [encoder encodeFloat:self.latitude       forKey:WIND_LATITUDE_KEY];
    [encoder encodeObject:self.lastUpdated   forKey:WIND_LASTUPDATED_KEY];
    [encoder encodeInteger:self.beaufortNum  forKey:WIND_BSNUM_KEY];
}

@end