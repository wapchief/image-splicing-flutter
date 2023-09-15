import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image to PDF',
      home: ImageToPdfScreen(),
    );
  }
}

class ImageToPdfScreen extends StatefulWidget {
  @override
  _ImageToPdfScreenState createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  List<XFile> selectedImages = [];

  final pdfTheme = pw.PageTheme(
    pageFormat: PdfPageFormat.letter.copyWith(
      marginLeft: 0.0,
      marginTop: 0.0,
      marginRight: 0.0,
      marginBottom: 0.0,
    ),
  );

  final imagesPerPage = 15; // 每页包含的图片数量
  final numRows = 3; // 每页行数
  final numCols = 5; // 每页列数

  bool loading = false;

  bool lineRow = true;
  bool lineColumn = true;

  Future<void> createPdf() async {
    if (loading) {
      return;
    }
    loading = true;
    setState(() {});
    final pdf = pw.Document();

    // 计算每张图片的宽度和高度以适应页面大小
    final pageWidth = PdfPageFormat.letter.width;
    final pageHeight = PdfPageFormat.letter.height;
    final imgWidth = pageWidth / numCols;
    final imgHeight = pageHeight / numRows;
    for (var i = 0; i < selectedImages.length; i += imagesPerPage) {
      final start = i;
      final end = (i + imagesPerPage < selectedImages.length)
          ? i + imagesPerPage
          : selectedImages.length;
      final List<pw.Widget> imageWidgets = [];
      // 创建3行5列的图像网格
      for (var row = 0; row < numRows; row++) {
        final List<pw.Widget> rowWidgets = [];
        for (var col = 0; col < numCols; col++) {
          final index = start + row * numCols + col;

          if (index < end) {
            final imageFile = selectedImages[index];
            final bytes = await imageFile.readAsBytes();
            // 在每个网格单元中放置图像
            final img = pw.Image(
              pw.MemoryImage(bytes),
              width: pageWidth / numCols,
              height: pageHeight / numRows,
            );
            rowWidgets.add(img);
            // 分割线
            if (lineColumn) {
              rowWidgets.add(
                pw.Container(
                  width: 1,
                  height: pageHeight / numRows,
                  color: const PdfColor.fromInt(0x20000000),
                ),
              );
            }
            // if (lineRow) {
            //   rowWidgets.add(
            //     pw.Container(
            //       width: 1,
            //       height: pageWidth / numCols,
            //       color: const PdfColor.fromInt(0x20000000),
            //     ),
            //   );
            // }
          }
        }
        imageWidgets.add(pw.Row(children: rowWidgets));
      }
      pdf.addPage(
        pw.Page(
          pageTheme: pdfTheme,
          build: (context) {
            // 创建一个包含图像网格的列
            return pw.Column(children: imageWidgets);
          },
        ),
      );
    }
    // val downloadsDir = applicationContext.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS).path

    final outputDir = await getTemporaryDirectory();
    // final outputDir = FileProvider.
    Uint8List uList = await pdf.save();

    var outputFile = File('${outputDir.path}/output.pdf');
    await outputFile.writeAsBytes(uList);
    loading = false;
    setState(() {});
    await launchUrl(Uri.file(outputFile.path));
    return;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('是否保存文件？'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('取消')),
              TextButton(
                onPressed: () async {
                  final res = await FileSaver.instance
                      .saveFile(name: 'output', file: outputFile, ext: 'pdf');
                  debugPrint(res);
                  await launchUrl(Uri.file(res));
                  Navigator.of(context).pop();
                },
                child: Text('保存'),
              ),
            ],
          );
        });
    // outputXFile.
    // Utils.openFile(outputXFile.path);
    // final result = await Share.shareXFiles([outputXFile], text: 'Great picture');
    // if (result.status == ShareResultStatus.success) {
    //   print('Thank you for sharing the picture!');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image to PDF Converter'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                final imageFile = selectedImages[index];
                return ListTile(
                  title: Text('${index + 1}、${imageFile.path}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        selectedImages.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Divider(),
          Row(
            children: [
              Column(
                children: [
                  // Row(
                  //   children: [
                  //     Switch.adaptive(
                  //       value: lineRow,
                  //       materialTapTargetSize: MaterialTapTargetSize.padded,
                  //       onChanged: (v) {
                  //         setState(() {
                  //           lineRow = v;
                  //         });
                  //       },
                  //     ),
                  //     Text('横向分割线', style: TextStyle(color: Colors.grey)),
                  //   ],
                  // ),
                  Row(
                    children: [
                      Switch.adaptive(
                          value: lineColumn,
                          onChanged: (v) {
                            setState(() {
                              lineColumn = v;
                            });
                          }),
                      Text(
                        '分割线',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 100,
              ),
              ElevatedButton(
                onPressed: () async {
                  final imagePicker = ImagePicker();
                  final pickedFile = await imagePicker.pickMultiImage();
                  setState(() {
                    selectedImages = pickedFile;
                    // selectedImages
                  });
                },
                child: Text('添加图片'),
              ),
              SizedBox(
                width: 10,
                height: 10,
              ),
              ElevatedButton(
                onPressed: createPdf,
                child: Text(loading ? '正在处理...' : '拼接图片并生成PDF'),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
