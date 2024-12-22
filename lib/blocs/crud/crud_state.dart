part of 'crud_bloc.dart';

abstract class CrudState extends Equatable {
  const CrudState();

  @override
  List<Object> get props => [];
}

class CrudInitial extends CrudState {}

class CrudLoading extends CrudState {}

class CrudLoaded extends CrudState {
  final List<Item> items;

  const CrudLoaded(this.items);

  @override
  List<Object> get props => [items];
}

class CrudError extends CrudState {
  final String message;

  const CrudError(this.message);

  @override
  List<Object> get props => [message];
}

