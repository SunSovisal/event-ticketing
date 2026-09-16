#import "SimulatorUatOpener.h"

#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/message.h>

static id GoITCWorkspace(void) {
  Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
  if (workspaceClass == Nil) {
    return nil;
  }
  SEL sel = NSSelectorFromString(@"defaultWorkspace");
  if (![workspaceClass respondsToSelector:sel]) {
    return nil;
  }
  return ((id(*)(id, SEL))objc_msgSend)(workspaceClass, sel);
}

static NSString *GoITCFrontBoardKey(void *handle, const char *name,
                                   NSString *fallback) {
  if (handle != NULL) {
    NSString *__strong *symbol = (NSString *__strong *)dlsym(handle, name);
    if (symbol != NULL && *symbol != nil) {
      return *symbol;
    }
  }
  return fallback;
}

static NSDictionary *GoITCFrontBoardOptions(NSURL *url) {
  void *fbs = dlopen(
      "/System/Library/PrivateFrameworks/FrontBoardServices.framework/"
      "FrontBoardServices",
      RTLD_NOW);
  NSString *payloadURLKey = GoITCFrontBoardKey(
      fbs, "FBSOpenApplicationOptionKeyPayloadURL", @"__PayloadURL");
  NSString *payloadOptionsKey = GoITCFrontBoardKey(
      fbs, "FBSOpenApplicationOptionKeyPayloadOptions", @"__PayloadOptions");
  NSString *unlockKey = GoITCFrontBoardKey(
      fbs, "FBSOpenApplicationOptionKeyUnlockDevice", @"__UnlockDevice");
  NSMutableDictionary *options = [NSMutableDictionary dictionary];
  options[payloadURLKey] = url;
  options[payloadOptionsKey] = @{
    UIApplicationLaunchOptionsURLKey : url,
  };
  options[unlockKey] = @YES;
  return options;
}

static id GoITCOpenConfiguration(NSURL *url) {
  Class configClass = NSClassFromString(@"LSOpenConfiguration");
  if (configClass == Nil) {
    configClass = NSClassFromString(@"_LSOpenConfiguration");
  }
  if (configClass == Nil) {
    return nil;
  }
  id config = [[configClass alloc] init];
  NSDictionary *frontBoardOptions = GoITCFrontBoardOptions(url);
  SEL setFrontBoard = NSSelectorFromString(@"setFrontBoardOptions:");
  if ([config respondsToSelector:setFrontBoard]) {
    ((void (*)(id, SEL, id))objc_msgSend)(config, setFrontBoard,
                                          frontBoardOptions);
  }
  SEL setSensitive = NSSelectorFromString(@"setSensitive:");
  if ([config respondsToSelector:setSensitive]) {
    ((void (*)(id, SEL, BOOL))objc_msgSend)(config, setSensitive, YES);
  }
  SEL setIgnoreAppLink =
      NSSelectorFromString(@"setIgnoreAppLinkEnabledProperty:");
  if ([config respondsToSelector:setIgnoreAppLink]) {
    ((void (*)(id, SEL, BOOL))objc_msgSend)(config, setIgnoreAppLink, YES);
  }
  return config;
}

static BOOL GoITCOpenByBundleWithURL(id workspace, NSString *bundleId,
                                     NSURL *url) {
  id config = GoITCOpenConfiguration(url);
  SEL configuredSel = NSSelectorFromString(
      @"openApplicationWithBundleIdentifier:configuration:completionHandler:");
  if (config == nil || ![workspace respondsToSelector:configuredSel]) {
    return NO;
  }
  ((void (*)(id, SEL, id, id, id))objc_msgSend)(workspace, configuredSel,
                                                bundleId, config, nil);
  return YES;
}

static BOOL GoITCOpenResourceWithApp(id workspace, NSString *bundleId,
                                     NSURL *url) {
  id application = bundleId;
  Class proxyClass = NSClassFromString(@"LSApplicationProxy");
  SEL proxySel = NSSelectorFromString(@"applicationProxyForIdentifier:");
  if (proxyClass != Nil && [proxyClass respondsToSelector:proxySel]) {
    id proxy = ((id(*)(id, SEL, id))objc_msgSend)(proxyClass, proxySel, bundleId);
    if (proxy != nil) {
      application = proxy;
    }
  }

  SEL opSel = NSSelectorFromString(
      @"operationToOpenResource:usingApplication:userInfo:");
  if (![workspace respondsToSelector:opSel]) {
    return NO;
  }
  id operation = ((id(*)(id, SEL, id, id, id))objc_msgSend)(
      workspace, opSel, url, application, nil);
  if (operation == nil) {
    return NO;
  }
  if ([operation isKindOfClass:[NSOperation class]]) {
    [[NSOperationQueue mainQueue] addOperation:operation];
    return YES;
  }
  return NO;
}

static BOOL GoITCOpenWithSpringBoard(NSString *bundleId, NSURL *url) {
  void *sbs = dlopen(
      "/System/Library/PrivateFrameworks/SpringBoardServices.framework/"
      "SpringBoardServices",
      RTLD_NOW);
  if (sbs == NULL) {
    return NO;
  }
  int (*launch)(NSString *, NSURL *, NSDictionary *, NSDictionary *, BOOL) =
      dlsym(sbs, "SBSLaunchApplicationWithIdentifierAndURLAndLaunchOptions");
  if (launch == NULL) {
    return NO;
  }
  int status = launch(bundleId, url, @{@"UnlockDevice" : @YES}, nil, NO);
  return status == 0;
}

BOOL GoITCOpenInstalledApp(NSString *bundleId, NSURL *url) {
  if (bundleId.length == 0 || url == nil) {
    return NO;
  }

  // Prefer APIs that take both the target app and the PayWay URL. Launching
  // by bundle id alone only foregrounds Simulator UAT on its home screen.
  if (GoITCOpenWithSpringBoard(bundleId, url)) {
    return YES;
  }

  id workspace = GoITCWorkspace();
  if (workspace == nil) {
    return NO;
  }
  if (GoITCOpenResourceWithApp(workspace, bundleId, url)) {
    return YES;
  }
  return GoITCOpenByBundleWithURL(workspace, bundleId, url);
}
