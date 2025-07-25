import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(OnboardingInitial()) {
    on<PageChangedEvent>(_onPageChangedEvent);
    on<PageSwipedEvent>(_onPageSwipedEvent);
  }

  int pageIndex = 0;

  final pageController = PageController(initialPage: 0);

  void _onPageChangedEvent(PageChangedEvent event, Emitter<OnboardingState> emit) {
    if (pageIndex == 2) {
      emit(NextScreenState());
      return;
    }
    pageIndex += 1;

    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
    );

    emit(PageChangedState(counter: pageIndex));
  }

  void _onPageSwipedEvent(PageSwipedEvent event, Emitter<OnboardingState> emit) {
    pageIndex = event.index;
    emit(PageChangedState(counter: pageIndex));
  }
}
