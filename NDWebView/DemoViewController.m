//
//  DemoViewController.m
//  WebViewDemo
//
//  Created by NiuDu on 16/5/20.
//  Copyright © 2016年 NiuDu. All rights reserved.
//

#import "DemoViewController.h"
#import "NDWebView.h"

@interface DemoViewController ()<JMEWebViewDelegate>

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NDWebView * webView = [[NDWebView alloc]initWithFrame:self.view.bounds webViewType:JMEWebViewType_WK];
    [self.view addSubview:webView];
    
    NSURL * url = [NSURL URLWithString:@"http://www.baidu.com"];
    NSURLRequest * request = [[NSURLRequest alloc]initWithURL:url];
    [webView loadRequest:request];
    
    [webView setWebViewDelegate:self];
    
    
    [self showAlter:webView];
}

// show当前选择的webView容器
-(void)showAlter:(NDWebView *)webview{
    NSString *currentWebView;
    if ([webview.webView isKindOfClass:[WKWebView class]]) {
        currentWebView=@"WKWebView";
    }else{
        currentWebView=@"UIWebView";
        
    }
    UIAlertView *alter =[[UIAlertView alloc]initWithTitle:@"当前容器为" message:currentWebView  delegate:nil cancelButtonTitle:@"点我取消" otherButtonTitles:nil, nil];
    [alter show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark- JMEWebView delegates
- (BOOL)webView:(NDWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(JMEWebViewNavigationType)navigationType{
    NSLog(@"%s",__FUNCTION__);
    return YES;
}
- (void)webViewDidStartLoad:(NDWebView *)webView{
    NSLog(@"start");
}
- (void)webViewDidFinishLoad:(NDWebView *)webView{
    NSLog(@"finish");
}
- (void)webView:(NDWebView *)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"fail:%@",error);
}

@end
