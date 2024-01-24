import 'package:flutter/material.dart';
import 'package:tuotu/common/func.dart';

class Instruction extends StatefulWidget {
  Instruction({super.key}){
    log("instructions页初始化完成");
  }

  @override
  State<Instruction> createState() => _nameState();
}

class _nameState extends State<Instruction> {
  @override
  Widget build(BuildContext context) {
    //log("instruction页渲染完成");
    return Padding(
        padding:const EdgeInsets.fromLTRB(50, 20, 50, 20),
        child: 
          ListView(
            //crossAxisAlignment:CrossAxisAlignment.center,
            children: [
              const Text("流程演示",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16)),
              const SizedBox(height: 15),
              Container(
                //alignment:Alignment.center,
                child: Image.asset(
                  'assets/images/instruction/instruction.gif',
                  //scale:1.5,
                ),
              ),
              const SizedBox(height: 15),

              // const Text("主界面",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16)),
              // const SizedBox(height: 15),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text(
                    "最上方为状态栏，从左到右分别显示当前手机名，ip 地址和是否接入WiFi的标识",
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  )),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text(
                    "接收文件记录为已接收的文件记录的快捷方式，接收文件后可以直接打开浏览或者删除",
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  )),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text(
                    "设备显示区，同局域网的设备都会显示在这里",
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  )),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.all(Radius.circular(5))),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Text(
                    "菜单tab，可切换不同的功能页面。\"传APP\"页面即手机-APP 或手机-PC客户端之间互传，\"传电脑\"展示了PC浏览器访问和下载PC客户端的链接",
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  )),
                ],
              ),
              const SizedBox(height: 10)
            ],
          )
    );
    
    
    
  
  }
}
