//
//  UNDViewController.m
//  UniqDay
//
//  Created by ChanLiang on 28/12/2016.
//  Copyright © 2016 ChanLiang. All rights reserved.
//

//controller
#import "UNDViewController.h"

//models
#import "UNDCard.h"

//views
#import "UNDCardView.h"
#import "UNDAddCardView.h"
#import "UNDTopBarView.h"
#import "UNDToolsBar.h"
#import "UNDBottomBarView.h"
#import "UNDCardViewCell.h"

//ViewModel
#import "UNDAddCardViewModel.h"
#import "UNDCollectionViewModel.h"
#import "UNDTopBarViewModel.h"

//Vendors
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <Masonry/Masonry.h>

@interface UNDViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic,strong) UNDTopBarView *topBar;
@property (nonatomic,strong) UNDToolsBar *toolsBar;
@property (nonatomic,strong) UIView *toolsBarBgView;
@property (nonatomic,strong) UICollectionView *collectionView;
@property (nonatomic,strong) UNDBottomBarView *bottomBar;
@property (nonatomic,strong) UNDAddCardView *addCardView;
@property (nonatomic,strong) UIDatePicker *datePicker;
@property (nonatomic,strong) UIVisualEffectView *addCardBgView;

//ViewModel
@property (nonatomic,strong) UNDAddCardViewModel *addCardViewModel;
@property (nonatomic,strong) UNDCollectionViewModel *collectionViewModel;

//realm
@property (nonatomic,strong) RLMNotificationToken *token;

//constraints
@property (nonatomic,strong) NSMutableArray *antimationConstraints;

@end

@implementation UNDViewController{
    CGFloat _viewWidth;
    CGFloat _viewHeight;
    int refreshScrollViewTag;
}

@synthesize addCardView,datePicker,addCardViewModel,toolsBar;

static NSString *reuseIdentifier = @"CollectionViewCellIdentifier";

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _viewWidth  = [UIScreen mainScreen].bounds.size.width;
    _viewHeight = [UIScreen mainScreen].bounds.size.height;
    self.antimationConstraints = [NSMutableArray new];

    self.view.backgroundColor = [UIColor colorWithRed:20 green:22 blue:27 alpha:0];
    
    [self addTopBar];
    [self initColletctionView];
    [self addBottomBar];
    
    [self addRealmNotifcationObserver];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    [self.token stop];
}

#pragma mark - TopBarView & CollectionView & BottomBarView

- (void)addTopBar{
    self.topBar = [[UNDTopBarView alloc]init];
    [self.view addSubview:self.topBar];
    [self.topBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(16);
        make.width.mas_equalTo(_viewWidth);
        make.height.mas_equalTo(36);
    }];
    
    self.topBar.allBtn.rac_command = [[RACCommand alloc]initWithSignalBlock:^RACSignal *(id input) {
        [self showToolBar];
        return [RACSignal empty];
    }];
}

- (void)initColletctionView{
    if (self.collectionView == nil) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
        flowLayout.scrollDirection             = UICollectionViewScrollDirectionHorizontal;
        flowLayout.minimumLineSpacing          = 40;
        flowLayout.sectionInset                = UIEdgeInsetsMake(16, 20, 16, 20);
        flowLayout.itemSize                    = CGSizeMake(_viewWidth - 40, _viewHeight - 32 - 120);
        self.collectionView = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        self.collectionView.delegate           = self;
        self.collectionView.dataSource         = self;
        self.collectionView.pagingEnabled      = YES;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        [self.collectionView registerClass:[UNDCardViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
        [self.view addSubview:self.collectionView];

        //bind viewModel
        self.collectionViewModel = [[UNDCollectionViewModel alloc]init];
        
        CGFloat collectionViewHeight = _viewHeight - 120;
        [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            self.antimationConstraints = [NSMutableArray arrayWithArray:@[
            make.top.equalTo(self.topBar.mas_bottom).offset(8)]];
            make.left.equalTo(self.view);
            make.width.equalTo(self.view);
            make.height.mas_equalTo(@(collectionViewHeight));
        }];
    }
}

- (void)addBottomBar{
    self.bottomBar = [[UNDBottomBarView alloc]init];
    [self.view addSubview:self.bottomBar];
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.collectionView.mas_bottom).offset(8);
        make.width.mas_equalTo(_viewWidth);
        make.height.mas_equalTo(44);
    }];
    
    [self.bottomBar.rac_addCardSignal subscribeNext:^(id x) {
        [self showAddCardView];
    }];
    
    [self.bottomBar.rac_dayCountOrder subscribeNext:^(id x) {
        [self.collectionViewModel sortByDate];
        [self.collectionView reloadData];
    }];
    
    [self.bottomBar.rac_CreatedDateOder subscribeNext:^(id x) {
        [self.collectionViewModel sortByCreatedDay];
        [self.collectionView reloadData];
    }];
}

#pragma mark - ToolBar

