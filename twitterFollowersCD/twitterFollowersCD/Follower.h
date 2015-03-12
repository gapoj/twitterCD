//
//  Follower.h
//  twitterFollowersCD
//
//  Created by Guillermo Apoj on 12/3/15.
//  Copyright (c) 2015 Globant. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Follower : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * id_str;
@property (nonatomic, retain) NSString * screen_name;

@end
