import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class NetworkImageWidget extends StatefulWidget {
  final String url;
  final double width;
  final double height;

  const NetworkImageWidget({
    super.key,
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  NetworkImageWidgetState createState() => NetworkImageWidgetState();
}

class NetworkImageWidgetState extends State<NetworkImageWidget> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final response = await http.get(
        Uri.parse(widget.url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load image: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading image: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pix = MediaQuery.of(context).size.width / 375;
    return SizedBox(
      width: widget.width * pix,
      height: widget.height * pix,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.red,
                          size: 40 * pix,
                        ),
                        SizedBox(height: 4 * pix),
                        Text(
                          'Lỗi: $_error',
                          style:
                              TextStyle(color: Colors.red, fontSize: 10 * pix),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.red,
                          size: 40 * pix,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
