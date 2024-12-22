import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/item.dart';
import '../../repositories/item_repository.dart';

part 'filtered_list_event.dart';
part 'filtered_list_state.dart';

class FilteredListBloc extends Bloc<FilteredListEvent, FilteredListState> {
  final ItemRepository repository;

  FilteredListBloc({required this.repository}) : super(FilteredListInitial()) {
    on<LoadFilteredItems>(_onLoadFilteredItems);
  }

  void _onLoadFilteredItems(LoadFilteredItems event, Emitter<FilteredListState> emit) async {
    emit(FilteredListLoading());
    try {
      final items = await repository.getFilteredItems(event.category);
      emit(FilteredListLoaded(items));
    } catch (_) {
      emit(FilteredListError('Failed to load filtered items'));
    }
  }
}

