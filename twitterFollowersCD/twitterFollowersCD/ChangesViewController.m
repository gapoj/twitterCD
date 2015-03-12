//
//  FollowerChangesViewController.m
//  twitterFollowersCD
//
//  Created by Guillermo Apoj on 12/3/15.
//  Copyright (c) 2015 Globant. All rights reserved.
//

#import "ChangesViewController.h"
#import "Follower.h"

@interface ChangesViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ChangesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:self.typeOfFollowers];
    self.label.text= [NSString stringWithFormat:@"%lu %@ since your last update",(unsigned long)self.changedFollowers.count,self.typeOfFollowers];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        return self.changedFollowers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *object =(NSDictionary *) self.changedFollowers[indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChangesCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ChangesCell"];
    }
    [[cell textLabel] setText:[object objectForKey:@"name"] ];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@",[object objectForKey:@"screen_name"]];
    return cell;
}

@end
