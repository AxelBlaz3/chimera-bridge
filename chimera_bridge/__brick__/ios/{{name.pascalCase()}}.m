#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE({{name.pascalCase()}}, RCTEventEmitter)

{{#futures}}
RCT_EXTERN_METHOD({{methodName}}:{{#params}}{{#isFirst}}({{oType}}){{name}}{{/isFirst}}{{^isFirst}} {{name}}:({{oType}}){{name}}{{/isFirst}}{{/params}} resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{{/futures}}

@end