import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CartState(
      child: SunnyBunnyCafeApp(),
    );
  }
}

class SunnyBunnyCafeApp extends StatefulWidget {
  const SunnyBunnyCafeApp({super.key});

  @override
  State<SunnyBunnyCafeApp> createState() => _SunnyBunnyCafeAppState();
}

class _SunnyBunnyCafeAppState extends State<SunnyBunnyCafeApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Солнечный зайчик',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFFF6B35),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF6B35),
          secondary: Color(0xFFFF8C42),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFFFF6B35),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B35),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF6B35),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B35),
          secondary: Color(0xFFFF8C42),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF2D2D2D),
          foregroundColor: Color(0xFFFF6B35),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B35),
          ),
        ),
        cardColor: const Color(0xFF2D2D2D),
      ),
      themeMode: _themeMode,
      home: AuthWrapper(
          toggleTheme: toggleTheme, isDark: _themeMode == ThemeMode.dark),
    );
  }
}

// ==================== АВТОРИЗАЦИЯ ====================
class AuthWrapper extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDark;
  const AuthWrapper(
      {super.key, required this.toggleTheme, required this.isDark});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            _CartStateState.clearCartStatic();
            return LoginScreen(
                toggleTheme: widget.toggleTheme, isDark: widget.isDark);
          }
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              bool isAdmin = false;
              String userName = '';

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;
                isAdmin = userData?['role'] == 'admin';
                userName =
                    userData?['name'] ?? user.email?.split('@').first ?? 'User';
              }

              final adminEmails = ['admin@gmail.com', '11111@gmail.com'];
              if (adminEmails.contains(user.email)) {
                isAdmin = true;
              }

              return MainScreen(
                isAdmin: isAdmin,
                userName: userName,
                userEmail: user.email ?? '',
                toggleTheme: widget.toggleTheme,
                isDark: widget.isDark,
              );
            },
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

//ЭКРАН ВХОДА
class LoginScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDark;
  const LoginScreen(
      {super.key, required this.toggleTheme, required this.isDark});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return ' Неверный формат email';
      case 'user-not-found':
        return ' Пользователь не найден';
      case 'wrong-password':
        return ' Неверный пароль';
      case 'email-already-in-use':
        return ' Этот email уже используется';
      case 'weak-password':
        return ' Пароль должен быть не менее 6 символов';
      default:
        return ' Ошибка. Попробуйте еще раз';
    }
  }

  Future<void> _authenticate() async {
    if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' Введите корректный email')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(' Пароль должен быть не менее 6 символов')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        if (_nameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(' Введите ваше имя')),
          );
          setState(() => _isLoading = false);
          return;
        }

        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'role': 'user',
          'phone': '',
          'address': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getErrorMessage(e.code))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' Ошибка подключения')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isDark
                ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)]
                : [const Color(0xFFFF6B35), const Color(0xFFFF8C42)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '☀️ Солнечный зайчик',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35)),
                    ),
                    const SizedBox(height: 40),
                    if (!_isLogin)
                      Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Ваше имя',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Пароль',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              _isLogin ? 'ВОЙТИ' : 'ЗАРЕГИСТРИРОВАТЬСЯ',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? 'Нет аккаунта? Зарегистрируйтесь'
                            : 'Уже есть аккаунт? Войдите',
                        style: const TextStyle(color: Color(0xFFFF6B35)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//ГЛАВНЫЙ ЭКРАН
class MainScreen extends StatefulWidget {
  final bool isAdmin;
  final String userName;
  final String userEmail;
  final VoidCallback toggleTheme;
  final bool isDark;
  const MainScreen(
      {super.key,
      required this.isAdmin,
      required this.userName,
      required this.userEmail,
      required this.toggleTheme,
      required this.isDark});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MenuScreen(isAdmin: widget.isAdmin),
      const CartScreen(),
      OrdersScreen(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
      ProfileScreen(
          userName: widget.userName,
          userEmail: widget.userEmail,
          toggleTheme: widget.toggleTheme,
          isDark: widget.isDark),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF6B35),
        unselectedItemColor: Colors.grey[400],
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu), label: 'Меню'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Корзина'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Заказы'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}

