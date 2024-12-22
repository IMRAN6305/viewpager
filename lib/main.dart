import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'blocs/crud/crud_bloc.dart';
import 'blocs/filtered_list/filtered_list_bloc.dart';
import 'repositories/item_repository.dart';
import 'models/item.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'common/widgets/custom_text_field.dart';
import 'common/widgets/custom_dropdown.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Flutter ViewPager CRUD',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.lightTheme,
          themeMode: ThemeMode.system,
          home: MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => CrudBloc(repository: ItemRepository())..add(LoadItems())),
              BlocProvider(create: (context) => FilteredListBloc(repository: ItemRepository())),
            ],
            child: ViewPagerScreen(),
          ),
        );
      },
    );
  }
}

class ViewPagerScreen extends StatefulWidget {
  @override
  _ViewPagerScreenState createState() => _ViewPagerScreenState();
}

class _ViewPagerScreenState extends State<ViewPagerScreen> {
  final PageController _pageController = PageController();
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnline) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset('assets/animations/no_internet.json', width: 200, height: 200),
              SizedBox(height: 20),
              Text('No Internet Connection', style: TextStyle(fontSize: 20)),
              SizedBox(height: 10),
              Text('Please check your internet connection and try again.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('ViewPager CRUD', style: TextStyle(fontSize: 20.sp)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            // Web view
            return Row(
              children: [
                Expanded(child: CrudScreen()),
                VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
                Expanded(child: FilteredListScreen()),
              ],
            );
          } else {
            // Mobile view
            return PageView(
              controller: _pageController,
              children: [
                CrudScreen(),
                FilteredListScreen(),
              ],
            );
          }
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return BottomNavigationBar(
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.list), label: 'CRUD'),
                BottomNavigationBarItem(icon: Icon(Icons.filter_list), label: 'Filtered'),
              ],
              currentIndex: _pageController.hasClients ? (_pageController.page?.round() ?? 0) : 0,
              onTap: (index) {
                _pageController.animateToPage(
                  index,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            );
          } else {
            return SizedBox.shrink();
          }
        },
      ),
    );
  }
}

class CrudScreen extends StatefulWidget {
  @override
  _CrudScreenState createState() => _CrudScreenState();
}

class _CrudScreenState extends State<CrudScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'Category 1';
  final TextEditingController _textController = TextEditingController();
  String? _selectedFilePath;
  Item? _editingItem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                CustomDropdown(
                  label: 'Category',
                  value: _selectedCategory,
                  items: ['Category 1', 'Category 2', 'Category 3'],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  label: 'Text',
                  controller: _textController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: _pickFile,
                  child: Text('Pick File'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48.h),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(_selectedFilePath ?? 'No file selected'),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(_editingItem == null ? 'Add Item' : 'Update Item'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48.h),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: BlocBuilder<CrudBloc, CrudState>(
              builder: (context, state) {
                if (state is CrudLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is CrudLoaded) {
                  return ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Slidable(
                        endActionPane: ActionPane(
                          motion: ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                context.read<CrudBloc>().add(DeleteItem(item.id));
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8.h),
                          child: ListTile(
                            title: Text(item.text, style: TextStyle(fontSize: 16.sp)),
                            subtitle: Text(item.category, style: TextStyle(fontSize: 14.sp)),
                            trailing: InkWell(
                                onTap: () {
                                  _editItem(item);
                                },
                                child: Icon(Icons.edit)),
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is CrudError) {
                  return Center(child: Text(state.message, style: TextStyle(fontSize: 16.sp)));
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, // Use custom type
      allowedExtensions: ['pdf'], // Only allow PDF files
    );
    if (result != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedFilePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a file')),
        );
        return;
      }

      final item = Item(
        id: _editingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        category: _selectedCategory,
        text: _textController.text,
        filePath: _selectedFilePath!,
      );

      if (_editingItem == null) {
        context.read<CrudBloc>().add(AddItem(item));
      } else {
        context.read<CrudBloc>().add(UpdateItem(item));
      }

      _resetForm();
    }
  }

  void _editItem(Item item) {
    setState(() {
      _editingItem = item;
      _selectedCategory = item.category;
      _textController.text = item.text;
      _selectedFilePath = item.filePath;
    });
  }

  void _resetForm() {
    setState(() {
      _editingItem = null;
      _selectedCategory = 'Category 1';
      _textController.clear();
      _selectedFilePath = null;
    });
  }
}

class FilteredListScreen extends StatefulWidget {
  @override
  _FilteredListScreenState createState() => _FilteredListScreenState();
}

class _FilteredListScreenState extends State<FilteredListScreen> {
  String _selectedCategory = 'Category 1';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          CustomDropdown(
            label: 'Filter by Category',
            value: _selectedCategory,
            items: ['Category 1', 'Category 2', 'Category 3'],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
              context.read<FilteredListBloc>().add(LoadFilteredItems(_selectedCategory));
            },
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: BlocBuilder<FilteredListBloc, FilteredListState>(
              builder: (context, state) {
                if (state is FilteredListLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is FilteredListLoaded) {
                  return ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 8.h),
                        child: ListTile(
                          title: Text(item.text, style: TextStyle(fontSize: 16.sp)),
                          subtitle: Text(item.category, style: TextStyle(fontSize: 14.sp)),
                          trailing: ElevatedButton(
                            onPressed: () {
                              // TODO: Implement PDF download and preview
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('PDF download and preview not implemented')),
                              );
                            },
                            child: Text('Download PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is FilteredListError) {
                  return Center(child: Text(state.message, style: TextStyle(fontSize: 16.sp)));
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }
}

