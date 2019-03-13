import 'package:flutter/material.dart' show Widget;
import 'package:adhara/module.dart';


class URL{

  String pattern;
  Widget widget;
  List<URL> urls;
  String name;
  Function router;
  AdharaModule module;
  Map<String, dynamic> kwArgs;

  URL(this.pattern, {
    this.router,
    this.widget,
    this.urls,
    this.name,
    this.module,
    this.kwArgs
  }) : assert(
    !(widget==null && router==null && module==null),
    "Invalid URL configuration. Provide a widget, router fn or urls list"
  );

  Function getRouter(){
    if(router!=null){
      return router;
    }
    return () => widget;
  }

}