//ПРОФИЛЬ ПОЛЬЗОВАТЕЛЯ
class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback toggleTheme;
  final bool isDark;
  const ProfileScreen(
      {super.key,
      required this.userName,
      required this.userEmail,
      required this.toggleTheme,
      required this.isDark});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'phone': _phoneController.text,
        'address': _addressController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Данные сохранены!'), backgroundColor: Colors.green),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    _CartStateState.clearCartStatic();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 Профиль'),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFFF6B35),
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              widget.userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.userEmail,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Контактная информация',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: ' Телефон',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: ' Адрес доставки',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Сохранить',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//КОРЗИНА
class CartItem {
  final int id;
  final String name;
  final String description;
  final String imagePath;
  final int price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.price,
    this.quantity = 1,
  });

  int get total => price * quantity;
}

class CartProvider extends InheritedWidget {
  final List<CartItem> cartItems;
  final int itemCount;
  final Function(int, String, String, String, int) addItem;
  final Function(int) removeItem;
  final Function(int, int) updateQuantity;
  final Function() clearCart;

  const CartProvider({
    super.key,
    required this.cartItems,
    required this.itemCount,
    required this.addItem,
    required this.removeItem,
    required this.updateQuantity,
    required this.clearCart,
    required super.child,
  });

  static CartProvider of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CartProvider>()!;
  }

  @override
  bool updateShouldNotify(CartProvider oldWidget) {
    return cartItems != oldWidget.cartItems;
  }
}

// ==================== ЭКРАН МЕНЮ ====================
class MenuScreen extends StatefulWidget {
  final bool isAdmin;
  const MenuScreen({super.key, required this.isAdmin});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<dynamic> _menu = [];
  bool _isLoading = true;
  String _selectedCategory = 'Все';
  String _searchQuery = '';

