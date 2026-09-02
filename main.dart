import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class Item {
  String name;
  int available, rate;
  Item(this.name, this.available, this.rate);
  Map<String,dynamic> toJson()=>{'name':name,'available':available,'rate':rate};
  factory Item.fromJson(Map x)=>Item(x['name'],x['available'],x['rate']);
}

class Customer {
  String id,name,phone,address;
  List rentals;
  List payments;
  Customer(this.id,this.name,{this.phone='',this.address='',this.rentals=const[],this.payments=const[]});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'phone':phone,'address':address,'rentals':rentals,'payments':payments};
  factory Customer.fromJson(Map x)=>Customer(x['id'],x['name'],phone:x['phone']??'',address:x['address']??'',rentals:List.from(x['rentals']??[]),payments:List.from(x['payments']??[]));
}

void main()=>runApp(const MadinaApp());

class MadinaApp extends StatelessWidget{
  const MadinaApp({super.key});
  @override Widget build(BuildContext c)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'مدینہ ٹینٹ سروس',
    theme:ThemeData(primarySwatch:Colors.green,useMaterial3:true),
    home:const HomePage());
}

class HomePage extends StatefulWidget{
  const HomePage({super.key});
  @override State<HomePage> createState()=>_HomePageState();
}

class _HomePageState extends State<HomePage>{
  List<Item> items=[];
  List<Customer> customers=[];
  bool loading=true;

  @override void initState(){super.initState();load();}
  Future<void> load() async{
    final p=await SharedPreferences.getInstance();
    final ir=p.getString('items');
    final cr=p.getString('customers');
    setState((){
      items=ir==null?[
        Item('ٹینٹ',100,100),Item('کرسیاں',500,100),Item('میز',500,100),
        Item('پلیٹ',1000,5),Item('جگ',500,10),Item('دیگ',15,200),
        Item('دریاں',200,25),Item('دسترخوان',100,20)
      ]:List.from((jsonDecode(ir) as List).map((x)=>Item.fromJson(x)));
      customers=cr==null?[]:List.from((jsonDecode(cr) as List).map((x)=>Customer.fromJson(x)));
      loading=false;
    });
  }
  Future<void> save() async{
    final p=await SharedPreferences.getInstance();
    await p.setString('items',jsonEncode(items.map((e)=>e.toJson()).toList()));
    await p.setString('customers',jsonEncode(customers.map((e)=>e.toJson()).toList()));
  }
  int get outstanding=>customers.fold(0,(s,c)=>s+c.rentals.fold(0,(a,r)=>a+(r['remaining']??0)));
  @override Widget build(BuildContext c){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    return Scaffold(
      appBar:AppBar(title:const Text('مدینہ ٹینٹ سروس')),
      body:ListView(padding:const EdgeInsets.all(12),children:[
        Card(child:ListTile(title:const Text('کل گاہک'),trailing:Text('${customers.length}',style:const TextStyle(fontSize:22)))),
        Card(child:ListTile(title:const Text('کل بقایا رقم'),trailing:Text('Rs.$outstanding',style:const TextStyle(fontSize:22,color:Colors.red)))),
        const SizedBox(height:10),
        FilledButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CustomersPage(customers:customers,items:items,save:save))),icon:const Icon(Icons.people),label:const Text('گاہک اور کرایہ')),
        FilledButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>InventoryPage(items:items,save:save))),icon:const Icon(Icons.inventory_2),label:const Text('سامان / اسٹاک')),
      ]),
    );
  }
}

class CustomersPage extends StatefulWidget{
  final List<Customer> customers; final List<Item> items; final Future<void> Function() save;
  const CustomersPage({super.key,required this.customers,required this.items,required this.save});
  @override State<CustomersPage> createState()=>_CustomersPageState();
}
class _CustomersPageState extends State<CustomersPage>{
  void addCustomer(){
    final n=TextEditingController(),p=TextEditingController(),a=TextEditingController();
    showDialog(context:context,builder:(_)=>AlertDialog(
      title:const Text('نیا گاہک'),content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:n,decoration:const InputDecoration(labelText:'نام')),
        TextField(controller:p,decoration:const InputDecoration(labelText:'موبائل')),
        TextField(controller:a,decoration:const InputDecoration(labelText:'پتہ')),
      ]),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('منسوخ')),
        FilledButton(onPressed:()async{if(n.text.trim().isEmpty)return;widget.customers.add(Customer(DateTime.now().microsecondsSinceEpoch.toString(),n.text,phone:p.text,address:a.text));await widget.save();setState((){});Navigator.pop(context);},child:const Text('محفوظ'))],
    ));
  }
  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('گاہک')),
    floatingActionButton:FloatingActionButton(onPressed:addCustomer,child:const Icon(Icons.add)),
    body:ListView.builder(itemCount:widget.customers.length,itemBuilder:(_,i){
      final x=widget.customers[i];
      final due=x.rentals.fold(0,(s,r)=>s+(r['remaining']??0));
      return Card(child:ListTile(title:Text(x.name),subtitle:Text('${x.phone}\nبقایا: Rs.$due'),isThreeLine:true,
        trailing:const Icon(Icons.arrow_forward_ios),
        onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>AccountPage(customer:x,items:widget.items,save:widget.save))));
    }));
}

