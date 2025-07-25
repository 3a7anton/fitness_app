import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fitness_flutter/core/const/text_constants.dart';
import 'package:fitness_flutter/core/service/user_service.dart';
import 'package:meta/meta.dart';

part 'change_password_event.dart';
part 'change_password_state.dart';

class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  ChangePasswordBloc() : super(ChangePasswordInitial()) {
    on<ChangePassword>(_onChangePassword);
  }

  void _onChangePassword(ChangePassword event, Emitter<ChangePasswordState> emit) async {
    emit(ChangePasswordProgress());
    try {
      await UserService.changePassword(newPass: event.newPass);
      emit(ChangePasswordSuccess(message: TextConstants.passwordUpdated));
      await Future.delayed(Duration(seconds: 1));
      emit(ChangePasswordInitial());
    } catch (e) {
      emit(ChangePasswordError(e.toString()));
      await Future.delayed(Duration(seconds: 1));
      emit(ChangePasswordInitial());
    }
  }
}