  String _getImagePath(String name) {
    switch (name.toLowerCase()) {
      case 'мокко брауни':
        return 'assets/images/mokko.png';
      case 'капучино':
        return 'assets/images/kapuchino.png';
      case 'латте':
        return 'assets/images/latte.png';
      case 'тыквенный с беконом':
        return 'assets/images/tukva_sup.png';
      case 'цезарь':
        return 'assets/images/zhezar.png';
      case 'средиземноморская паста':
        return 'assets/images/pasta_sredzem.png';
      case 'панкейки шоколадные':
        return 'assets/images/pankeyk.png';
      default:
        return 'assets/images/placeholder.png';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await http.get(Uri.parse('http://localhost:8080/api/menu'));
      if (response.statusCode == 200) {
        setState(() {
          _menu = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка подключения к серверу')),
      );
    }
  }

  List<String> get _categories {
    Set<String> cats = {'Все'};
    for (var item in _menu) cats.add(item['category']);
    return cats.toList();
  }

  List<dynamic> get _filteredMenu {
    var filtered = _menu;

    // Фильтр по категории
    if (_selectedCategory != 'Все') {
      filtered = filtered
          .where((item) => item['category'] == _selectedCategory)
          .toList();
    }

    // Поиск по названию
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((item) =>
              item['name'].toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  void _addToCart(Map<String, dynamic> item) {
    CartProvider.of(context).addItem(item['id'], item['name'],
        item['description'], _getImagePath(item['name']), item['price']);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('${item['name']} добавлен'),
          duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _deleteMenuItem(int id, String name) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить блюдо'),
        content: Text('Вы уверены, что хотите удалить "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await http.delete(
                  Uri.parse('http://localhost:8080/api/menu/$id'),
                );
                if (response.statusCode == 200) {
                  _fetchMenu();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Блюдо удалено')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ошибка удаления')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    String category = 'напитки';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Новое блюдо'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Название', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                    labelText: 'Описание', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                    labelText: 'Цена', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                value: category,
                items: 'напитки,обеды,салаты,ужины,десерты'
                    .split(',')
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => category = v!,
                decoration: const InputDecoration(
                    labelText: 'Категория', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите название')));
                return;
              }
              if (priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите цену')));
                return;
              }

              await http.post(
                Uri.parse('http://localhost:8080/api/menu'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'name': nameController.text,
                  'description': descController.text,
                  'price': int.parse(priceController.text),
                  'category': category,
                }),
              );

              _fetchMenu();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Блюдо добавлено!')));
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = CartProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('☀️ Солнечный зайчик'),
        actions: [
          // Счетчик корзины на иконке
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // Переключиться на вкладку корзины
                  final mainScreenState =
                      context.findAncestorStateOfType<_MainScreenState>();
                  if (mainScreenState != null) {
                    mainScreenState.setState(() {
                      mainScreenState._currentIndex = 1;
                    });
                  }
                },
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchMenu),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ПОИСК
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: ' Поиск блюд...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                // Категории
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF6B35)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF6B35)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(cat,
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600])),
                        ),
                      );
                    },
                  ),
                ),
                // Список блюд
                Expanded(
                  child: _filteredMenu.isEmpty
                      ? const Center(child: Text('Ничего не найдено'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredMenu.length,
                          itemBuilder: (context, index) {
                            final item = _filteredMenu[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: Colors.grey[200]!, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(24)),
                                    child: Image.asset(
                                      _getImagePath(item['name']),
                                      width: 400,
                                      height: 400,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 140,
                                        height: 160,
                                        color: const Color(0xFFFF6B35),
                                        child: const Icon(Icons.restaurant,
                                            size: 60, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['name'].toUpperCase(),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 25),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (widget.isAdmin)
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red,
                                                      size: 22),
                                                  onPressed: () =>
                                                      _deleteMenuItem(
                                                          item['id'],
                                                          item['name']),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            item['description'],
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.grey[600],
                                                height: 1.4),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              const Spacer(),
                                              ElevatedButton.icon(
                                                onPressed: () =>
                                                    _addToCart(item),
                                                icon: const Icon(
                                                    Icons.add_shopping_cart,
                                                    size: 20),
                                                label: Text(
                                                    '${item['price']} ₽',
                                                    style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFFFF6B35),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              child: const Icon(Icons.add),
              backgroundColor: const Color(0xFFFF6B35),
            )
          : null,
    );
  }
}

