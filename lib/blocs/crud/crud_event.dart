part of 'crud_bloc.dart';

abstract class CrudEvent extends Equatable {
  const CrudEvent();

  @override
  List<Object> get props => [];
}

class LoadItems extends CrudEvent {}

class AddItem extends CrudEvent {
  final Item item;

  const AddItem(this.item);

  @override
  List<Object> get props => [item];
}

class UpdateItem extends CrudEvent {
  final Item item;

  const UpdateItem(this.item);

  @override
  List<Object> get props => [item];
}

class DeleteItem extends CrudEvent {
  final String id;

  const DeleteItem(this.id);

  @override
  List<Object> get props => [id];
}

