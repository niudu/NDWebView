//
//  JMEWebView.h
//  JDMEForIphone
//
//  Created by NiuDu on 2016/4/26.
//  Copyright © 2016年 NiuDu All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

/********
 基于UIWebView 和WKWebView 封装的webView，可根据系统版本选择使用哪种webView
 简单封装了一些常用的属性和方法,侧重WKWebView。
 个性设置可后期扩展，添加.
 ********/

typedef NS_ENUM(NSInteger,JMEWebViewType) {
    JMEWebViewType_UI = 1, //使用UIWebView 来实现
    JMEWebViewType_WK = 2, //使用WKWebView 来实现(如果系统版本已支持WKWebView)
};
typedef NS_ENUM(NSInteger,JMEWebViewNavigationType) {
    JMEWebViewNavigationTypeLinkClicked,
    JMEWebViewNavigationTypeFormSubmitted,
    JMEWebViewNavigationTypeBackForward,
    JMEWebViewNavigationTypeReload,
    JMEWebViewNavigationTypeFormResubmitted,
    JMEWebViewNavigationTypeOther
};
@class NDWebView;

/****
 代理方法，基于开发者熟悉的早期的UIWebView的代理框架
 *****/

@protocol JMEWebViewDelegate <NSObject>
@optional
- (void)webViewDidStartLoad: (NDWebView * __nullable)webView;
- (void)webViewDidFinishLoad:(NDWebView * __nullable)webView;
- (void)webView:(NDWebView * __nullable)webView didFailLoadWithError:(NSError * __nullable)error;
- (BOOL)webView:(NDWebView * __nullable)webView shouldStartLoadWithRequest:(NSURLRequest * __nullable)request navigationType:(JMEWebViewNavigationType )navigationType;
- (void)userContentController:(WKUserContentController * __nullable)userContentController didReceiveScriptMessage:(WKScriptMessage * __nullable)message;//only for WKWebView
@end

/****
 WKWebView的UIDelegate
 ****/
@protocol JMEWebViewUIDelegate <NSObject>
@optional
- (void)webView:(NDWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler;
- (void)webView:(NDWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler;
@end

@interface NDWebView : UIView

@property (nonatomic,weak)  id<JMEWebViewDelegate> webViewDelegate;
@property (nonatomic,weak)  id<JMEWebViewUIDelegate> wbUIDelegate;//WK的UI 代理
//内部使用的webView,UIWebView or WKWebView
@property (nonatomic,strong,nullable) id webView;

- (__nullable instancetype)initWithFrame:(CGRect)frame webViewType: (JMEWebViewType) type;
- (__nullable id)loadRequest:( NSURLRequest * _Nullable )request;
- (__nullable id)loadHTMLString:(NSString * _Nullable)string baseURL:(NSURL * _Nullable)baseURL;
- (__nullable id)loadData:(NSData * _Nullable)data MIMEType:(NSString * _Nullable)MIMEType textEncodingName:(NSString * _Nullable)textEncodingName baseURL:(NSURL * _Nullable)baseURL;
@property (nullable, nonatomic, readonly, copy)   NSString *title;
@property (nullable, nonatomic, readonly, copy)   NSURL *URL;
@property (nullable, nonatomic, readonly, strong) NSURLRequest *originRequest;
@property (nullable, nonatomic, readonly, strong) NSURLRequest *currentRequest;

@property (nullable, nonatomic, copy,getter = jsDataModelName)   NSString * jsDataModelName;//js注入数据的数据模型，在wkwebView 上有效
- (__nullable id)reload;
- (void)stopLoading;

- (__nullable id)goBack;
- (__nullable id)goForward;

@property (nonatomic, readonly, getter=canGoBack) BOOL canGoBack;
@property (nonatomic, readonly, getter=canGoForward) BOOL canGoForward;
@property (nonatomic, readonly, getter=isLoading) BOOL loading;

- (void)evaluateJavaScript:(NSString * _Nullable)javaScriptString completionHandler:(void (^ __nullable)(__nullable id, NSError * __nullable error))completionHandler;

@property (nonatomic) BOOL allowsInlineMediaPlayback; // defaults to YES
@property (nonatomic) BOOL allowsBackForwardNavigationGestures;// defaults to NO，对WKWebView有效
@property (nullable, nonatomic, readonly, strong) UIScrollView *scrollView;


//UIWebView 与WKWebview 设置cookie的方法不同
//@para array中存放的是需要设置的cookie值,类型为NSString类型  。domain表示设置cookie的域，UIWebView需要使用此值
- (void)setCookieWithCooksArray: (NSArray *) array domain: (NSString *) domain forRequest: (NSMutableURLRequest *) request;

////以下针对UIWebView ，如果使用的是WKWebview，相应设置无效
///是否根据视图大小来缩放页面  默认为YES
@property (nonatomic) BOOL scalesPageToFit;
//@property (nonatomic) UIDataDetectorTypes dataDetectorTypes;

@end
