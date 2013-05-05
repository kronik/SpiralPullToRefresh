//
//  DataViewController.m
//  Spiral Pull Demo
//
//  Created by Dmitry Klimkin on 5/5/13.
//  Copyright (c) 2013 Dmitry Klimkin. All rights reserved.
//

#import "DataViewController.h"
#import "UIScrollView+SpiralPullToRefresh.h"

@interface DataViewController ()

@property (nonatomic, strong) NSTimer *workTimer;
@property (nonatomic, strong) NSMutableArray *items;

@end

@implementation DataViewController

@synthesize workTimer = _workTimer;
@synthesize items = _items;

- (NSMutableArray *)items {
    if (_items == nil) {
        _items = [NSMutableArray new];
    }
    return _items;
}

- (void)statTodoSomething {
    
    [self.workTimer invalidate];
    
    self.workTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(onAllworkDoneTimer) userInfo:nil repeats:NO];
}

- (void)onAllworkDoneTimer {
    [self.workTimer invalidate];
    self.workTimer = nil;
    
    [self.items addObject: [NSNumber numberWithInt: self.items.count]];
    
    [self.tableView.pullToRefreshController didFinishRefresh];
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    __typeof (&*self) __weak weakSelf = self;
    
    [self.tableView addPullToRefreshWithActionHandler:^ {         
         int64_t delayInSeconds = 1.0;
         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
         dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
             [weakSelf refreshTriggered];
         });
     }];
    
    // Three type of waiting animations available now: Random, Linear and Circular
    self.tableView.pullToRefreshController.waitingAnimation = SpiralPullToRefreshWaitAnimationCircular;
}

- (void)refreshTriggered {
    [self statTodoSomething];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"DataTableCellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = [NSString stringWithFormat: @"%d", [self.items[self.items.count - indexPath.row - 1] intValue]];
    
    return cell;
}

@end
