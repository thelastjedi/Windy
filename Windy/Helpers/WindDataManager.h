//
//  WindDataManager.h
//  Widget-Example
//
//  Created by Harshita on 26/02/15.
//  Copyright (c) 2015 Harshita. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol WindDelegate <NSObject>
-(void)updateWindLabel:(NSString*)text;
@end

@interface WindDataManager : NSObject

+(id)sharedManager;

/**
 *  Fetch wind data for given co-ordinates
 */
-(void)updateWindDataForLatitude:(CGFloat)latitude andLongitude:(CGFloat)longitude;

/**
 *  Get animation duration of Pinwheel 
 *  according to the current wind's Beaufort
 *  Number
 *
 *  @return pinwheel animation duration
 */
-(CGFloat)getPinwheelSpeed;

@property (nonatomic, strong) id<WindDelegate> windDelegate;

@end