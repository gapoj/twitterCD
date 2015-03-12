//
//  FollowerChangesViewController.h
//  twitterFollowersCD
//
//  Created by Guillermo Apoj on 12/3/15.
//  Copyright (c) 2015 Globant. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChangesViewController : UIViewController
@property (strong, nonatomic) NSArray* changedFollowers;
@property (strong, nonatomic) NSString *typeOfFollowers;

@end
