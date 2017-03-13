//
//  UNDScrollView.h
//  UniqDay
//
//  Created by ChanLiang on 18/02/2017.
//  Copyright © 2017 ChanLiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RLMResults,UNDCard;

@interface UNDScrollView : UIView

@property (nonatomic,strong) RLMResults *models;
@property (nonatomic,strong) UNDCard *currentModel;

- (void)generateContent;

- (void)configureScorllViewWithModels;

@end
