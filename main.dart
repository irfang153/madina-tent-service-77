
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

void main() => runApp(const MadinaApp());

class Item {
  String name; int available, rate;
  Item(this.name,this.available,this.rate);
  Map<String,dynamic> toJson()=>{'name':name,'available':available,'rate':rate};
  factory Item.fromJson(Map x)=>Item(x['name'],x['available'],x['rate']);
}
class Customer {
  String id,name,phone,address; List rentals;
  Customer(this.id,this.name,{this.phone='',this.address='',this.rentals=const[]});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'phone':phone,'address':address,'rentals':rentals};
  factory Customer.fromJson(Map x)=>Customer(x['id'],x['name'],phone:x['phone']??'',address:x['address']??'',rentals:List.from(x['rentals']??[]));
}

class MadinaApp extends StatelessWidget {
  const MadinaApp({super.key});
  Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false,title:'مدینہ ٹینٹ سروس',
    theme:ThemeData(useMaterial3:true,colorSchemeSeed:Colors.green),
    home:const Home());
}

class Home extends StatefulWidget {
  const Home({super.key}); State<Home> createState()=>_Home();
}
class _Home extends State<Home>{
  int tab=0; bool ready=false; List<Item> items=[]; List<Customer> customers=[];
  final defaults=[
    ['ٹینٹ',100,100],['کرسیاں',500,100],['میز',500,100],['پلیٹ',1000,5],
    ['جگ',500,10],['دیگ',15,200],['دریاں',200,25],['دستر خوان',100,20]
  ];
  void initState(){super.initState();load();}
  Future load()async{
    final p=await SharedPreferences.getInstance();
    final a=p.getString('items'),b=p.getString('customers');
    setState((){
      items=a==null?defaults.map((x)=>Item(x[0] as String,x[1] as int,x[2] as int)).toList()
        :(jsonDecode(a) as List).map((x)=>Item.fromJson(x)).toList();
      customers=b==null?[]:(jsonDecode(b) as List).map((x)=>Customer.fromJson(x)).toList();
      ready=true;
    });
  }
  Future save()async{
    final p=await SharedPreferences.getInstance();
    await p.setString('items',jsonEncode(items.map((x)=>x.toJson()).toList()));
    await p.setString('customers',jsonEncode(customers.map((x)=>x.toJson()).toList()));
  }
  Widget build(BuildContext c){
    if(!ready)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('مدینہ ٹینٹ سروس',style:TextStyle(fontWeight:FontWeight.bold))),
      body:IndexedStack(index:tab,children:[
        Dashboard(items,customers,()=>setState(()=>tab=1)),
        CustomersPage(customers,items,(){save();setState((){});}),
        InventoryPage(items)
      ]),
      bottomNavigationBar:NavigationBar(
        selectedIndex:tab,onDestinationSelected:(x)=>setState(()=>tab=x),
        destinations:const[
          NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'ہوم'),
          NavigationDestination(icon:Icon(Icons.people_outline),selectedIcon:Icon(Icons.people),label:'گاہک'),
          NavigationDestination(icon:Icon(Icons.inventory_2_outlined),selectedIcon:Icon(Icons.inventory_2),label:'سامان')
        ])));
  }
}

class Dashboard extends StatelessWidget{
  final List<Item> items; final List<Customer> customers; final VoidCallback go;
  const Dashboard(this.items,this.customers,this.go,{super.key});
  Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[
      const Icon(Icons.storefront,size:55),
      const Text('کرایہ اور کھاتے',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
      Text('${customers.length} گاہک محفوظ'),
      const SizedBox(height:12),
      FilledButton.icon(onPressed:go,icon:const Icon(Icons.person_add),label:const Text('نیا گاہک / نیا کرایہ'))
    ]))),
    const SizedBox(height:10),
    const Text('سامان کی دستیابی',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    ...items.map((i)=>Card(child:ListTile(
      title:Text(i.name),subtitle:Text('کرایہ Rs. ${i.rate}'),
      trailing:Text('${i.available}',style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)))))
  ]);
}

class CustomersPage extends StatefulWidget{
  final List<Customer> cs; final List<Item> items; final VoidCallback save;
  const CustomersPage(this.cs,this.items,this.save,{super.key});
  State<CustomersPage> createState()=>_CustomersPage();
}
class _CustomersPage extends State<CustomersPage>{
  Future add()async{
    final n=TextEditingController(),p=TextEditingController(),a=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(x)=>AlertDialog(
      title:const Text('نیا گاہک'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:n,decoration:const InputDecoration(labelText:'گاہک کا نام')),
        TextField(controller:p,decoration:const InputDecoration(labelText:'موبائل نمبر')),
        TextField(controller:a,decoration:const InputDecoration(labelText:'پتہ'))
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(x,false),child:const Text('منسوخ')),
        FilledButton(onPressed:()=>Navigator.pop(x,true),child:const Text('محفوظ کریں'))
      ]));
    if(ok==true&&n.text.trim().isNotEmpty){
      widget.cs.add(Customer(DateTime.now().microsecondsSinceEpoch.toString(),n.text.trim(),phone:p.text,address:a.text));
      widget.save();setState((){});
    }
  }
  Widget build(BuildContext c)=>Column(children:[
    Padding(padding:const EdgeInsets.all(16),child:Row(children:[
      const Expanded(child:Text('گاہکوں کے کھاتے',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold))),
      FilledButton.icon(onPressed:add,icon:const Icon(Icons.add),label:const Text('نیا گاہک'))
    ])),
    Expanded(child:widget.cs.isEmpty
      ?const Center(child:Text('ابھی کوئی گاہک محفوظ نہیں'))
      :ListView(children:widget.cs.map((x)=>Card(child:ListTile(
        leading:const CircleAvatar(child:Icon(Icons.person)),title:Text(x.name),
        subtitle:Text(x.phone),trailing:const Icon(Icons.chevron_left),
        onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>Account(x,widget.items,widget.save)))
      )).toList()))
  ]);
}

