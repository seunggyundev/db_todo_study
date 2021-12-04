import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();  //Firebase 초기화
  runApp(MyApp());
}

//할 일 클래스
//할 일 정보를 표현하기 위해 Todo클래스를 작성함 완료여부와 할 일 내용을 프로퍼티로 가지는 클래스
class Todo {
  bool isDone;
  String title;


  Todo(this.title, {this.isDone = false});
}

//시작 클래스
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '할 일 관리',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: TodoListPage(),
    );
  }
}

class TodoListPage extends StatefulWidget {

  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  /*
  //할 일 목록을 저장할 리스트
  //앞에 <Todo>를 작성하여 Todo객체를 담는 것을 명시했음
  final _items = <Todo>[]; */

  //할 일 문자열 조작을 위한 컨트롤러
  var _todoController = TextEditingController();

  //컨트롤러는 사용이 끝나면 dispose()로 해제해준다
  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('남은 할 일'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  //할 일을 입력받을 텍스트필드
                  child: TextField(
                    controller: _todoController,
                  ),
                ),
                ElevatedButton(
                    onPressed: () {
                      _addTodo(Todo((_todoController.text)));
                    },
                    child: Text('add')),
                //ListView위젯은 Column위젯의  children프로퍼티에 포함될 때 Expanded위젯으로 감싸야 정상 작동
              ],
            ),
            //이 코드는 todo 컬렉션의 데이터가 지속적으로 흘러들어오는 스트림을 통해 UI를 그림
            //여기서 StramBuilder 클래스를 사용하는데, 스트림과 연결해두면 스트림의 값이 변할 때마다 builder 부분이 다시 호출됨
            //이때 매번 화면 전체를 다시 그리지는 않고, streamBuilder로 일부분만 그림 Firestore에서는 snapshots()메서드를 사용해 데이터의 스트림을 쉽게 얻을 수 있음
            StreamBuilder<QuerySnapshot>(
              //스트림은 DB값이 변경되었을 때 자동으로 다시 값을 받아온다
              stream: FirebaseFirestore.instance.collection('todo').snapshots(),  //todo 컬렉션에 있는 모든 문서를 스트림으로 얻음, 스트림은 자료가 변경되었을 때 반응하여 화면을 다시 그림,그러기 위해서는  StreamBuilder클래스와 함께 사용
              //builder 프로퍼티를 통해 BuildContext와 QuerySnapshot 객체가 각각 context와 snapshot으로 넘어온다
              //여기에서 화면에 그려질 UI를 반환하도록 코드를 짠다
              builder: (context, snapshot) {
                //snapshot.hasData로 자료의 유무를 얻는다
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                final documents = snapshot.data?.docs;  //snapshot.data.docs로 모든 문서를 얻음
                return Expanded(
                  child: ListView(
                    //값 리스트를 위젯 리스트로 변환하는 코드
                    //_items리스트의 항목을 map()함수를 통해 내부 순환하여 todo 인수로 받고 _buildItemWidget() 메서드르 반환하고 이를 toList()함수로 다시 리스트로 변환한다
                    //이로써 전체 UI와 할 일 목록 UI를 결합함
                    children: documents!.map((doc) => _buildItemWidget(doc)).toList(),  //docs를 반복하면서 doc을 통해 위젯을 그림
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  //할 일 목록 UI임
  //할 일 객체를 ListTile 형태로 변경하는 메서드
  //_buildItemWidget()메서드는 Todo객체를 인수로 받고 ListTile위젯을 반환함
  Widget _buildItemWidget(DocumentSnapshot doc) {
    //Firestore문서는 DocumentSnapshot 클래스의 인스턴스이다 이를 받아서 Todo객체를 셍성하는 코
    final todo = Todo(doc['title'], isDone: doc['isDone']);

    return ListTile(
      onTap: () {
        _toggleTodo(doc);
      }, //완료/미완료 상태가 변경됨
      title: Text(
        todo.title, //할 일
        //Todo 객체의 isDone프로퍼티의 값에 따라 일반적인 Text가 사용되거나 취소선과 이탤릭체가 적용된 Text가 사용됨
        style: todo.isDone
            ? TextStyle(
                decoration: TextDecoration.lineThrough, //취소선
                fontStyle: FontStyle.italic)
            : null, //아무 스타일도 적용 안 함
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_forever),
        //Todo : 쓰레기통 클릭 시 삭제되도록 수정
        onPressed: () {
          _deleteTodo(doc);
        }, //항목 삭제
      ),
    );
  }

  //각 기능들을 Todo 객체를 인수로 받는 메서드롤 작성함
  //할 일 추가 메서드
  //할 일 목록에 새로운 Todo 객체를 추가하고 TextField에 입력한 글자를 지움
  void _addTodo(Todo todo) {
    //todo 컬렉션 안에 add()로 새로운 문서를 추가하는 코드
    //add()에는 Map 형식으로 데이터를 작성한다
    FirebaseFirestore.instance.collection('todo').add({'title': todo.title, 'isDone': todo.isDone});
    _todoController.text = '';
    /*
    setState(() {
      _items.add(todo);
      _todoController.text = ''; //할 일 입력 필드를 비움
    }); */
  }

  //할 일 삭제 메서드
  //할 일 목록에서 선택한 Todo 객체를 삭제한
  //특정 문서를 업데이트하려면 문서 ID가 필요함
  //DocumentSnapshot을 통해 문서 ID를 얻을 수 있으며 doc()에 인수로 전달하고 delete()로 삭
  void _deleteTodo(DocumentSnapshot doc) {
    FirebaseFirestore.instance.collection('todo').doc(doc.id).delete();
  }

  //할 일 완료/미완료 메서드
  //Todo 객체의 isDone 값을 반전시킨다
  //특정 문서를 업데이트하려면 문서 ID가 필요함
  //DocumentSnapshot을 통해 문서 ID를 얻을 수 있으며 doc()에 인수로 전달하고 update()에 수정하고자 하는 내용을 Map형태로 전달하면 자료가 업데이트됨
  void _toggleTodo(DocumentSnapshot doc) {
    FirebaseFirestore.instance.collection('todo').doc(doc.id).update({'isDone': !doc['isDone'],});
  }
}
