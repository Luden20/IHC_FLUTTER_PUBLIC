import 'package:appihv/components/general/shinny_button.dart';
import 'package:appihv/service/pocketbase.service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotificationButton extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _NotificationsButtonState();
  }
}
class _NotificationsButtonState extends State<NotificationButton>{
  bool notificaciones=PBService.notificationsEnable;
  @override
  Widget build(BuildContext context) {
    return ShinnyButton(
      icons: notificaciones?Icons.notifications_active:Icons.notifications_off,
      text: notificaciones?'Habilitadas':'No habilitadas',
      onPressed:(){
        PBService.notificationsEnable=!notificaciones;
        notificaciones=PBService.notificationsEnable;
        setState(() {

        });
      },
      expand: false,width: 225,);
  }

}