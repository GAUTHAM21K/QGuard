
import "package:flutter/material.dart";

class usertile extends StatelessWidget {
  
  final String text;
  final void Function()? onTap;

  const usertile({
    super.key,
    required this.text,
    required this.onTap
    });



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
        
            children: [
              Icon(Icons.person,size: 45,color: Colors.white70,),
              SizedBox(width: 10,),
              Text(text,style: TextStyle(color: Colors.white70,fontSize: 25))
            ],
          ),
        ),
      ),



    );
  }
}