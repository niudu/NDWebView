//
//  JMEWebView.m
//  JDMEForIphone
//
//  Created by NiuDu on 2016/4/26.
//  Copyright © 2016年 NiuDu. All rights reserved.
//

#import "NDWebView.h"

@interface NDWebView()<UIWebViewDelegate,WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler>{
}
@property (nonatomic,assign)  JMEWebViewType type;
@property (nonatomic,assign)  BOOL           isWK;//webView是否为WKWebView
@property (nonatomic, copy)   NSString     * title;

@property (nonatomic, strong) NSMutableURLRequest * originRequest;
@property (nonatomic, strong) NSMutableURLRequest * currentRequest;

@property (nonatomic, strong) NSURL       * lastCancelURL;//errorCode = -999时，重复加载一次，避免循环，只重复加载一次


- (JMEWebViewNavigationType)changeNavitationTypeWithType: (NSInteger) type;

@end

@implementation NDWebView
- (void)dealloc
{
    if(_isWK)
    {
       
        WKWebView* webView = _webView;
        webView.UIDelegate = nil;
        webView.navigationDelegate = nil;
        
        [webView removeObserver:self forKeyPath:@"title"];
    }
    else
    {
        UIWebView* webView = _webView;
        webView.delegate = nil;
    }
    [_webView scrollView].delegate = nil;
    [_webView stopLoading];
//    [(UIWebView*)_webView loadHTMLString:@"" baseURL:nil];
    [_webView stopLoading];
    [_webView removeFromSuperview];
    _webView = nil;

}
- (instancetype)init{
    return [self initWithFrame:self.bounds webViewType:JMEWebViewType_WK];
}
- (instancetype)initWithFrame:(CGRect)frame{
    return [self initWithFrame:frame webViewType:JMEWebViewType_WK];
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        _allowsBackForwardNavigationGestures = NO;
        _allowsInlineMediaPlayback           = YES;
        [self setBackgroundColor:[UIColor whiteColor]];
        [self initWKWebView];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame webViewType: (JMEWebViewType) type{
    self = [super initWithFrame:frame];
    if (self) {
        _type = type;
        _allowsBackForwardNavigationGestures = NO;
        _allowsInlineMediaPlayback           = YES;
        [self setBackgroundColor:[UIColor whiteColor]];
        if (_type == JMEWebViewType_WK) {
            [self initWKWebView];
        }else{
            [self initUIWebView];
        }
    }
    return self;
}

- (void)initWKWebView{
    WKWebViewConfiguration* config = [[NSClassFromString(@"WKWebViewConfiguration") alloc] init];
    config.preferences = [[NSClassFromString(@"WKPreferences") alloc] init];
    config.preferences.minimumFontSize = 10;
    config.preferences.javaScriptEnabled = YES;
    config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
    config.userContentController = [[NSClassFromString(@"WKUserContentController")  alloc] init];
    WKWebView * webView = [[NSClassFromString(@"WKWebView") alloc]initWithFrame:self.bounds configuration:config];
    [webView setNavigationDelegate:self];
    [webView setUIDelegate:self];
    [self addSubview:webView];
    [webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    [[webView configuration] setAllowsInlineMediaPlayback:YES];
    [webView setAllowsBackForwardNavigationGestures:NO];
    
    _webView = webView;
    _isWK = YES;
    if (!_webView) {
        [self initUIWebView];
    }
}
- (void)initUIWebView{
    UIWebView * webView = [[UIWebView alloc]initWithFrame:self.bounds];
    [self addSubview:webView];
    _webView = webView;
    [webView setDelegate:self];
    [webView setScalesPageToFit:YES];
    [webView setAllowsInlineMediaPlayback:YES];
    
    _isWK = NO;
}
- (void)setCookieWithCooksArray: (NSArray *) array domain: (NSString *) domain forRequest: (NSMutableURLRequest *) request{
    
    __block NSString * cookieForDocument = @"";
    __block NSString * cookieForHeader   = @"";
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            if (_isWK) {
                cookieForDocument = [cookieForDocument stringByAppendingString:[NSString stringWithFormat:@"document.cookie = '%@';",obj]];
                cookieForHeader = [cookieForHeader stringByAppendingString:[NSString stringWithFormat:@"%@;",obj]];
            }else{
                NSHTTPCookie *cookie_temp = [NSHTTPCookie cookieWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:obj, NSHTTPCookieName,
                                                                                @"", NSHTTPCookieValue,
                                                                                domain, NSHTTPCookieDomain,
                                                                                @"/", NSHTTPCookiePath,
                                                                                [NSDate distantFuture], NSHTTPCookieExpires,
                                                                                nil]];
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie_temp];
                
            }

        }
    }];
    if (_isWK) {
        if ([cookieForHeader hasSuffix:@";"]) {
            cookieForHeader = [cookieForHeader substringToIndex:cookieForHeader.length-1];
        }
        
        [request addValue:cookieForHeader forHTTPHeaderField:@"Cookie"];
        if ([cookieForDocument hasSuffix:@";"]) {
            cookieForDocument = [cookieForDocument substringToIndex:cookieForDocument.length-1];
        }
        NSLog(@"cookieForHeader=======%@",cookieForHeader);
        NSLog(@"cookieForDocument======%@",cookieForDocument);
        WKUserScript * cookieScript = [[WKUserScript alloc]initWithSource:cookieForDocument injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
            [((WKWebView *)self.webView).configuration.userContentController addUserScript:cookieScript];
    }
}

