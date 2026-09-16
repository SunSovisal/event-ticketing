#import "SimulatorUatOpener.h"

#import <objc/message.h>

BOOL GoITCAppIsInstalled(NSString *bundleId) {
  if (bundleId.length == 0) {
    return NO;
  }

  Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
  SEL workspaceSel = NSSelectorFromString(@"defaultWorkspace");
  SEL installedSel = NSSelectorFromString(@"applicationIsInstalled:");
  if (workspaceClass == Nil || ![workspaceClass respondsToSelector:workspaceSel]) {
    return NO;
  }

  id workspace = ((id(*)(id, SEL))objc_msgSend)(workspaceClass, workspaceSel);
  if (workspace == nil || ![workspace respondsToSelector:installedSel]) {
    return NO;
  }

  return ((BOOL(*)(id, SEL, id))objc_msgSend)(workspace, installedSel, bundleId);
}