- (void)showToolBar{
    
    self.toolsBarBgView                 = [[UIView alloc]init];
    self.toolsBarBgView.backgroundColor = [UIColor clearColor];
    UITapGestureRecognizer *tap         = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideToolsBar)];
    [self.toolsBarBgView addGestureRecognizer:tap];
    [self.view addSubview:self.toolsBarBgView];
    [self.toolsBarBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    self.topBar.alpha         = 0.2;
    self.collectionView.alpha = 0.2;
    self.bottomBar.alpha      = 0.2;

    for (MASConstraint *constraint in self.antimationConstraints) {
        constraint.offset     = 100;
    }

    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];

    self.toolsBar = [[UNDToolsBar alloc]init];
    [self.toolsBarBgView addSubview:toolsBar];

    [self.toolsBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topBar.mas_bottom);
        make.width.equalTo(self.toolsBarBgView);
        make.height.equalTo(@100);
    }];
    
    self.toolsBar.editBtn.rac_command = [[RACCommand alloc]initWithSignalBlock:^RACSignal *(id input) {
        
        return [RACSignal empty];
    }];
    
}

- (void)hideToolsBar{
    
    for (MASConstraint *constraint in self.antimationConstraints) {
        constraint.offset = 8;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.toolsBar.frame = CGRectMake(0, 60, _viewWidth, 0);
        [self.toolsBar hideButtons];
        [self.view layoutSubviews];
    } completion:^(BOOL finished) {
        [self.toolsBar removeButtons];
        [self.toolsBar removeFromSuperview];
        self.toolsBar = nil;
        [self.toolsBarBgView removeFromSuperview];
        self.toolsBarBgView = nil;
        self.topBar.alpha = 1;
        self.bottomBar.alpha = 1;
        self.collectionView.alpha = 1;
    }];
}

#pragma mark - BottomBarView

#pragma mark - AddCardView 

- (void)showAddCardView{
    
    [self showAddCardViewBackgroundView];
    
    CGRect addCardViewFrame0 = CGRectMake(8, _viewHeight - 264, _viewWidth - 16, 256);
    CGRect addCardViewFrame1 = CGRectMake(8, _viewHeight, _viewWidth - 16, 256);
    
    if (self.addCardView == nil) {
        self.addCardView = [[UNDAddCardView alloc]initWithFrame:addCardViewFrame1];
        [self.view addSubview:self.addCardView];
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        self.addCardView.frame = addCardViewFrame0;
    } completion:^(BOOL finished) {
        //rac -- notification
        [[[NSNotificationCenter defaultCenter] rac_addObserverForName:kRaiseAddCardViewNotification object:nil]
         subscribeNext:^(NSNotification *notification) {
             [self raiseAddCardView];
         }];
        
        [[[NSNotificationCenter defaultCenter] rac_addObserverForName:kRaiseDatePickerNotification object:nil]
         subscribeNext:^(NSNotification *notification) {
             [self raiseDatePicker];
         }];
        
        [[[NSNotificationCenter defaultCenter] rac_addObserverForName:kAddImageNotification object:nil]
         subscribeNext:^(id x) {
             //add image action
         }];
        
        //rac
        [[self.addCardView cancelSignal] subscribeNext:^(id x) {
            [self dismissAddCardView];
        }];
        
        [[self.addCardView rac_doneSignal] subscribeNext:^(id x) {
            [self addCardModelResult];
        }];
        
        
        //init addCardViewModel
        self.addCardViewModel = [[UNDAddCardViewModel alloc]init];
        self.addCardViewModel.title = nil;
        self.addCardViewModel.date  = nil;
        self.addCardViewModel.image = nil;

        RAC(self.addCardViewModel,title) = self.addCardView.rac_titleSignal;
        RAC(self.addCardViewModel,image) = self.addCardView.rac_imageSignal;
    }];
}


- (void)raiseAddCardView{
    
    CGPoint orignialCenter = self.addCardView.center;
    
    CGFloat height = 216;
    CGFloat top = [UIScreen mainScreen].bounds.size.height - height;
    
    [self dismissDatePicker];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.addCardView.center = CGPointMake(orignialCenter.x, top - 178);
    }];
}

- (void)dismissAddCardView{
    
    [self.addCardView dismissKeyboard];
    [self dismissDatePicker];
    [self dimissAddCardViewBackgroundView];
    
    //dismiss AddCardView
    [UIView animateWithDuration:0.3 animations:^{
        CGPoint center0 = self.addCardView.center;
        CGFloat centerY = [UIScreen mainScreen].bounds.size.height + self.addCardView.frame.size.height/2;
        self.addCardView.center = CGPointMake(center0.x, centerY);
    } completion:^(BOOL finished) {
        [self.addCardView removeFromSuperview];
        self.addCardView = nil;
    }];
}

#pragma mark - Date Picker

