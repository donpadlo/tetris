import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' ;
import 'dart:async';
import 'package:flutter_easyloading/flutter_easyloading.dart';

final random  = new Random.secure();

int lw=10;
int lh=18;
double opa_keyboard=0.5;
double keyboard_size=40;
List LandMatrix=[];       // матрица стакана с упавшими фигурами
bool GameOver=false;

List <int> f__=[1,2,3,4]; // []
List <int> f_s=[1,2,3,11,12,13,21,22,23]; // []
List <int> f_g=[1,2,3,13];               // Г
List <int> f_t=[2,11,12,13];              // T
List <int> f_z=[1,2,12,22,23];            // Z
List Figures=[f__,f_s,f_g,f_t,f_z];
List <int> MovedFig=[]; // та фигура которая сейчас движется..
int fcurrent=0;      // номер фигуры которая сейчас движется
Timer? timer;

class Coords{
  int x=0;
  int y=0;
}


Map<int,Color>  FigColors = {
  0: Colors.red,
  1: Colors.green,
  2: Colors.indigoAccent,
  3: Colors.white,
  4: Colors.blue,
  99: Colors.black,
  100: Colors.grey,
  101: Colors.white,
};

// получить координаты левого верхнего угла фигуры
Coords GetStartXYFigure(List Fig){
  Coords res=Coords();
  res.x=999;res.y=999;
  for (var i = 0; i < Fig.length; i++) {
    Coords crd=Poz2Coors(Fig[i]);
    if (crd.x<=res.x){res.x=crd.x;};
    if (crd.y<=res.y){res.y=crd.y;};
  };
  return res;
}

// передвинуть фигуру в координаты
List <int> FigureMove(int x,int y,List<int> FM){
  Coords crd_before_move=GetStartXYFigure(MovedFig);
  int step_x=x-crd_before_move.x+2;
  int step_y=y-crd_before_move.y+1;
  for (var i = 0; i < FM.length; i++) {
    Coords tmp_crd=Poz2Coors(FM[i]);
    tmp_crd.x=tmp_crd.x+step_x;
    tmp_crd.y=tmp_crd.y+step_y;
    if (tmp_crd.x>lw){
      print("Ахтунг!");
      FM[0]=-1;
      return FM;
    };
    if (tmp_crd.y>lh){
      print("Ахтунг!");
      FM[0]=-1;
      return FM;
    };
    //print("Сдвиг в ${tmp_crd.x},${tmp_crd.y}");
    FM[i]=Coors2Poz(tmp_crd.x,tmp_crd.y);
  };
  return FM;
}
Coords Poz2Coors(int poz){
  int y=((poz-1)/lw).truncate();
  int x=poz-1-(y*lw);
  Coords res=Coords();
  res.x=x;
  res.y=y;
  //print("poz=$poz => x=$x,y=$y");
  return res;
}

int Coors2Poz(int x,int y){
  return (y-1)*lh+(x-1);
}

