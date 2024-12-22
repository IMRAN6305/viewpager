part of 'filtered_list_bloc.dart';

abstract class FilteredListState extends Equatable {
  const FilteredListState();

  @override
  List<Object> get props => [];
}

class FilteredListInitial extends FilteredListState {}

class FilteredListLoading extends FilteredListState {}

class FilteredListLoaded extends FilteredListState {
  final List<Item> items;

  const FilteredListLoaded(this.items);

  @override
  List<Object> get props => [items];
}

class FilteredListError extends FilteredListState {
  final String message;

  const FilteredListError(this.message);

  @override
  List<Object> get props => [message];
}