// ==================== ЭКРАН КОРЗИНЫ (оптимизированный) ====================
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isOrdering = false;
  bool _showPaymentForm = false;
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  int get _totalPrice {
    final cart = CartProvider.of(context).cartItems;
    return cart.fold(0, (sum, item) => sum + item.total);
  }

  Future<void> _createOrder() async {
    final cart = CartProvider.of(context);
    if (cart.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Корзина пуста')),
      );
      return;
    }

    setState(() {
      _showPaymentForm = true;
    });
  }

  Future<void> _submitOrder() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер телефона')),
      );
      return;
    }
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите адрес доставки')),
      );
      return;
    }

    setState(() {
      _isOrdering = true;
      _showPaymentForm = false;
    });

    final cart = CartProvider.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final orderItems = cart.cartItems
        .map((item) => ({
              'id': item.id,
              'name': item.name,
              'price': item.price,
              'quantity': item.quantity,
            }))
        .toList();

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': user?.uid,
          'items': orderItems,
          'total': _totalPrice,
          'phone': _phoneController.text,
          'address': _addressController.text,
        }),
      );

      if (response.statusCode == 200) {
        cart.clearCart();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Заказ оформлен! Спасибо!'),
              backgroundColor: Colors.green,
            ),
          );
          _phoneController.clear();
          _addressController.clear();
        }
      } else {
        throw Exception('Ошибка оформления');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка оформления заказа')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOrdering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartProvider.of(context);
    final items = cart.cartItems;
    final total = _totalPrice;

    return Scaffold(
      appBar: AppBar(
        title: const Text(' Корзина'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: cart.clearCart),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 80),
                SizedBox(height: 16),
                Text('Корзина пуста')
              ],
            ))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(item.imagePath,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    width: 50,
                                    height: 50,
                                    color: const Color(0xFFFF6B35),
                                    child: const Icon(Icons.restaurant))),
                          ),
                          title: Text(item.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item.price} ₽'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 20),
                                onPressed: () {
                                  cart.updateQuantity(
                                      item.id, item.quantity - 1);
                                },
                              ),
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 20),
                                onPressed: () {
                                  cart.updateQuantity(
                                      item.id, item.quantity + 1);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => cart.removeItem(item.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _showPaymentForm ? 280 : 0,
                  child: _showPaymentForm
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Данные для доставки',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => setState(
                                        () => _showPaymentForm = false),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  labelText: ' Номер телефона',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  labelText: ' Адрес доставки',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _isOrdering ? null : _submitOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B35),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30)),
                                ),
                                child: _isOrdering
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Text('Оплатить',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.1), blurRadius: 10)
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Итого',
                              style: TextStyle(color: Colors.grey[600])),
                          Text('$total ₽',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF6B35))),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _createOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Оформить',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

//ЗАКАЗЫ
class OrdersScreen extends StatefulWidget {
  final String userId;
  const OrdersScreen({super.key, required this.userId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final res = await http.get(Uri.parse(
          'http://localhost:8080/api/orders?userId=${widget.userId}'));
      if (res.statusCode == 200)
        setState(() => _orders = json.decode(res.body));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(' Заказы'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders)
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('Нет заказов'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFF6B35),
                            child: Text('${order['id']}')),
                        title: Text('Заказ #${order['id']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${order['total']} ₽ • ${order['status']}'),
                            if (order['address'] != null &&
                                order['address'].isNotEmpty)
                              Text(' ${order['address']}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: (order['items'] as List)
                                  .map((item) => ListTile(
                                      title: Text(item['name']),
                                      trailing: Text(
                                          '${item['quantity']} x ${item['price']} ₽')))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

//СОСТОЯНИЕ КОРЗИНЫ
class _CartState extends StatefulWidget {
  const _CartState({required this.child});
  final Widget child;

  @override
  State<_CartState> createState() => _CartStateState();
}

class _CartStateState extends State<_CartState> {
  static List<CartItem> _cartItemsStatic = [];

  static void clearCartStatic() {
    _cartItemsStatic.clear();
  }

  List<CartItem> get _cartItems => _cartItemsStatic;
  int get _itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  void _addItem(int id, String name, String desc, String img, int price) {
    setState(() {
      final existing = _cartItems.indexWhere((i) => i.id == id);
      if (existing != -1)
        _cartItems[existing].quantity++;
      else
        _cartItems.add(CartItem(
            id: id,
            name: name,
            description: desc,
            imagePath: img,
            price: price));
    });
  }

  void _removeItem(int id) =>
      setState(() => _cartItems.removeWhere((i) => i.id == id));
  void _updateQuantity(int id, int q) => setState(() {
        final index = _cartItems.indexWhere((i) => i.id == id);
        if (index != -1) {
          if (q <= 0)
            _cartItems.removeAt(index);
          else
            _cartItems[index].quantity = q;
        }
      });
  void _clearCart() => setState(() => _cartItems.clear());

  @override
  Widget build(BuildContext context) {
    return CartProvider(
      cartItems: _cartItems,
      itemCount: _itemCount,
      addItem: _addItem,
      removeItem: _removeItem,
      updateQuantity: _updateQuantity,
      clearCart: _clearCart,
      child: widget.child,
    );
  }
}