- (JMEWebViewNavigationType)changeNavitationTypeWithType: (NSInteger) type {
    switch (type) {
        case UIWebViewNavigationTypeLinkClicked |WKNavigationTypeLinkActivated :
            return JMEWebViewNavigationTypeLinkClicked;
        case UIWebViewNavigationTypeFormSubmitted | WKNavigationTypeFormSubmitted:
            return JMEWebViewNavigationTypeFormSubmitted;
        case UIWebViewNavigationTypeFormResubmitted | WKNavigationTypeFormResubmitted:
            return JMEWebViewNavigationTypeFormResubmitted;
        case UIWebViewNavigationTypeBackForward | WKNavigationTypeBackForward:
            return JMEWebViewNavigationTypeBackForward;
        case UIWebViewNavigationTypeReload|WKNavigationTypeReload:
            return JMEWebViewNavigationTypeReload;
        default:
            return JMEWebViewNavigationTypeOther;
    }
    
}
- (void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    [_webView setFrame:self.bounds];
}
#pragma mark - WKWebView&&UIWebView delegates
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    if ([message.name isEqualToString:_jsDataModelName]) {
        [self jm_userContentController:userContentController didReceiveScriptMessage:message];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    JMEWebViewNavigationType type = [self changeNavitationTypeWithType:navigationAction.navigationType];
    BOOL result = [self jm_webViewShouldStartLoadWithRequest:navigationAction.request navigationType:type];
    if(result){
        NSLog(@"--------------%@,%@,navigationType==%ld",navigationAction.targetFrame,navigationAction.sourceFrame,(long)navigationAction.navigationType);
       
        self.currentRequest  = navigationAction.request;
        
        NSString *scheme = navigationAction.request.URL.scheme.lowercaseString;
    
        if ((navigationAction.navigationType == WKNavigationTypeLinkActivated || navigationAction.navigationType == WKNavigationTypeOther )&& ![scheme hasPrefix:@"http"]) {
            [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
            decisionHandler(WKNavigationActionPolicyCancel);

        }else{
            decisionHandler(WKNavigationActionPolicyAllow);
        }

    }
    else
    {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    [self jm_webViewDidStartLoad];
}


- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"---------------iiiiiiiiiiiiiiii---");
    NSURL * url = [error.userInfo valueForKey:@"NSErrorFailingURLKey"];
    NSString * string = [NSString stringWithFormat:@"%@",url];
    NSLog(@"%@",string);

    if ([error code] == NSURLErrorCancelled && ![string hasSuffix:@".html"]) {
        if (![self.lastCancelURL isEqual:url] && [url isKindOfClass:[NSURL class]] ) {
            NSURLRequest * tempReqest = [[NSURLRequest alloc]initWithURL:[error.userInfo valueForKey:@"NSErrorFailingURLKey"] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
            [webView loadRequest:tempReqest];
            NSLog(@"取消加载，重复加载一次");
        }
    }else{
        [self jm_webViewDidFailLoadWithError:error];
    }
    self.lastCancelURL = url;

}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    self.lastCancelURL = nil;
    [self jm_webViewDidFinishLoad];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    [self jm_webViewDidFailLoadWithError:error];
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    [self jm_webViewRunJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
       NSLog(@"%@", message);
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    [self jm_webViewRunJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
       
    NSLog(@"%@", message);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    JMEWebViewNavigationType type = [self changeNavitationTypeWithType:navigationType];
    BOOL result = [self jm_webViewShouldStartLoadWithRequest:request navigationType:type];
    return result;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    [self jm_webViewDidStartLoad];
}
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if(self.originRequest == nil)
    {
        self.originRequest = webView.request;
    }
    
    [self jm_webViewDidFinishLoad];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(nullable NSError *)error{
    if ([error code] == NSURLErrorCancelled) return;
    [self jm_webViewDidFailLoadWithError:error];
}

#pragma mark - 回调方法
- (void)jm_webViewDidStartLoad{
    if (_webViewDelegate && [_webViewDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [_webViewDelegate webViewDidStartLoad:self];
    }
}
- (void)jm_webViewDidFinishLoad{
    if (_webViewDelegate && [_webViewDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [_webViewDelegate webViewDidFinishLoad:self];
    }
}
- (void)jm_webViewDidFailLoadWithError:(NSError * __nullable)error{
//    if([error code] == NSURLErrorCancelled) return;

    if (_webViewDelegate && [_webViewDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [_webViewDelegate webView:self didFailLoadWithError:error];
    }
}
- (BOOL)jm_webViewShouldStartLoadWithRequest:(NSURLRequest * __nullable)request navigationType:(JMEWebViewNavigationType )navigationType{
    if (_webViewDelegate && [_webViewDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]){
        return [_webViewDelegate webView:self shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    return YES;
}
//only for WKWebView
- (void)jm_userContentController:(WKUserContentController * __nullable)userContentController didReceiveScriptMessage:(WKScriptMessage * __nullable)message{
    if (_webViewDelegate && [_webViewDelegate respondsToSelector:@selector(userContentController:didReceiveScriptMessage:)]) {
        [_webViewDelegate userContentController:userContentController didReceiveScriptMessage:message];
    }
}
- (void)jm_webViewRunJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    if (_wbUIDelegate && [_wbUIDelegate respondsToSelector:@selector(webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [_wbUIDelegate webView:self runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }
}
- (void)jm_webViewRunJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler{
    if (_wbUIDelegate &&[_wbUIDelegate respondsToSelector:@selector(webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [_wbUIDelegate webView:self runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    }
}

#pragma mark - 属性方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"title"]) {
        self.title = change[NSKeyValueChangeNewKey];
    }
}
- (void)setJsDataModelName: (NSString *) jsDataModelName{
    if (jsDataModelName.length > 0 && [_jsDataModelName isEqualToString:jsDataModelName] && _webView && [_webView isMemberOfClass:[WKWebView class]]) {
        [((WKWebView *)_webView).configuration.userContentController addScriptMessageHandler:self name:jsDataModelName];
        _jsDataModelName = jsDataModelName;
    }else{
        _jsDataModelName = nil;
    }
}
- (NSURL *) URL{
    if (_isWK) {
        return [(WKWebView*)_webView URL];
    }else{
        return [[(UIWebView *)_webView request]URL];
    }
}
- (NSURLRequest *) originRequest{
    if (_isWK) {
        return _originRequest;
    }else{
        return [(UIWebView *)_webView request];
    }
}
- (NSURLRequest *)currentRequest{
    if (_isWK) {
        return _currentRequest;
    }else{
        return [(UIWebView *)_webView request];
    }
}
- (BOOL)canGoBack{
    return [_webView canGoBack];
}
- (BOOL)canGoForward{
    return [_webView canGoForward];
}
- (BOOL)isLoading{
    return [_webView isLoading];
}

- (void)setAllowsInlineMediaPlayback:(BOOL)allowsInlineMediaPlayback{
    if (allowsInlineMediaPlayback != _allowsInlineMediaPlayback) {
        if (_isWK) {
            [[(WKWebView *)_webView configuration] setAllowsInlineMediaPlayback:allowsInlineMediaPlayback];
        }else{
            [(UIWebView *)_webView setAllowsInlineMediaPlayback:allowsInlineMediaPlayback];
        }
        _allowsBackForwardNavigationGestures = allowsInlineMediaPlayback;
    }
}
- (void)setAllowsBackForwardNavigationGestures:(BOOL)allowsBackForwardNavigationGestures{
    if (_isWK && _allowsBackForwardNavigationGestures != allowsBackForwardNavigationGestures) {
        [(WKWebView *)_webView setAllowsBackForwardNavigationGestures:allowsBackForwardNavigationGestures];
        _allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures;
    }
}
- (UIScrollView *)scrollView{
    return [_webView scrollView];
}
- (void)setScalesPageToFit:(BOOL)scalesPageToFit{
    if(!_isWK)
        ((UIWebView *)_webView).scalesPageToFit = scalesPageToFit;
    else
    {
        if(_scalesPageToFit == scalesPageToFit)
        {
            return;
        }
        
        WKWebView* webView = _webView;
        
        NSString *jScript = @"var meta = document.createElement('meta'); \
        meta.name = 'viewport'; \
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'; \
        var head = document.getElementsByTagName('head')[0];\
        head.appendChild(meta);";
        
        if(scalesPageToFit)
        {
            WKUserScript *wkUScript = [[NSClassFromString(@"WKUserScript") alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
            [webView.configuration.userContentController addUserScript:wkUScript];
        }
        else
        {
            NSMutableArray* array = [NSMutableArray arrayWithArray:webView.configuration.userContentController.userScripts];
            for (WKUserScript *wkUScript in array)
            {
                if([wkUScript.source isEqual:jScript])
                {
                    [array removeObject:wkUScript];
                    break;
                }
            }
            for (WKUserScript *wkUScript in array)
            {
                [webView.configuration.userContentController addUserScript:wkUScript];
            }
        }
    }
    
    _scalesPageToFit = scalesPageToFit;

}
#pragma mark - 公共接口
- (__nullable id)loadRequest:(NSURLRequest *)request{
    self.originRequest  = request;
    self.currentRequest = request;
    
    if (_isWK) {
        return [(WKWebView *)_webView loadRequest:request];
    }else{
        [(UIWebView *)_webView loadRequest:request];
        return nil;
    }
}
- (__nullable id)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL{
    if (_isWK) {
        return [(WKWebView *)_webView loadHTMLString:string baseURL:baseURL];
    }else{
        [(UIWebView *)_webView loadHTMLString:string baseURL:baseURL];
        return nil;
    }
}

- (__nullable id)loadData:(NSData *)data MIMEType:(NSString *)MIMEType textEncodingName:(NSString *)textEncodingName baseURL:(NSURL *)baseURL{
    if (_isWK && [(WKWebView *)_webView respondsToSelector:@selector(loadData:MIMEType:characterEncodingName:baseURL:)]) {
        return [(WKWebView *)_webView loadData:data MIMEType:MIMEType characterEncodingName:textEncodingName baseURL:baseURL];
    }else{
        [(UIWebView *)_webView loadData:data MIMEType:MIMEType textEncodingName: textEncodingName baseURL:baseURL];
        return nil;
    }
}

- (__nullable id)reload{
    if (_isWK) {
        return [(WKWebView *)_webView reload];
    }else{
        [(UIWebView *)_webView reload];
        return nil;
    }
}
- (void)stopLoading{
   [_webView stopLoading];
}

- (__nullable id)goBack{
    if (_isWK) {
        return [(WKWebView *)_webView goBack];
    }else{
        [(UIWebView *)_webView goBack];
        return nil;
    }
}
- (__nullable id)goForward{
    if (_isWK) {
        return [(WKWebView *)_webView goForward];
    }else{
        [(UIWebView *)_webView goForward];
        return nil;
    }
}
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ __nullable)(__nullable id, NSError * __nullable error))completionHandler{
    if (_isWK) {
        [(WKWebView *)_webView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
    }else{
        NSString * resustString = [(UIWebView *)_webView stringByEvaluatingJavaScriptFromString:javaScriptString];
        if (completionHandler) {
            completionHandler(resustString,nil);
        }
    }
}

#pragma mark-  未实现方法的容错
-(BOOL)respondsToSelector:(SEL)aSelector
{
    BOOL hasResponds = [super respondsToSelector:aSelector];
    if(hasResponds == NO)
    {
        hasResponds = [self.webViewDelegate respondsToSelector:aSelector];
    }
    if(hasResponds == NO)
    {
        hasResponds = [self.webView respondsToSelector:aSelector];
    }
    return hasResponds;
}
- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature* methodSign = [super methodSignatureForSelector:selector];
    if(methodSign == nil)
    {
        if([self.webView respondsToSelector:selector])
        {
            methodSign = [self.webView methodSignatureForSelector:selector];
        }
        else
        {
            methodSign = [(id)self.webViewDelegate methodSignatureForSelector:selector];
        }
    }
    return methodSign;
}
- (void)forwardInvocation:(NSInvocation*)invocation
{
    if([self.webView respondsToSelector:invocation.selector])
    {
        [invocation invokeWithTarget:self.webView];
    }
    else
    {
        [invocation invokeWithTarget:self.webViewDelegate];
    }
}
@end