void CreateLandMatrix(){
  LandMatrix=[];
  LandMatrix= new List.generate(lh, (_) => new List.filled(lw, 0));
  print(LandMatrix);
  print("----------");
  for (int h=0;h<lh;h++){
    print(LandMatrix[h]);
  };
}
void FigureSelections(){
  print("Всего фигур: ${Figures.length}");
  for (var i = 0; i < 10; i++) {
    fcurrent=random.nextInt(Figures.length);
    //print("Выбрана фигура ${fnext}");
  };
  //fcurrent=0;
  MovedFig=List<int>.from(Figures[fcurrent]);
  print("Выбрана фигура ${MovedFig} №${fcurrent}");
  // проверяем переполнение стакана
  for (var i = 0; i < MovedFig.length; i++) {
    Coords crd=Poz2Coors(MovedFig[i]);
    if (LandMatrix[crd.y][crd.x]>0){
      GameOver=true;
    }
  };
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: EasyLoading.init(),
      title: 'TETRIS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Tetris'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {

  void enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  void exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  void StartTimer(context){
    timer = Timer.periodic(Duration(seconds: 1), (Timer _) {
      DestroyFullLines();
      print("Сработал таймер..");
      MoveFigDown(context);
    });
  }

  // поворачиваем блок
  void RotateFig(context){
    print("До поворота: ${MovedFig}");
    List <int> OldFig=List<int>.from(MovedFig); //запоминаем фигуру и положение до поворота

    // найдем минимальные координаты x и y до поворота
    Coords crd_before_rotare=GetStartXYFigure(MovedFig);
    print("min_x=${crd_before_rotare.x},min_y=${crd_before_rotare.y}");

    // передвинем фигуру в центр
    int center_x=(lw/2).truncate();
    int center_y=(lh/2).truncate();

    MovedFig=FigureMove(center_x,center_y,MovedFig);
    for (var i = 0; i < MovedFig.length; i++) {
      Coords crd=Poz2Coors(MovedFig[i]);
      int new_x=(crd.x * cos(3.1415926535897932/2) - crd.y * sin(3.1415926535897932/2)).round();
      int new_y=(crd.x * sin(3.1415926535897932/2) + crd.y * cos(3.1415926535897932/2)).round();
      MovedFig[i]=Coors2Poz(new_x,new_y);
      //print("x=${new_x},y=${new_y}");
    };
    MovedFig=FigureMove(crd_before_rotare.x,crd_before_rotare.y,MovedFig);

    print("После поворота: ${MovedFig}");
    // проверяем, а можно ли было поворачивать?
    if (MovedFig[0]==-1){
      MovedFig=OldFig;
    }
    // проверяем, а нет ли наложения элементов на то что уже в стакане?
    for (var i = 0; i < MovedFig.length; i++) {
      Coords crd=Poz2Coors(MovedFig[i] + lw);
      if (MovedFig[i] + lw<=lw*lh) {
        if (LandMatrix[crd.y][crd.x] > 0) {
          MovedFig=OldFig;
        };
      };
    };
  }

  bool FigOvelay(List <int> FG){
    bool res=false;
    for (var i = 0; i < FG.length; i++) {
      Coords crd=Poz2Coors(FG[i] + lw);
      if (FG[i] + lw<=lw*lh) {
        if (LandMatrix[crd.y][crd.x] > 0) {
          res=true;
          break;
        };
      };
    };
    return res;
  }
  // двигаем фигуру вправо
  void MoveFigLeft(context) {
    if (GameOver==true) {return;};
    bool move=true;
    // проверим, а можем ли двигать влево, не уткнемся ли в стену стакана?
    for (var i = 0; i < MovedFig.length; i++) {
      Coords crd=Poz2Coors(MovedFig[i]);
      print("x=${crd.x}");
      if (crd.x==0){
        move=false;
      };
    };
  // если не упираемся в стенку, то проверяем, что пусто слева
    if (move==true){
      for (var i = 0; i < MovedFig.length; i++) {
        Coords crd=Poz2Coors(MovedFig[i]-1);
        if (LandMatrix[crd.y][crd.x]>0){
          move=false;
        };
      };
    };
    // если таки можем двигаться влево, то передвигаем фигуру
    if (move==true){
      print("Фигура двинулась вправо");
      for (var i = 0; i < MovedFig.length; i++) {
        MovedFig[i] = MovedFig[i] - 1;
      };
    };
  }
  // двигаем фигуру вправо
  void MoveFigRight(context){
    if (GameOver==true) {return;};
    bool move=true;
    // проверим, а можем ли двигать вправо, не уткнемся ли в стену стакана?
    for (var i = 0; i < MovedFig.length; i++) {
      Coords crd=Poz2Coors(MovedFig[i]);
      print("x=${crd.x}");
      if (crd.x>=(lw-1)){
        move=false;
      };
    };
    // если не упираемся в стенку, то проверяем, что пусто справа
    if (move==true){
      for (var i = 0; i < MovedFig.length; i++) {
        Coords crd=Poz2Coors(MovedFig[i]+1);
        if (LandMatrix[crd.y][crd.x]>0){
          move=false;
        };
      };
    };
    // если таки можем двигаться вправо, то передвигаем фигуру
    if (move==true){
      print("Фигура двинулась вправо");
      for (var i = 0; i < MovedFig.length; i++) {
        MovedFig[i] = MovedFig[i] + 1;
      };
    };
  }
  // двигаем фигуру вниз
  void MoveFigDown(context){
      if (GameOver==true) {return;};
      bool move=true;
      // проверим,при следующем шаге, ни одна ли из точек не достигнет дна колодца при движении вниз?
      for (var i = 0; i < MovedFig.length; i++) {
        // проверка дна колодца
        if ((MovedFig[i] + lw)>lw*lh){
          move=false;
        };
        // проверка что наезд на другую фигуру
        Coords crd=Poz2Coors(MovedFig[i] + lw);
        if (MovedFig[i] + lw<=lw*lh) {
          if (LandMatrix[crd.y][crd.x] > 0) {
            move = false;
          };
        };
      };
      if (move==true) {
        for (var i = 0; i < MovedFig.length; i++) {
          MovedFig[i] = MovedFig[i] + lw;
        };
      };
      // если не можем двигаться вниз, то переносим фигуру в "стакан"
      if (move==false){
        print("-переносим фигуру в стакан");
        for (var i = 0; i < MovedFig.length; i++) {
          Coords crd=Poz2Coors(MovedFig[i]);
          LandMatrix[crd.y][crd.x]=1;
        };
        DestroyFullLines();
        // создаём новую фигуру
        FigureSelections();
      };
      setState(() {
        MovedFig=MovedFig;
      });
    print("Фигура двинулась вниз: ${MovedFig}");
  }

  // смотрим, а нет ли закрытых линий в стакане?
  void DestroyFullLines(){
    print("проверка необходимости удаления заполненых линий");
    for (var h = 0; h < lh; h++) {
      bool destroy=true;
      for (var w = 0; w < lw; w++) {
        if (LandMatrix[h][w]==0){
          destroy=false;
        };
      };
      if (destroy==true){
        print("кажется комуто нужно срочно похудеть...");
        for (var w = 0; w < lw; w++) {LandMatrix[h][w]=101;}; // чищу заполненую строчку
        // передвигаю все строчки что выше - ниже
        print("Цикл с $h по 1");
        int poz=h-1;
        for (var hz = 1; hz <= h; hz++) {
          print("копирую строчку $poz в ${poz+1}");
          for (var w = 0; w < lw; w++) {
            LandMatrix[poz+1][w]=LandMatrix[poz][w];
            LandMatrix[poz][w]=0;
          }
          poz--;
        };
        //for (var w = 0; w < lw; w++) {LandMatrix[0][w]=101;}; // чищу первую строчку
      };
    };
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      print('System overlays are visible: $systemOverlaysAreVisible');
    });
    enterFullScreen();  // входим в полноэкранный режим
    CreateLandMatrix(); // очистим сткан упавших фигур
    FigureSelections(); // добавляем случайную фигуру в матрицу падающих фигур
 //   WidgetsBinding.instance.addPostFrameCallback((_) => StartTimer(context)); // фигуры начинают падать
  }

  List <Widget> MyLandView(){
    int poz=0;
    return List<Widget>.generate(lh, (int index_h){
      return Row(
        children:
        List<Widget>.generate(lw, (int index_w){
          poz++;
          Color BoxColor=FigColors[99]??Colors.black;
          if (MovedFig.contains(poz)==true){
            BoxColor=FigColors[fcurrent]??Colors.black;
          };
          Coords crd=Poz2Coors(poz);
          // если в стакане что-то есть - рисуем
          if (LandMatrix[crd.y][crd.x]>0){
            BoxColor=FigColors[100]??Colors.black;
          };
          if (LandMatrix[crd.y][crd.x]==101){
            BoxColor=FigColors[101]??Colors.black;
          };
          return
            Padding(
                padding: EdgeInsets.all(1),
                child:
                Container(
                    color: BoxColor,
                    height: MediaQuery.of(context).size.height/lh-2 ,
                    width: MediaQuery.of(context).size.width/lw-2,
                    //child: Text("$poz")
                )
            );
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
        Stack(
          children: [
            Column(
              children: MyLandView()
            ),
            Visibility(
                visible: GameOver,
                child:
                  Padding(
                    padding: EdgeInsets.only(top: 100,left: 20,right: 20),
                    child:
                    Container(
                        padding: const EdgeInsets.all(16.0),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(32.0),
                              topRight: Radius.circular(32.0),
                              bottomRight: Radius.circular(32.0),
                              bottomLeft: Radius.circular(32.0),
                            )
                        ),
                        child:
                        Text(
                            "Вот и всё..", style: TextStyle(fontSize: 14.0, color: Colors.red)
                        )
                    ),
                  )
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              child:
                  Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child:
                      Column(
                      children: [
                        Expanded(
                            child:
                                Container(),
                        ),
                        Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: keyboard_size,height: keyboard_size,
                              ),
                              IconButton (
                                color: Colors.white.withOpacity(opa_keyboard),
                                padding: const EdgeInsets.all(0),
                                icon:  Icon(Icons.start, size: keyboard_size),
                                onPressed: () {
                                  if (timer==null) {
                                    StartTimer(context);
                                  };
                                },
                              ),
                              Container(
                                width: keyboard_size,height: keyboard_size,
                              ),
                            ]
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton (
                              padding: const EdgeInsets.all(0),
                              color: Colors.white.withOpacity(opa_keyboard),
                              icon:  Icon(Icons.arrow_left, size: keyboard_size),
                              onPressed: () {
                                 setState(() {
                                   MoveFigLeft(context);
                                 });
                                },
                            ),
                            IconButton (
                              padding: const EdgeInsets.all(0),
                              color: Colors.white.withOpacity(opa_keyboard),
                              icon:  Icon(Icons.replay, size: keyboard_size),
                              onPressed: () {
                                setState(() {
                                  RotateFig(context);
                                });
                              },
                            ),

                            IconButton (
                              padding: const EdgeInsets.all(0),
                              color: Colors.white.withOpacity(opa_keyboard),
                              icon:  Icon(Icons.arrow_right, size: keyboard_size),
                              onPressed: () {
                               setState(() {
                                 MoveFigRight(context);
                               });
                              },
                            ),
                          ],
                        ),
                        Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: keyboard_size,height: keyboard_size,
                              ),
                              IconButton (
                                color: Colors.white.withOpacity(opa_keyboard),
                                padding: const EdgeInsets.all(0),
                                icon:  Icon(Icons.arrow_downward, size: keyboard_size),
                                onPressed: () {
                                  setState(() {
                                    if (timer==null){
                                      EasyLoading.showToast("Игра еще не стартовала..");
                                    } else {
                                      MoveFigDown(context);
                                    }
                                  });
                                },
                              ),
                              Container(
                                width: keyboard_size,height: keyboard_size,
                              ),
                            ]
                        ),
                      ],
                    )  // кнопки для нажатия
                  )
            )

          ],

        )
    );
  }
}