class Account extends StatefulWidget{
  final Customer customer; final List<Item> items; final VoidCallback save;
  const Account(this.customer,this.items,this.save,{super.key});
  State<Account> createState()=>_Account();
}
class _Account extends State<Account>{
  final qty=<String,int>{}; final paid=TextEditingController();
  DateTime returnDate=DateTime.now().add(const Duration(days:1));
  int get total=>widget.items.fold(0,(s,i)=>s+(qty[i.name]??0)*i.rate);

  void makeAgreement(Map r){
    final lines=(r['items'] as List).map((x)=>
      '${x['name']}: ${x['qty']} × Rs.${x['rate']} = Rs.${x['qty']*x['rate']}').join('\n');
    final text="مدینہ ٹینٹ سروس — کرایہ نامہ\n\n"
      "گاہک: ${widget.customer.name}\nموبائل: ${widget.customer.phone}\n"
      "پتہ: ${widget.customer.address}\n"
      "تاریخ: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(r['date']))}\n"
      "واپسی: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(r['return']))}\n\n"
      "سامان:\n$lines\n\n"
      "کل کرایہ: Rs.${r['total']}\nوصول شدہ: Rs.${r['paid']}\n"
      "بقایا: Rs.${r['remaining']}";
    showDialog(context:context,builder:(x)=>AlertDialog(
      title:const Text('کرایہ نامہ'),
      content:SingleChildScrollView(child:Text(text)),
      actions:[
        TextButton(onPressed:()=>Share.share(text),child:const Text('شیئر کریں')),
        FilledButton(onPressed:()=>Navigator.pop(x),child:const Text('بند کریں'))
      ]));
  }

  void rent(){
    if(total==0){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('کم از کم ایک سامان منتخب کریں')));
      return;
    }
    final p=int.tryParse(paid.text.trim())??0;
    for(final i in widget.items){
      final n=qty[i.name]??0;
      if(n>i.available){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('${i.name} دستیاب نہیں')));
        return;
      }
    }
    final r={
      'date':DateTime.now().toIso8601String(),'return':returnDate.toIso8601String(),
      'items':qty.entries.where((e)=>e.value>0).map((e)=>({
        'name':e.key,'qty':e.value,
        'rate':widget.items.firstWhere((i)=>i.name==e.key).rate
      })).toList(),
      'total':total,'paid':p,'remaining':total-p
    };
    widget.customer.rentals=[...widget.customer.rentals,r];
    for(final i in widget.items)i.available-=qty[i.name]??0;
    widget.save();setState(qty.clear);makeAgreement(r);
  }

  Widget build(BuildContext c)=>Directionality(textDirection:TextDirection.rtl,child:Scaffold(
    appBar:AppBar(title:Text(widget.customer.name)),
    body:ListView(padding:const EdgeInsets.all(12),children:[
      Card(child:ListTile(title:Text(widget.customer.name),
        subtitle:Text('${widget.customer.phone}\n${widget.customer.address}'))),
      const Text('نیا کرایہ',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
      ...widget.items.map((i){
        final n=qty[i.name]??0;
        return Card(child:Row(children:[
          Expanded(child:ListTile(title:Text(i.name),subtitle:Text('Rs.${i.rate} • دستیاب ${i.available}'))),
          IconButton(onPressed:n>0?()=>setState(()=>qty[i.name]=n-1):null,icon:const Icon(Icons.remove_circle_outline)),
          Text('$n',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
          IconButton(onPressed:n<i.available?()=>setState(()=>qty[i.name]=n+1):null,icon:const Icon(Icons.add_circle_outline))
        ]));
      }),
      Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[
        Text('کل کرایہ: Rs.$total',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        TextField(controller:paid,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'وصول شدہ رقم')),
        ListTile(title:const Text('واپسی کی تاریخ'),
          trailing:Text(DateFormat('dd-MM-yyyy').format(returnDate)),
          onTap:()async{
            final d=await showDatePicker(context:context,firstDate:DateTime.now(),
              lastDate:DateTime.now().add(const Duration(days:3650)),initialDate:returnDate);
            if(d!=null)setState(()=>returnDate=d);
          }),
        FilledButton.icon(onPressed:rent,icon:const Icon(Icons.save),
          label:const Text('محفوظ کریں اور کرایہ نامہ بنائیں'))
      ]))),
      const Text('پچھلا حساب',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
      ...widget.customer.rentals.reversed.map((r)=>Card(child:ListTile(
        title:Text('کل Rs.${r['total']} • بقایا Rs.${r['remaining']}'),
        subtitle:Text(DateFormat('dd-MM-yyyy').format(DateTime.parse(r['date']))),
        onTap:()=>makeAgreement(r))))
    ])));
}
class InventoryPage extends StatelessWidget{
  final List<Item> items; const InventoryPage(this.items,{super.key});
  Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('سامان کا ریکارڈ',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),
    ...items.map((i)=>Card(child:ListTile(title:Text(i.name),
      subtitle:Text('کرایہ Rs.${i.rate}'),trailing:Text('${i.available}',
      style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)))))
  ]);
}
