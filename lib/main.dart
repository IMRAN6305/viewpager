import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'blocs/crud/crud_bloc.dart';
import 'blocs/filtered_list/filtered_list_bloc.dart';
import 'repositories/item_repository.dart';
import 'models/item.dart';
import 'core/theme/app_theme.dart';
import 'common/widgets/custom_text_field.dart';
import 'common/widgets/custom_dropdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Flutter ViewPager CRUD',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: MultiBlocProvider(
            providers: [
              BlocProvider(
                  create: (context) =>
                      CrudBloc(repository: ItemRepository())..add(LoadItems())),
              BlocProvider(
                  create: (context) =>
                      FilteredListBloc(repository: ItemRepository())),
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
              Lottie.asset('assets/animations/no_internet.json',
                  width: 200, height: 200),
              const SizedBox(height: 20),
              const Text('No Internet Connection',
                  style: TextStyle(fontSize: 20)),
              const SizedBox(height: 10),
              const Text(
                  'Please check your internet connection and try again.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('ViewPager CRUD', style: TextStyle(fontSize: 20.sp)),
        shape: const RoundedRectangleBorder(
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
                VerticalDivider(
                    width: 1, color: Theme.of(context).dividerColor),
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
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.list), label: 'CRUD'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.filter_list), label: 'Filtered'),
              ],
              currentIndex: _pageController.hasClients
                  ? (_pageController.page?.round() ?? 0)
                  : 0,
              onTap: (index) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
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
                  items: const ['Category 1', 'Category 2', 'Category 3'],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  label: 'Your Message',
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
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48.h),
                  ),
                  child: const Text('Pick File'),
                ),
                SizedBox(height: 8.h),
                Text(_selectedFilePath ?? 'No file selected'),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48.h),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _editingItem == null ? Icons.add : Icons.update,
                        // Conditional icon
                        size: 20.sp, // Adjust the size of the icon
                      ),
                      SizedBox(width: 8.w),
                      // Space between the icon and the text
                      Text(
                        _editingItem == null ? 'Add Item' : 'Update Item',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Requests',
            style: TextStyle(
              decoration: TextDecoration.underline,
              fontSize: 24.sp, // Adjust the size for heading
              fontWeight: FontWeight.bold, // Make it bold for heading effect
              color: Colors.black, // You can customize the color
            ),
          ),
          SizedBox(height: 5.h),
          Expanded(
            child: BlocBuilder<CrudBloc, CrudState>(
              builder: (context, state) {
                if (state is CrudLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is CrudLoaded) {
                  return ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Slidable(
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                context
                                    .read<CrudBloc>()
                                    .add(DeleteItem(item.id));
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
                          child: InkWell(
                            onTap: () {
                              _showItemDetailsPopup(context, item);
                            },
                            child: ListTile(
                              tileColor: _getCategoryColor(item.category),
                              title: Text(item.text,
                                  style: TextStyle(
                                      fontSize: 16.sp,
                                      overflow: TextOverflow.ellipsis),
                                  maxLines: 1,
                                  softWrap: false),
                              subtitle: Text(item.category,
                                  style: TextStyle(fontSize: 14.sp)),
                              trailing: InkWell(
                                  onTap: () {
                                    _editItem(item);
                                  },
                                  child: const Icon(Icons.edit)),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is CrudError) {
                  return Center(
                      child: Text(state.message,
                          style: TextStyle(fontSize: 16.sp)));
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showItemDetailsPopup(BuildContext context, Item item) {
    Color categoryColor = _getCategoryColor(item.category);

    // Define the Text style for better readability
    TextStyle headingStyle = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.bold,
      color: Colors.grey[800],
    );

    TextStyle valueStyle = TextStyle(
      fontSize: 16.sp,
      color: Colors.grey[700],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 8,
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Item Details',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                SizedBox(height: 16.h),

                // Text: Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Text: ', style: headingStyle),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        item.text,
                        style: valueStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines:
                            1, // Limit to 3 lines, show "see all" button if overflow
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                // Category: Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category: ', style: headingStyle),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        item.category,
                        style: valueStyle,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),

                // Description: Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ', style: headingStyle),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        item.id, // Assuming `item.text` is the description
                        style: valueStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1, // Limit description lines
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Show More Option (Only for long content)
                if (item.text.length >
                    100) // Check length of content and show 'See all' if it's long
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        // Open a full view with all content
                        _showFullContentPopup(context, item);
                      },
                      child: Text('See All Content',
                          style: TextStyle(color: categoryColor)),
                    ),
                  ),

                // Close Button
                Align(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: categoryColor,
                      // Button color based on category
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// Full Content Popup (For "See All" button)
  void _showFullContentPopup(BuildContext context, Item item) {
    Color categoryColor = _getCategoryColor(item.category);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 8,
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Full Content',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                SizedBox(height: 16.h),

                // Full Content Text
                Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.justify,
                ),
                SizedBox(height: 20.h),

                // Close Button
                Align(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: categoryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          const SnackBar(content: Text('Please select a file')),
        );
        return;
      }

      final item = Item(
        id: _editingItem?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
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
            items: const ['Category 1', 'Category 2', 'Category 3'],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
              context
                  .read<FilteredListBloc>()
                  .add(LoadFilteredItems(_selectedCategory));
            },
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: BlocBuilder<FilteredListBloc, FilteredListState>(
              builder: (context, state) {
                if (state is FilteredListLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is FilteredListLoaded) {
                  if (state.items.isEmpty) {
                    return Center(
                      child: Lottie.asset('assets/animations/empty.json'),
                    );
                  }
                  return ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 8.h),
                        child: ListTile(
                          tileColor: _getCategoryColor(item.category),
                          title: Text(
                            item.text,
                            style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.white.withOpacity(0.9)),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                          subtitle: Text(item.category,
                              style: TextStyle(fontSize: 14.sp)),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('PDF Options'),
                                    content: const Text(
                                        'Do you want to View or Download the PDF?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () async {
                                          // Option: View PDF
                                          Navigator.of(context).pop();
                                          await _viewPdf(item.filePath);
                                        },
                                        child: const Text('View'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          // String fileName =
                                          //     item.filePath.split('/').last;
                                          // final downloadPath =
                                          //     await downloadPdfLocally(
                                          //         fileName, item.filePath);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                              'File Downloaded ',
                                            )),
                                          );
                                        },
                                        child: const Text('Download'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Text('Download PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is FilteredListError) {
                  return Center(
                      child: Text(state.message,
                          style: TextStyle(fontSize: 16.sp)));
                }
                return Container();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewPdf(String filePath) async {
    // Open the PDF file using a PDF viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFScreen(filePath: filePath),
      ),
    );
  }

  Future<String> downloadPdfLocally(
      String fileName, String localFilePath) async {
    // Check for storage permissions
    final permissionStatus = await Permission.storage.request();

    // If permission is denied, show a dialog and exit
    if (permissionStatus.isDenied) {
      // You can show a dialog to inform the user why permission is needed
      print("Permission denied. Please enable storage permissions.");
      return "Permission Denied"; // Or show a dialog to prompt the user
    }

    // If permission is granted, proceed with the download
    final directory = await getExternalStorageDirectory();
    final downloadDirectory = Directory('${directory!.path}/Downloads');

    // Check if the directory exists, if not, create it
    if (!await downloadDirectory.exists()) {
      await downloadDirectory.create(recursive: true);
    }

    // Define the local file path in the Downloads folder
    final localFile = File('${downloadDirectory.path}/$fileName');

    // Check if the file already exists
    if (await localFile.exists()) {
      print("File already exists at: ${localFile.path}");
      return localFile.path; // Return the existing file path
    }

    // If the file doesn't exist, download and save it
    try {
      // Simulate downloading the file (In a real scenario, you could use HTTP request to fetch the file)
      final response = await http.get(Uri.parse(localFilePath));

      if (response.statusCode == 200) {
        // Write the bytes to the local file
        await localFile.writeAsBytes(response.bodyBytes);
        print("File downloaded to: ${localFile.path}");
        return localFile.path; // Return the new file path after download
      } else {
        print("Failed to download file");
        throw Exception("Failed to download PDF file");
      }
    } catch (e) {
      print("Error downloading file: $e");
      throw Exception("Error downloading PDF file");
    }
  }
}

class PDFScreen extends StatelessWidget {
  final String filePath;

  const PDFScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF View')),
      body: PDFView(
        filePath: filePath,
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error occurred')),
          );
        },
        onPageError: (page, error) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error occurred')),
          );
        },
      ),
    );
  }
}

// Method to get color based on category
Color _getCategoryColor(String category) {
// print("categoryColor is $category");
  switch (category) {
    case 'Category 1':
      return Colors.red;
    case 'Category 2':
      return Colors.blue;
    case 'Category 3':
      return Colors.yellow;
    default:
      return Colors.grey;
  }
}
