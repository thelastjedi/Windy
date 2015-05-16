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
 *  Fetch Wind data for given co-ordinates
 */
-(void)updateWindDataForLatitude:(CGFloat)latitude andLongitude:(CGFloat)longitude;

@property (nonatomic, strong) id<WindDelegate> windDelegate;

@end