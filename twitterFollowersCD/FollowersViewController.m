//
//  FollowersViewController.m
//  twitterFollowersCD
//
//  Created by Guillermo Apoj on 3/11/15.
//  Copyright (c) 2015 Globant. All rights reserved.
//

#import "FollowersViewController.h"
#import "FHSTwitterEngine.h"
#import "OTSPersistance.h"
#import "Follower.h"
#import "ChangesViewController.h"

@import CoreData;

@interface FollowersViewController ()< UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate,NSFetchedResultsControllerDelegate >
@property NSArray *updatedFollowersArray;
@property NSArray *previousFollowersArray;
@property NSMutableArray *NewFollowersArray;
@property NSMutableArray *unFollowersArray;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) OTSPersistance *databaseManager;

@property BOOL updated;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation FollowersViewController

#pragma mark - Property Overrides

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) return _fetchedResultsController;
    
    NSManagedObjectContext *moc = [[self databaseManager] mainThreadManagedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Follower"];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:@[ sort ]];
    
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:moc sectionNameKeyPath:nil cacheName:nil];
    [self setFetchedResultsController:frc];
    [[self fetchedResultsController] setDelegate:self];
    
    NSError *error = nil;
    NSAssert([_fetchedResultsController performFetch:&error], @"Unresolved error %@\n%@", [error localizedDescription], [error userInfo]);
    return _fetchedResultsController;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.updated = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    [self setTitle:@"Followers"];
    self.NewFollowersArray = [[NSMutableArray alloc]init];
    [self setDatabaseManager:[[OTSPersistance alloc] init]];
    [[self databaseManager] setupCoreDataStackWithCompletionHandler:^(BOOL suceeded, NSError *error) {
        if (suceeded) {
            [[[self navigationItem] leftBarButtonItem] setEnabled:YES];
            [[[self navigationItem] rightBarButtonItem] setEnabled:YES];
            [self fetchedResultsController];
        } else {
            NSLog(@"Core Data stack setup failed.");
        }
    }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onUpdate:(id)sender {
    self.NewFollowersArray = [[NSMutableArray alloc]init];
    [self bringFollowers];
}
- (void)notUpdatedAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Updated" message:@"You have to alert your followers first" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alert show];
}

- (IBAction)onNewfollowers:(id)sender {
    if (self.updated) {
        ChangesViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Changes"];
        vc.changedFollowers = [NSArray arrayWithArray:self.NewFollowersArray];
        vc.typeOfFollowers=@"New Followers";
        [self.navigationController pushViewController:vc animated:YES];
    }else{
        [self notUpdatedAlert];
    }
   
}

- (void)searchForUnfollowers {
    self.unFollowersArray= [[NSMutableArray alloc]init];
    NSManagedObjectContext *searchContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    for (Follower * f in self.previousFollowersArray) {
        if ([self unfollowerCheck:f.id_str andContext:searchContext]) {
            NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:f.name, @"name", f.id_str, @"id_str",f.screen_name,@"screen_name" ,nil];
            
            [self.unFollowersArray addObject:dict];
        }
    }
}

- (IBAction)onUnfollowers:(id)sender {
    if (self.updated) {
        ChangesViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Changes"];
        [self searchForUnfollowers];
    
        vc.changedFollowers = [NSArray arrayWithArray:self.unFollowersArray];
        vc.typeOfFollowers=@"UnFollowers";
        [self.navigationController pushViewController:vc animated:YES];
    }else{
        [self notUpdatedAlert];
    }
}

