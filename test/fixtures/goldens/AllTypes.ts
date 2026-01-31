import { NativeModules, NativeEventEmitter } from 'react-native';

const { AllTypes } = NativeModules;
const eventEmitter = new NativeEventEmitter(AllTypes);


export function onOnString(callback: (data: string) => void) {
  return eventEmitter.addListener('onString', callback);
}

export function onOnInt(callback: (data: number) => void) {
  return eventEmitter.addListener('onInt', callback);
}

export function onOnMap(callback: (data: object) => void) {
  return eventEmitter.addListener('onMap', callback);
}



export function getString(): Promise<string> {
  return AllTypes.getString();
}

export function getInt(): Promise<number> {
  return AllTypes.getInt();
}

export function getDouble(): Promise<number> {
  return AllTypes.getDouble();
}

export function getBool(): Promise<boolean> {
  return AllTypes.getBool();
}

export function voidMethod(): Promise<void> {
  return AllTypes.voidMethod();
}

export function getList(): Promise<any[]> {
  return AllTypes.getList();
}

export function getMap(): Promise<object> {
  return AllTypes.getMap();
}


export default {
  
  onOnString,
  
  onOnInt,
  
  onOnMap,
  
  
  getString,
  
  getInt,
  
  getDouble,
  
  getBool,
  
  voidMethod,
  
  getList,
  
  getMap,
  
};