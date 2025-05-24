import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/provider/auth_provider.dart';
import 'package:smart_farm/theme/app_colors.dart';
import 'package:smart_farm/view/home_screen.dart';
import 'package:smart_farm/view/login_screen.dart';
import 'package:smart_farm/widget/top_bar.dart';

class Signupscreen extends StatefulWidget {
  const Signupscreen({super.key});

  @override
  State<Signupscreen> createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Error text variables
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  // Toggle password visibility
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validate the entire form
  bool _validateForm() {
    bool isValid = true;

    // Validate name
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = 'Vui lòng nhập tên của bạn';
      });
      isValid = false;
    } else if (_nameController.text.trim().length < 2) {
      setState(() {
        _nameError = 'Tên phải có ít nhất 2 ký tự';
      });
      isValid = false;
    } else {
      setState(() {
        _nameError = null;
      });
    }

    // Validate email
    String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    RegExp emailRegex = RegExp(emailPattern);

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = 'Vui lòng nhập email của bạn';
      });
      isValid = false;
    } else if (!emailRegex.hasMatch(_emailController.text.trim())) {
      setState(() {
        _emailError = 'Email không hợp lệ';
      });
      isValid = false;
    } else {
      setState(() {
        _emailError = null;
      });
    }

    // Validate password
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Vui lòng nhập mật khẩu của bạn';
      });
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      setState(() {
        _passwordError = 'Mật khẩu phải có ít nhất 6 ký tự';
      });
      isValid = false;
    } else if (!_passwordController.text.contains(RegExp(r'[A-Z]'))) {
      setState(() {
        _passwordError = 'Mật khẩu phải chứa ít nhất 1 chữ hoa';
      });
      isValid = false;
    } else if (!_passwordController.text.contains(RegExp(r'[0-9]'))) {
      setState(() {
        _passwordError = 'Mật khẩu phải chứa ít nhất 1 số';
      });
      isValid = false;
    } else {
      setState(() {
        _passwordError = null;
      });
    }

    return isValid;
  }

  void _handleSignUp() async {
    if (_validateForm()) {
      final String name = _nameController.text.trim();
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      bool res = await Provider.of<AuthProvider>(context, listen: false)
          .register(name, email, password);
      {
        if (res) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng ký thành công')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng ký không thành công')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pix = size.width / 375;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopBar(title: 'Đăng ký', isBack: true),
          ),
          Positioned(
            top: 70 * pix,
            left: 0,
            right: 0,
            bottom: 0,
            child:
                Consumer<AuthProvider>(builder: (context, authProvider, child) {
              if (authProvider.loading) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              return SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: size.width,
                              height: 90 * pix,
                              padding: EdgeInsets.only(top: 10 * pix),
                              child: Text(
                                'Bắt đầu chăm sóc khu vườn của bạn!',
                                style: TextStyle(
                                    fontSize: 22 * pix,
                                    fontFamily: 'BeVietnamPro',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Name Field
                      Container(
                        width: size.width,
                        padding:
                            EdgeInsets.only(left: 16 * pix, right: 20 * pix),
                        margin: EdgeInsets.only(bottom: 5 * pix),
                        child: Text(
                          'Tên',
                          style: TextStyle(
                              fontSize: 14 * pix,
                              fontFamily: 'BeVietnamPro',
                              color: Colors.black),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Container(
                        margin:
                            EdgeInsets.only(left: 16 * pix, right: 16 * pix),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12 * pix),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Nhập tên của bạn',
                            hintStyle: TextStyle(
                                fontSize: 14 * pix,
                                fontFamily: 'BeVietnamPro',
                                color: Colors.grey[500]),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16 * pix, vertical: 14 * pix),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide:
                                  BorderSide(color: AppColors.primaryGreen),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            errorText: _nameError,
                            errorStyle: TextStyle(
                              color: Colors.red,
                              fontSize: 12 * pix,
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16 * pix),

                      // Email Field
                      Container(
                        width: size.width,
                        padding:
                            EdgeInsets.only(left: 16 * pix, right: 20 * pix),
                        margin: EdgeInsets.only(bottom: 5 * pix),
                        child: Text(
                          'Email',
                          style: TextStyle(
                              fontSize: 14 * pix,
                              fontFamily: 'BeVietnamPro',
                              color: Colors.black),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Container(
                        margin:
                            EdgeInsets.only(left: 16 * pix, right: 16 * pix),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12 * pix),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Nhập email của bạn',
                            hintStyle: TextStyle(
                                fontSize: 14 * pix,
                                fontFamily: 'BeVietnamPro',
                                color: Colors.grey[500]),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16 * pix, vertical: 14 * pix),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide:
                                  BorderSide(color: AppColors.primaryGreen),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            errorText: _emailError,
                            errorStyle: TextStyle(
                              color: Colors.red,
                              fontSize: 12 * pix,
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16 * pix),

                      // Password Field
                      Container(
                        width: size.width,
                        padding:
                            EdgeInsets.only(left: 16 * pix, right: 20 * pix),
                        margin: EdgeInsets.only(bottom: 5 * pix),
                        child: Text(
                          'Mật khẩu',
                          style: TextStyle(
                              fontSize: 14 * pix,
                              fontFamily: 'BeVietnamPro',
                              color: Colors.black),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Container(
                        margin:
                            EdgeInsets.only(left: 16 * pix, right: 16 * pix),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12 * pix),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Nhập mật khẩu của bạn',
                            hintStyle: TextStyle(
                                fontSize: 14 * pix,
                                fontFamily: 'BeVietnamPro',
                                color: Colors.grey[500]),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16 * pix, vertical: 14 * pix),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide:
                                  BorderSide(color: AppColors.primaryGreen),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12 * pix),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            errorText: _passwordError,
                            errorStyle: TextStyle(
                              color: Colors.red,
                              fontSize: 12 * pix,
                              fontFamily: 'BeVietnamPro',
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      // Password strength indicator
                      if (_passwordController.text.isNotEmpty)
                        Container(
                          width: size.width,
                          padding: EdgeInsets.only(
                              left: 16 * pix, right: 16 * pix, top: 8 * pix),
                          child: Row(
                            children: [
                              _buildStrengthIndicator(
                                  _passwordController.text.length >= 6),
                              SizedBox(width: 4 * pix),
                              _buildStrengthIndicator(_passwordController.text
                                  .contains(RegExp(r'[A-Z]'))),
                              SizedBox(width: 4 * pix),
                              _buildStrengthIndicator(_passwordController.text
                                  .contains(RegExp(r'[0-9]'))),
                            ],
                          ),
                        ),

                      SizedBox(height: 50 * pix),

                      // Sign Up Button
                      Padding(
                        padding: EdgeInsets.all(16 * pix),
                        child: InkWell(
                          onTap: _handleSignUp,
                          child: Container(
                            width: size.width,
                            height: 56 * pix,
                            padding: EdgeInsets.only(
                                left: 16 * pix, right: 16 * pix, top: 12 * pix),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12 * pix),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primaryGreen.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text('Đăng ký ',
                                style: TextStyle(
                                    fontSize: 20 * pix,
                                    fontFamily: 'BeVietnamPro',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white),
                                textAlign: TextAlign.center),
                          ),
                        ),
                      ),

                      SizedBox(height: 10 * pix),

                      Container(
                        width: size.width,
                        height: 20 * pix,
                        padding:
                            EdgeInsets.only(left: 16 * pix, right: 16 * pix),
                        child: Text('Or',
                            style: TextStyle(
                                fontSize: 14 * pix,
                                fontFamily: 'BeVietnamPro',
                                color: Colors.black),
                            textAlign: TextAlign.center),
                      ),
                      Container(
                        width: size.width,
                        height: 56 * pix,
                        padding: EdgeInsets.only(
                            left: 66 * pix, right: 16 * pix, top: 12 * pix),
                        child: Row(
                          children: [
                            Text('Bạn đã có tài khoản?',
                                style: TextStyle(
                                    fontSize: 14 * pix,
                                    fontFamily: 'BeVietnamPro',
                                    color: Colors.black),
                                textAlign: TextAlign.center),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Loginscreen()));
                              },
                              child: Text(' Đăng nhập',
                                  style: TextStyle(
                                    fontSize: 14 * pix,
                                    fontFamily: 'BeVietnamPro',
                                    color: AppColors.primaryGreen,
                                  ),
                                  textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Helper method to build password strength indicator
  Widget _buildStrengthIndicator(bool condition) {
    return Expanded(
      child: Container(
        height: 4 * (MediaQuery.of(context).size.width / 375),
        decoration: BoxDecoration(
          color: condition ? AppColors.primaryGreen : Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
