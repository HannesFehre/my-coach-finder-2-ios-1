#import <Capacitor/Capacitor.h>

// Register OSParameterPlugin with Capacitor
CAP_PLUGIN(OSParameterPlugin, "OSParameter",
  CAP_PLUGIN_METHOD(addOSParameter, CAPPluginReturnPromise);
)
