//
//  ChoosePayHandle.h
//  BlackCard
//
//  Created by abx’s mac on 2017/5/27.
//  Copyright © 2017年 abx’s mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChoosePayHandle : NSObject


- (instancetype)initWithController:(UIViewController *)controller andModel:(id)model;
- (void)handleShow;
@end
