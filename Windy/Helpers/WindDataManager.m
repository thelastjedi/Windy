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

#import "WindDataManager.h"

@interface Windy : NSObject
@property (nonatomic, retain) NSString	* speed;
@property (nonatomic, retain) NSString	* direction;
@property (nonatomic, retain) NSDate	* lastUpdated;
@property (nonatomic, assign) CGFloat	  longitude;
@property (nonatomic, assign) CGFloat	  latitude;

@end

#define OPEN_WEATHER_RATE_LIMIT     10
#define WEATHER_API_CALLED_KEY      @"weather_api_key"
#define WEATHER_OBJECT_KEY          @"weather_obj_key"
#define OPEN_WEATHER_MAP_API_KEY    @"fe4fe9724fb8c6775d5ef2b61cbccce3"


@interface WindDataManager()
{
    BOOL isUpdating;
}

@property (nonatomic, strong) Windy     * currentWind;
@end

@implementation  WindDataManager
@synthesize currentWind;

+ (id)sharedManager
{
    static WindDataManager *sharedManager = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedManager = [[self alloc] init];
        });
    return sharedManager;
}

#pragma mark - Public

-(void)updateWindDataForLatitude:(CGFloat)latitude andLongitude:(CGFloat)longitude{
    
    if(![self shouldFetchWindData]||isUpdating)
    {
        [self loadLastSavedWind];
        NSLog(@"not fetching now");
        return;
    }
    
    isUpdating = YES;

    [self getWindDataForLatitude:latitude andLongitude:longitude completion:^(BOOL done, id response){

        [self apiWasCalled];
        isUpdating = NO;
        
        if(!done){
            [self invokeDelegateWithMessage:@"Error"];
        }
        else
        {
            if(!currentWind) currentWind = [[Windy alloc] init];

            currentWind.latitude      = latitude;
            currentWind.longitude     = longitude;
            currentWind.lastUpdated   = [NSDate date];
            currentWind.direction     = [NSString stringWithFormat:@"%@", response[@"deg"]];
            currentWind.speed         = [NSString stringWithFormat:@"%@", response[@"speed"]];
            
            [self windWasUpdated];
        }
    }];
}

#pragma mark


-(void)invokeDelegateWithMessage:(NSString*)msg{
    if([self.windDelegate respondsToSelector:@selector(updateWindLabel:)])
        [self.windDelegate updateWindLabel:msg];
}

-(void)getWindDataForLatitude:(CGFloat)latitude andLongitude:(CGFloat)longitude completion:(void (^)(BOOL done, id response))dataCompletion;
{
    NSString * urlString = @"http://api.openweathermap.org/data/2.5/weather?lat=%d&lon=%d";
    urlString = [NSString stringWithFormat:urlString, (int)latitude, (int)longitude];
    
    NSURL * url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest * request = [NSMutableURLRequest
                                     requestWithURL:url
                                     cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                     timeoutInterval:30];

    [request setValue:OPEN_WEATHER_MAP_API_KEY forHTTPHeaderField:@"x-api-key"];
    [request setHTTPMethod:@"GET"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data ,NSError *error) {
        
        NSDictionary * jsonData = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data
                                                                                  options:kNilOptions
                                                                                    error:&error];
        if(error)
        {
            dataCompletion(NO, error);
        }
        else
        {
            if(!jsonData[@"wind"])
                dataCompletion(NO, nil);
            else
                NSLog(@"%@", jsonData);
                dataCompletion(YES, jsonData[@"wind"]);
        }
    }];
}

#pragma mark - Rate Limiting

-(void)apiWasCalled{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:WEATHER_API_CALLED_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSDate*)lastApiCall{
    return [[NSUserDefaults standardUserDefaults] objectForKey:WEATHER_API_CALLED_KEY];
}

-(BOOL)shouldFetchWindData{
    /**
     * As per the section "How to work with API in more effective way" from openweathermap.org/appid
     */
    NSDate * now         = [NSDate date];
    NSDate * lastApiHit  = [self lastApiCall];
    
    if(!lastApiHit)
        return YES;
    
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

-(void)loadLastSavedWind{
    NSData *windData = [[NSUserDefaults standardUserDefaults] objectForKey:WEATHER_OBJECT_KEY];
    if(!windData) return;
    self.currentWind  = [NSKeyedUnarchiver unarchiveObjectWithData:windData];
    [self invokeDelegateWithMessage:currentWind.speed];
}

-(void)windWasUpdated{
    NSData *windData = [NSKeyedArchiver archivedDataWithRootObject:self.currentWind];
    [[NSUserDefaults standardUserDefaults] setObject:windData forKey:WEATHER_OBJECT_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self invokeDelegateWithMessage:currentWind.speed];
}


@end

@implementation Windy
@synthesize direction, speed;
@synthesize longitude, latitude;
@synthesize lastUpdated;


- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if(self) {
        self.direction    = [decoder decodeObjectForKey:WIND_DIRECTION_KEY];
        self.speed		  = [decoder decodeObjectForKey:WIND_SPEED_KEY];
        self.longitude    = [decoder decodeFloatForKey :WIND_LONGITUDE_KEY];
        self.latitude     = [decoder decodeFloatForKey :WIND_LATITUDE_KEY];
        self.lastUpdated  = [decoder decodeObjectForKey:WIND_LASTUPDATED_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.direction    forKey:WIND_DIRECTION_KEY];
    [encoder encodeObject:self.speed        forKey:WIND_SPEED_KEY];
    [encoder encodeFloat:self.longitude     forKey:WIND_LONGITUDE_KEY];
    [encoder encodeFloat:self.latitude      forKey:WIND_LATITUDE_KEY];
    [encoder encodeObject:self.lastUpdated  forKey:WIND_LASTUPDATED_KEY];
}

@end