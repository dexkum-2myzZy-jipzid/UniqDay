//
//  UNDCard+CoreDataProperties.h
//  
//
//  Created by ChanLiang on 09/01/2017.
//
//  This file was automatically generated and should not be edited.
//

#import "UNDCard+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface UNDCard (CoreDataProperties)

+ (NSFetchRequest<UNDCard *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDate *date;
@property (nullable, nonatomic, retain) NSData *image;
@property (nullable, nonatomic, copy) NSString *title;

@end

NS_ASSUME_NONNULL_END
