import 'dart:async';

import 'package:adhara/config.dart';
import 'package:adhara/datainterface/bean.dart';
import 'package:adhara/datainterface/network/network_provider.dart';
import 'package:adhara/datainterface/storage/http_storage_provider.dart';
import 'package:adhara/datainterface/storage/bean_storage_provider.dart';
import 'package:adhara/datainterface/storage/key_value_storage_provider.dart';


class DataInterface{

  Config config;
  NetworkProvider networkProvider;
  HTTPStorageProvider httpStorageProvider;
  KeyValueStorageProvider keyValueStorageProvider;

  DataInterface(this.config){
    networkProvider = config.networkProvider;
  }

  Future createDataStores() async {
    httpStorageProvider = HTTPStorageProvider(config);
    await httpStorageProvider.createTable();
    keyValueStorageProvider = KeyValueStorageProvider(config);
    await keyValueStorageProvider.createTable();
  }

  bool get canStore{
    return true;
  }

  dynamic _getFromHTTPStorage(url) async {
    dynamic storageData = await httpStorageProvider.getData(url);
      print("data from storage for URL $url is");
      print(storageData);
    return storageData;
  }

  Future storeHTTPData(url, httpData) async {
    return httpStorageProvider.setData(url, httpData);
  }

  dynamic getFromHTTP(url, {
    Function networkDataFormatter,
    Function storageDataFormatter
  }) async {
    dynamic data = await _getFromHTTPStorage(url);
    if(data == null) {
      try {
        dynamic httpData = await networkProvider.get(url);
        if(networkDataFormatter != null) {
          httpData = networkDataFormatter(httpData);
        }
//      print(">>> in httpData");
//      print(httpData);
        if (this.canStore) {
          await storeHTTPData(url, httpData);
          data = await _getFromHTTPStorage(url);
        }
//        return httpData;
      } catch (e) {
        print("DATAINTERFACE ERROR");
        print(e);
        data = {};
      }
    }
    if(storageDataFormatter!=null){
      data = storageDataFormatter(data);
    }
    return data;
  }

  Future<Map> queryOne(BeanStorageProvider storageProvider, int id) async {
    return storageProvider.getByIdRaw(id);
  }

  Future<List<Map>> query(BeanStorageProvider storageProvider, {Map<String, dynamic> filter, Map<String, dynamic> exclude}) async {
    String where;
    List<dynamic> whereArgs = [];
    if(filter!=null){
      List<String> whereKeys = [];
      filter.forEach((k,v){
        whereKeys.add("$k == ?");
        whereArgs.add(v);
      });
      where = whereKeys.join(" and ");
    }
    if(exclude!=null){
      List<String> excludeKeys = [];
      exclude.forEach((k,v){
        excludeKeys.add("$k != ?");
        whereArgs.add(v);
      });
      where += " and "+excludeKeys.join(" and ");
    }
    return storageProvider.getRawList(where: where, whereArgs: whereArgs);
  }

  Future<Bean> save(BeanStorageProvider storageProvider, Bean bean) async {
    return storageProvider.save(bean);
  }

  Future<List<Bean>> saveAll(BeanStorageProvider storageProvider, List<Bean> beans) async {
    return storageProvider.saveAll(beans);
  }

  Future<int> update(BeanStorageProvider storageProvider, Bean bean) async {
    return storageProvider.edit(bean);
  }

  Future delete(BeanStorageProvider storageProvider, Bean bean) async {
    storageProvider.deleteOne(bean);
  }

}