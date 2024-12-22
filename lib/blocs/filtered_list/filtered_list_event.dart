part of 'filtered_list_bloc.dart';

abstract class FilteredListEvent extends Equatable {
  const FilteredListEvent();

  @override
  List<Object> get props => [];
}

class LoadFilteredItems extends FilteredListEvent {
  final String category;

  const LoadFilteredItems(this.category);

  @override
  List<Object> get props => [category];
}

