import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/item.dart';
import '../../repositories/item_repository.dart';

part 'crud_event.dart';
part 'crud_state.dart';

class CrudBloc extends Bloc<CrudEvent, CrudState> {
  final ItemRepository repository;


  CrudBloc({required this.repository}) : super(CrudInitial()) {
    on<LoadItems>(_onLoadItems);
    on<AddItem>(_onAddItem);
    on<UpdateItem>(_onUpdateItem);
    on<DeleteItem>(_onDeleteItem);
  }

  void _onLoadItems(LoadItems event, Emitter<CrudState> emit) async {
    emit(CrudLoading());
    try {
      final items = await repository.getItems();
      emit(CrudLoaded(items));
    } catch (_) {
      emit(CrudError('Failed to load items'));
    }
  }

  void _onAddItem(AddItem event, Emitter<CrudState> emit) async {
    final currentState = state;
    print("*"*100);
    print("checking for current state $currentState");
    if (currentState is CrudLoaded) {
      try {
        await repository.addItem(event.item);
        final items = await repository.getItems();

        emit(CrudLoaded(items));
      } catch (e) {
        print("Error adding item: $e");
        emit(CrudError('Failed to add item'));
      }
    }
  }

  void _onUpdateItem(UpdateItem event, Emitter<CrudState> emit) async {
    final currentState = state;
    if (currentState is CrudLoaded) {
      try {
        await repository.updateItem(event.item);
        final items = await repository.getItems();
        emit(CrudLoaded(items));
      } catch (_) {
        emit(CrudError('Failed to update item'));
      }
    }
  }

  void _onDeleteItem(DeleteItem event, Emitter<CrudState> emit) async {
    final currentState = state;
    if (currentState is CrudLoaded) {
      try {
        await repository.deleteItem(event.id);
        final items = await repository.getItems();
        emit(CrudLoaded(items));
      } catch (_) {
        emit(CrudError('Failed to delete item'));
      }
    }
  }
}

