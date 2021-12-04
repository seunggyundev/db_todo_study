import 'package:flutter/material.dart';


//할 일 클래스
//할 일 정보를 표현하기 위해 Todo클래스를 작성함 완료여부와 할 일 내용을 프로퍼티로 가지는 클래스
class Todo {
  bool isDone = false;
  String? title;


  Todo(this.title, {this.isDone = false});
}