- (void)raiseDatePicker{
    
    [self.addCardView dismissKeyboard];
    
    CGRect addCardViewFrame0 = self.addCardView.frame;
    
    CGFloat height = 216;
    CGFloat top = [UIScreen mainScreen].bounds.size.height - height;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.addCardView.frame = CGRectMake(addCardViewFrame0.origin.x,top - 264, addCardViewFrame0.size.width, addCardViewFrame0.size.height);
    }];
    
    if (self.datePicker == nil) {
        self.datePicker = [[UIDatePicker alloc]init];
        self.datePicker.backgroundColor = [UIColor whiteColor];
        self.datePicker.datePickerMode = UIDatePickerModeDate;
        self.datePicker.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT+0800"];
        [self.view addSubview:self.datePicker];
        
        [self.datePicker mas_makeConstraints:^(MASConstraintMaker *make) {
            UIEdgeInsets insets = UIEdgeInsetsMake(top, 0, 0, 0);
            make.edges.equalTo(self.view).insets(insets);
        }];
        
        NSIndexPath *indePath = [NSIndexPath indexPathForRow:1 inSection:0];
        UNDDateTableViewCell *cell = [self.addCardView.tableView cellForRowAtIndexPath:indePath];
        [cell.dateBtn setTitle:[self dateToDateStr:[NSDate date]] forState:UIControlStateNormal];
         [cell.dateBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.addCardViewModel.date = self.datePicker.date;

        [[self.datePicker rac_newDateChannelWithNilValue:[NSDate date]]
         subscribeNext:^(NSDate *date) {
             NSString *dateStr = [self dateToDateStr:date];
             [cell.dateBtn setTitle:dateStr forState:UIControlStateNormal];
             self.addCardViewModel.date = date;
         }];
    }
}

- (NSString *)dateToDateStr:(NSDate *)date{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateStyle = kCFDateFormatterMediumStyle;
    NSString *dateStr = [dateFormatter stringFromDate:date];
    return dateStr;
}

- (void)dismissDatePicker{
    if (self.datePicker != nil) {
        [UIView animateWithDuration:0.2 animations:^{
            CGPoint center0 = self.datePicker.center;
            CGFloat centerY = [UIScreen mainScreen].bounds.size.height + self.datePicker.frame.size.height/2;
            self.datePicker.center = CGPointMake(center0.x, centerY);
        } completion:^(BOOL finished) {
            [self.datePicker removeFromSuperview];
            self.datePicker = nil;
        }];
    }
}

#pragma mark - AddCardViewBackgroundView

- (void)showAddCardViewBackgroundView{
    //Blur Effect
    if (self.addCardBgView == nil) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        self.addCardBgView       = [[UIVisualEffectView alloc]initWithEffect:blurEffect];
        self.addCardBgView.frame = self.view.frame;
        [self.view addSubview:self.addCardBgView];
    }
}

- (void)dimissAddCardViewBackgroundView{
    if (self.addCardBgView != nil) {
        [UIView animateWithDuration:0.1 animations:^{
            self.addCardBgView.center = CGPointMake(_viewWidth/2.0, _viewHeight * 1.5);
        }completion:^(BOOL finished) {
            [self.addCardBgView removeFromSuperview];
            self.addCardBgView = nil;
        }];
    }
}


#pragma mark - Realm

- (void)addRealmNotifcationObserver{
    __weak typeof(self) weakSelf = self;
    self.token = [[UNDCard allObjects] addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Failed to open Realm on background worker: %@", error);
            return;
        }
        
        if (!change) {
            return;
        }
        
        [weakSelf.collectionView reloadData];
    }];
}

#pragma mark - else

- (void)addCardModelResult{
    UNDAddCardModelResult result = [self.addCardViewModel addCardModel];
    NSString *message;
    switch (result) {
        case UNDAddCardModelTitleFailure:
            message = NSLocalizedString(@"Please Enter Title!", nil);
            break;
        case UNDAddCardModelDateFailure:
            message = NSLocalizedString(@"Please Enter Date!", nil);
            break;
        case UNDAddCardModelImageFailure:
            message = NSLocalizedString(@"Please Add Image!", nil);
            break;
        case UNDAddCardModelSuccess:
            [self dismissAddCardView];
            break;
    }
    
    if (result != UNDAddCardModelSuccess) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *done = [UIAlertAction actionWithTitle:NSLocalizedString(@"Done", nil) style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:done];
        [self presentViewController:alert animated:YES completion:nil];
    }
}


#pragma mark - UICollectionViewDelegate & DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.collectionViewModel.cellViewModels.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    UNDCardViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.viewModel = self.collectionViewModel.cellViewModels[indexPath.item];
    return cell;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    CGFloat contentOffsetX = scrollView.contentOffset.x;
    int index = contentOffsetX/_viewWidth + 1;
    NSString *indexStr = [NSString stringWithFormat:@"%d/%lu",index,(unsigned long)[UNDCard allObjects].count];
    self.topBar.viewModel.indexStr = indexStr;
}

@end
