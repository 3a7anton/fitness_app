import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fitness_flutter/core/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc() : super(ForgotPasswordInitial()) {
    on<ForgotPasswordTappedEvent>(_onForgotPasswordTappedEvent);
  }
  
  final emailController = TextEditingController();
  bool isError = false;

  void _onForgotPasswordTappedEvent(ForgotPasswordTappedEvent event, Emitter<ForgotPasswordState> emit) async {
    try {
      emit(ForgotPasswordLoading());
      await AuthService.resetPassword(emailController.text);
      emit(ForgotPasswordSuccess());
    } catch (e) {
      print('Error: ' + e.toString());
      emit(ForgotPasswordError(message: e.toString()));
    }
  }
}
