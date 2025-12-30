import { NativeModules, NativeEventEmitter } from 'react-native';

const { {{name.pascalCase()}} } = NativeModules;
const eventEmitter = new NativeEventEmitter({{name.pascalCase()}});

{{#streams}}
export function on{{methodName.pascalCase()}}(callback: (data: {{returnTsType}}) => void) {
  return eventEmitter.addListener('{{methodName}}', callback);
}
{{/streams}}

{{#futures}}
export function {{methodName}}({{#params}}{{name}}: {{tsType}}{{^last}}, {{/last}}{{/params}}): Promise<{{returnTsType}}> {
  return {{name.pascalCase()}}.{{methodName}}({{#params}}{{name}}{{^last}}, {{/last}}{{/params}});
}
{{/futures}}

export default {
  {{#streams}}
  on{{methodName.pascalCase()}},
  {{/streams}}
  {{#futures}}
  {{methodName}},
  {{/futures}}
};