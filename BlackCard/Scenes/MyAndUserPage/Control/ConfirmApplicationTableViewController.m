//
//  ConfirmApplicationTableViewController.m
//  BlackCard
//
//  Created by abx’s mac on 2017/4/25.
//  Copyright © 2017年 abx’s mac. All rights reserved.
//

#import "ConfirmApplicationTableViewController.h"
#import "HomePageModel.h"
#import "PayModel.h"
#import "PayManagerHelper.h"
#define kButtonRePayAction 999

@interface ConfirmApplicationTableViewController ()<PayHelperDelegate>
@property (weak, nonatomic) IBOutlet UILabel *cardTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *customizeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *trueNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *addLabel;
@property (weak, nonatomic) IBOutlet UIButton *serviceButton;
@property (weak, nonatomic) IBOutlet UIButton *registerPayButton;
@property (weak, nonatomic) IBOutlet UILabel *payMoneyLabel;
@property (strong,nonatomic)NSDictionary *tokenDic;
@property(strong,nonatomic)RegisterModel *model;


@end

@implementation ConfirmApplicationTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self buttonSetting];
    [self contentFillSetting];
    [[PayManagerHelper shared] setDelegate:self];
}


- (void)buttonSetting {
    
    UIFont *font = [UIFont systemFontOfSize:12];
    
    NSMutableAttributedString *baseStr = [[NSMutableAttributedString alloc]initWithString:@"我已经完全阅读并同意" attributes:@{NSFontAttributeName : font,NSForegroundColorAttributeName:kUIColorWithRGB(0xA6A6A6)}];
    [baseStr appendAttributedString:[[NSAttributedString alloc]initWithString:@"《精英黑卡会籍服务章程》" attributes:@{NSFontAttributeName : font,NSForegroundColorAttributeName:kUIColorWithRGB(0xE3A63F)}]];
    [self.serviceButton setAttributedTitle:baseStr forState:UIControlStateNormal];
    
}


- (void)contentFillSetting{
    
    self.cardTypeLabel.text = [NSString stringWithFormat:@"黑卡会籍：%@",_model.cardModel.blackcardName];
    self.customizeNameLabel.text = [NSString stringWithFormat:@"定制姓名：%@",_model.customName];
    self.trueNameLabel.text = [NSString stringWithFormat:@"收件人：%@",_model.fullName];
    self.phoneLabel.text = [NSString stringWithFormat:@"联系电话：%@",_model.phoneNum];
    self.addLabel.text =  [NSString stringWithFormat:@"收件地址：%@-%@-%@",_model.province,_model.city,_model.addr] ;
    
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc]initWithString:@"支付金额：" attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12],NSForegroundColorAttributeName : kUIColorWithRGB(0x434343)}];
    
    CGFloat payMoney = _model.cardModel.blackcardPrice +  ([NSString isEmpty:_model.customName] ? 0 : 60.0);
    [string appendAttributedString:[[NSAttributedString alloc]initWithString:[NSString stringWithFormat:@"¥%.2f",payMoney] attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:13],NSForegroundColorAttributeName : kUIColorWithRGB(0xE3A63F)}]];
    
    self.payMoneyLabel.attributedText = string;
    
    
}
- (IBAction)registerButtonAction:(UIButton *)sender {
    
    if (_tokenDic == nil) {
        [self registerWithHttp];
    }else {
        
        [self payWithDic:_tokenDic];
    }
    
 
    
    
}


- (void)registerWithHttp {
    
    NSError *error = nil;
    NSDictionary *dic = [OEZJsonModelAdapter jsonDictionaryFromModel:_model error:&error];
    [self showLoader:@"注册中..."];
    WEAKSELF
    
    [[AppAPIHelper shared].getMyAndUserAPI registerWithRegisterModel:dic complete:^(id data) {
        [weakSelf showLoader:@"注册成功,等待支付"];
        weakSelf.tokenDic  = data;
        
        [weakSelf payWithDic:data];
        
    } error:^(NSError *error) {
        [weakSelf showError:error];

        if (error.code == 10017) {
            [weakSelf lastPayWihtPush];
            
        }
        
        
    }];
    
}


- (void)payWithDic:(NSDictionary *)dic {
    WEAKSELF
    if (_tokenDic ) {
        [self showLoader:@"支付中..."];
    }
    
    [[AppAPIHelper shared].getMyAndUserAPI registerWithPay:dic complete:^(PayInfoModel *model) {
        [weakSelf hiddenProgress];
        [[PayManagerHelper shared].wxPay payWithWXModel:model.wxPayInfo];
        [[BlackLogHelper shared] setPayDic:@{@"event" : @"register_pay",@"amount" : @(model.payTotalPrice),@"payType":@(model.payType),@"tradeNo":model.tradeNo}];
        
    } error:^(NSError *error) {
        [weakSelf showError:error];
        [weakSelf payButtonSetting];
    }];
    
    
}

- (void)payButtonSetting {
    self.registerPayButton.tag =  kButtonRePayAction;
    [self.registerPayButton setTitle:@"重新支付" forState:UIControlStateNormal];
    
}



- (void)payHelperWithType:(PayType)type withPayStatus:(PayStatus)payStatus withData:(id)data {
    [self LogPayStatus:payStatus withData:data];
    switch (payStatus) {
        case PayError: {  //支付失败
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"支付失败" message:@"请重新支付" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [alert show];
            [self payButtonSetting];
        }
            break;
        case PayOK:{ //支付成功
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"支付成功" message:@"" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
            WEAKSELF
            [alert showWithCompleteBlock:^(NSInteger buttonIndex) {
                [weakSelf.navigationController  dismissViewControllerAnimated:YES completion:nil];
                
                
            }];
            
            
            
        }
            break;
        case PayCancel:{//支付取消
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"支付已取消" message:@"" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [alert show];
            [self payButtonSetting];
        }
            break;
        default:{
            if ([data isKindOfClass:[NSString class]]) {
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"支付出错" message:data delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
                [alert show];
                [self payButtonSetting];
            }
            
        }
            break;

    }

}



- (void)lastPayWihtPush {
    
    WEAKSELF
    [self pushStoryboardViewControllerIdentifier:@"ResetPayTableViewController" block:^(UIViewController *viewController) {
         [viewController  setValue:weakSelf.model.phoneNum forKey:@"phoneNum"];
    }];

    
    
    
}
- (IBAction)showWedAction:(UIButton *)sender {
    
    [self pushWithIdentifier:@"WebViewController" complete:^(UIViewController *controller) {
        [controller setValue:kHttpAPIUrl_userAgreement forKey:@"url"];
        [controller setValue:@"《精英黑卡会籍服务章程》" forKey:@"webTitle"];
    }];
    
}

- (void)LogPayStatus:(PayStatus)payStatus withData:(id)data{
    
    NSString *returnCode = payStatus == PayOK ? @"0" : @"2";
    returnCode =  payStatus == PayCancel ?  @"1" : returnCode;
    NSString *memo = [data isKindOfClass:[NSString  class]] ? data : @"";
    [[BlackLogHelper shared] addOtherPayInformationWithPost:@{@"returnCode":returnCode,@"returnMsg":memo}];
}

@end