- (void)updateOrCreateFollowerWithDictionary:(NSDictionary*)item andContext:(NSManagedObjectContext *)batchAddContext {
    NSFetchRequest * request=[[NSFetchRequest alloc]initWithEntityName:@"Follower"];
    NSSortDescriptor* sortDescriptor1 = [[NSSortDescriptor alloc]initWithKey:@"name" ascending:YES];
    
    NSPredicate *predicate= [NSPredicate predicateWithFormat:@"id_str == %@",[item objectForKey:@"id_str"]];
    request.predicate = predicate;
    request.sortDescriptors=[NSArray arrayWithObjects:sortDescriptor1, nil];
    Follower *friend=[batchAddContext executeFetchRequest:request error:nil].firstObject;
    if(!friend) {
        friend=[NSEntityDescription insertNewObjectForEntityForName:@"Follower" inManagedObjectContext:batchAddContext];
        friend.id_str=[item objectForKey:@"id_str"];
        friend.name =[item objectForKey:@"name"];
        friend.screen_name =[item objectForKey:@"screen_name"];
        [self.NewFollowersArray addObject:item];
    }
    friend.name =[item objectForKey:@"name"];
    friend.screen_name =[item objectForKey:@"screen_name"];
 
}
- (BOOL)unfollowerCheck:(NSString*)id_str andContext:(NSManagedObjectContext *)context {
             NSFetchRequest * request=[[NSFetchRequest alloc]initWithEntityName:@"Follower"];
             NSSortDescriptor* sortDescriptor1 = [[NSSortDescriptor alloc]initWithKey:@"name" ascending:YES];
             
             NSPredicate *predicate= [NSPredicate predicateWithFormat:@"id_str == %@",id_str];
             request.predicate = predicate;
             request.sortDescriptors=[NSArray arrayWithObjects:sortDescriptor1, nil];
            if([context executeFetchRequest:request error:nil].count == 0) {
                return NO;
             }
    
    return YES;
    
}


- (void)bringFollowers {
    
    NSString *username = [FHSTwitterEngine sharedEngine].authenticatedUsername;
    
    NSMutableDictionary *   dict1 = [[FHSTwitterEngine sharedEngine]listFollowersForUser:username isID:NO withCursor:@"-1" andUsersPerPage:@"200"];
    
       self.updatedFollowersArray =[dict1 objectForKey:@"users"];
  
    NSManagedObjectContext *batchAddContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
   
    [batchAddContext setParentContext:[[self databaseManager] mainThreadManagedObjectContext]];
    [batchAddContext performBlock:^{
        NSFetchRequest * request=[[NSFetchRequest alloc]initWithEntityName:@"Follower"];
        NSSortDescriptor* sortDescriptor1 = [[NSSortDescriptor alloc]initWithKey:@"name" ascending:YES];
        request.sortDescriptors=[NSArray arrayWithObjects:sortDescriptor1, nil];
         self.previousFollowersArray = [batchAddContext executeFetchRequest:request error:nil];
       
        for (NSInteger itemCount = 0; itemCount < self.updatedFollowersArray.count; itemCount++) {
            NSDictionary * item = [self.updatedFollowersArray objectAtIndex:itemCount];
            
            [self updateOrCreateFollowerWithDictionary:item andContext:batchAddContext];
        }
        
        // Save the batchAddContext which pushes the items onto the main thread context
        NSError *error;
        if (![batchAddContext save:&error]) {
            NSLog(@"Unable to save batch added items: %@", [error localizedDescription]);
            return;
        }
        
        // Save the main thead context... saveDataWithCompletionHandler: uses the right thread
        [[self databaseManager] saveDataWithCompletionHandler:^(BOOL suceeded, NSError *error) {
            if (!suceeded) {
                NSLog(@"Core Data save failed.");
            }else{
                self.updated = YES;
            }
        }];
    }];
 
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[[self fetchedResultsController] sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = [[self fetchedResultsController] sections];
    id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Follower *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FollowerCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FollowerCell"];
    }
    [[cell textLabel] setText:object.name ];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@",object.screen_name];
    return cell;
}


#pragma mark - NSFetchedResultsControllerDelegate Methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[self tableView] beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [[self tableView] insertSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [[self tableView] deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    NSArray *newArray = nil;
    NSArray *oldArray = nil;
    
    if (newIndexPath) {
        newArray = [NSArray arrayWithObject:newIndexPath];
    }
    
    if (indexPath) {
        oldArray = [NSArray arrayWithObject:indexPath];
    }
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [[self tableView] insertRowsAtIndexPaths:newArray withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [[self tableView] deleteRowsAtIndexPaths:oldArray withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
        {
            UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];
            NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
            [[cell textLabel] setText:[object valueForKey:@"name"]];
            break;
        }
        case NSFetchedResultsChangeMove:
            [[self tableView] deleteRowsAtIndexPaths:oldArray withRowAnimation:UITableViewRowAnimationFade];
            [[self tableView] insertRowsAtIndexPaths:newArray withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [[self tableView] endUpdates];
}

@end