class AccountPage extends StatefulWidget{
  final Customer customer; final List<Item> items; final Future<void> Function() save;
  const AccountPage({super.key,required this.customer,required this.items,required this.save});
  @override State<AccountPage> createState()=>_AccountPageState();
}
class _AccountPageState extends State<AccountPage>{
  Map<String,int> qty={}; DateTime? returnDate;
  int get total=>qty.entries.fold(0,(s,e)=>s+e.value*widget.items.firstWhere((i)=>i.name==e.key).rate);
  int get due=>widget.customer.rentals.fold(0,(s,r)=>s+(r['remaining']??0));

  void rent(){
    if(qty.values.every((v)=>v==0)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('سامان منتخب کریں')));return;}
    showDialog(context:context,builder:(_)=>_RentDialog(
      total:total, onSave:(paid,date)async{
        final r={'date':DateTime.now().toIso8601String(),'return':date.toIso8601String(),
          'items':qty.entries.where((e)=>e.value>0).map((e)=>({'name':e.key,'qty':e.value,'returned':0,'rate':widget.items.firstWhere((i)=>i.name==e.key).rate})).toList(),
          'total':total,'paid':paid,'remaining':total-paid};
        widget.customer.rentals=[...widget.customer.rentals,r];
        for(final i in widget.items)i.available-=qty[i.name]??0;
        await widget.save();setState((){qty.clear();returnDate=null;});makeAgreement(r);
        Navigator.pop(context);
      }));
  }

  void makeAgreement(Map r){
    final lines=(r['items'] as List).map((x)=>'${x['name']}: ${x['qty']} × Rs.${x['rate']}').join('\n');
    final text='مدینہ ٹینٹ سروس\nکرایہ نامہ\nگاہک: ${widget.customer.name}\nموبائل: ${widget.customer.phone}\nتاریخ: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(r['date']))}\nواپسی: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(r['return']))}\n\n$lines\n\nکل کرایہ: Rs.${r['total']}\nوصول: Rs.${r['paid']}\nبقایا: Rs.${r['remaining']}';
    Share.share(text);
  }

  Future<void> returnItems(int index)async{
    final r=widget.customer.rentals[index];
    final list=List<Map<String,dynamic>>.from((r['items'] as List).map((x)=>Map<String,dynamic>.from(x)));
    final back={for(final x in list)x['name']:0};
    final ok=await showDialog<bool>(context:context,builder:(_)=>StatefulBuilder(builder:(c,set){
      return AlertDialog(title:const Text('سامان واپس لیں'),content:SizedBox(width:350,child:ListView(shrinkWrap:true,children:[
        ...list.map((x){final max=(x['qty']??0)-(x['returned']??0);return ListTile(title:Text(x['name']),subtitle:Text('باقی: $max'),trailing:Row(mainAxisSize:MainAxisSize.min,children:[
          IconButton(onPressed:back[x['name']]>0?()=>set(()=>back[x['name']]--):null,icon:const Icon(Icons.remove)),
          Text('${back[x['name']]}',style:const TextStyle(fontSize:18)),
          IconButton(onPressed:back[x['name']]<max?()=>set(()=>back[x['name']]++):null,icon:const Icon(Icons.add))
        ]);})
      ])),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('منسوخ')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('واپس جمع کریں'))]);
    }));
    if(ok!=true)return;
    for(final x in list){
      final n=x['name'],b=back[n]??0;
      if(b>0){x['returned']=(x['returned']??0)+b;final it=widget.items.firstWhere((i)=>i.name==n);it.available+=b;}
    }
    r['items']=list;
    await widget.save();setState((){});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('سامان اسٹاک میں واپس شامل ہوگیا')));
  }

  Future<void> addPayment()async{
    if(due<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('کوئی بقایا رقم نہیں')));return;}
    final ctrl=TextEditingController();
    await showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('بقایا رقم وصول کریں'),content:TextField(controller:ctrl,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'رقم')),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('منسوخ')),FilledButton(onPressed:()async{
        final p=int.tryParse(ctrl.text)||0;if(p<=0)return;
        var left=p;
        for(final r in widget.customer.rentals){
          final rem=(r['remaining']??0) as int;
          if(left<=0)break;
          final use=left<rem?left:rem;r['paid']=(r['paid']??0)+use;r['remaining']=rem-use;left-=use;
        }
        widget.customer.payments=[...widget.customer.payments,{'date':DateTime.now().toIso8601String(),'amount':p-left}];
        await widget.save();setState((){});Navigator.pop(context);
      },child:const Text('وصول محفوظ کریں'))]));
  }

  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:Text(widget.customer.name)),
    body:ListView(padding:const EdgeInsets.all(12),children:[
      Card(child:ListTile(title:const Text('موجودہ بقایا'),trailing:Text('Rs.$due',style:const TextStyle(fontSize:22,color:Colors.red)))),
      FilledButton.icon(onPressed:addPayment,icon:const Icon(Icons.payments),label:const Text('بقایا رقم وصول کریں')),
      const SizedBox(height:8),
      const Text('نیا کرایہ',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
      ...widget.items.map((it){qty.putIfAbsent(it.name,()=>0);return ListTile(title:Text(it.name),subtitle:Text('اسٹاک: ${it.available} • ریٹ: Rs.${it.rate}'),trailing:Row(mainAxisSize:MainAxisSize.min,children:[
        IconButton(onPressed:qty[it.name]!>0?()=>setState(()=>qty[it.name]=qty[it.name]!-1):null,icon:const Icon(Icons.remove)),
        Text('${qty[it.name]}'),
        IconButton(onPressed:qty[it.name]!<it.available?()=>setState(()=>qty[it.name]=qty[it.name]!+1):null,icon:const Icon(Icons.add))
      ]);}),
      Card(child:ListTile(title:const Text('کل کرایہ'),trailing:Text('Rs.$total',style:const TextStyle(fontSize:22)))),
      FilledButton.icon(onPressed:rent,icon:const Icon(Icons.save),label:const Text('کرایہ محفوظ کریں')),
      const Divider(),
      const Text('پچھلا حساب',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
      ...widget.customer.rentals.asMap().entries.toList().reversed.map((e){
        final idx=e.key,r=e.value;
        final returned=(r['items'] as List).every((x)=>(x['returned']??0)>=(x['qty']??0));
        return Card(child:ListTile(title:Text('کل Rs.${r['total']} • بقایا Rs.${r['remaining']}'),
          subtitle:Text('${DateFormat('dd-MM-yyyy').format(DateTime.parse(r['date']))}\n${returned?'تمام سامان واپس':'سامان زیرِ کرایہ'}'),
          isThreeLine:true,onTap:()=>makeAgreement(r),
          trailing:returned?const Icon(Icons.check_circle):IconButton(onPressed:()=>returnItems(idx),icon:const Icon(Icons.assignment_return))));
      })
    ]));
}

class _RentDialog extends StatefulWidget{
  final int total; final void Function(int,DateTime) onSave;
  const _RentDialog({required this.total,required this.onSave});
  @override State<_RentDialog> createState()=>_RentDialogState();
}
class _RentDialogState extends State<_RentDialog>{
  final paid=TextEditingController(); DateTime date=DateTime.now().add(const Duration(days:1));
  @override Widget build(BuildContext c)=>AlertDialog(title:const Text('کرایہ مکمل کریں'),
    content:Column(mainAxisSize:MainAxisSize.min,children:[
      Text('کل: Rs.${widget.total}',style:const TextStyle(fontSize:20)),
      TextField(controller:paid,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'وصول شدہ رقم')),
      ListTile(title:Text('واپسی: ${DateFormat('dd-MM-yyyy').format(date)}'),trailing:const Icon(Icons.calendar_month),onTap:()async{
        final d=await showDatePicker(context:c,firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:3650)),initialDate:date);
        if(d!=null)setState(()=>date=d);
      })
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('منسوخ')),FilledButton(onPressed:(){
      final p=int.tryParse(paid.text)||0;if(p<0||p>widget.total)return;
      widget.onSave(p,date);
    },child:const Text('محفوظ کریں'))]);
}

class InventoryPage extends StatefulWidget{
  final List<Item> items; final Future<void> Function() save;
  const InventoryPage({super.key,required this.items,required this.save});
  @override State<InventoryPage> createState()=>_InventoryPageState();
}
class _InventoryPageState extends State<InventoryPage>{
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('سامان / اسٹاک')),
    body:ListView(children:widget.items.map((i)=>Card(child:ListTile(title:Text(i.name),subtitle:Text('کرایہ: Rs.${i.rate}'),trailing:Text('${i.available}',style:const TextStyle(fontSize:22)))).toList()));
                                                   }
