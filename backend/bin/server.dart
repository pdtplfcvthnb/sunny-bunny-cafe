import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

final _headers = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

List<Map<String, dynamic>> _menu = [
  {
    'id': 1,
    'name': 'мокко брауни',
    'description':
        'горячий шоколад с добавлением эспрессо, сиропа брауни и шоколадной стружки',
    'price': 490,
    'category': 'напитки'
  },
  {
    'id': 2,
    'name': 'капучино',
    'description': 'эспрессо с добавлением вспененного молока',
    'price': 290,
    'category': 'напитки'
  },
  {
    'id': 3,
    'name': 'латте',
    'description': 'смесь из молочной пены, молока и эспрессо',
    'price': 370,
    'category': 'напитки'
  },
  {
    'id': 4,
    'name': 'тыквенный с беконом',
    'description': 'суп пюре из тыквы, подается с гренками и красным маслом',
    'price': 670,
    'category': 'обеды'
  },
  {
    'id': 5,
    'name': 'цезарь',
    'description': 'классика',
    'price': 650,
    'category': 'салаты'
  },
  {
    'id': 6,
    'name': 'средиземноморская паста',
    'description':
        'паста с кальмарами, креветками, мидиями в томатном соусе и стружкой тунца',
    'price': 890,
    'category': 'ужины'
  },
  {
    'id': 7,
    'name': 'панкейки шоколадные',
    'description':
        'пышные панкейки с добавлением банана, щедро политые шоколадным кремом и посыпанны ореховой крошкой',
    'price': 670,
    'category': 'десерты'
  }
];

List<Map<String, dynamic>> _orders = [];
int _nextOrderId = 1;
int _nextId = 8;

Middleware _corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _headers);
      }
      final response = await handler(request);
      return response.change(headers: _headers);
    };
  };
}

Response _getMenu(Request req) {
  return Response.ok(json.encode(_menu), headers: _headers);
}

Future<Response> _postMenu(Request req) async {
  try {
    final body = json.decode(await req.readAsString());
    final newItem = {
      'id': _nextId++,
      'name': body['name'],
      'description': body['description'],
      'price': body['price'],
      'category': body['category'],
    };
    _menu.add(newItem);
    return Response.ok(json.encode(newItem), headers: _headers);
  } catch (e) {
    return Response.badRequest(
        body: json.encode({'error': 'Ошибка добавления блюда'}));
  }
}

Future<Response> _deleteMenu(Request req) async {
  try {
    final id = int.parse(req.url.pathSegments.last);
    _menu.removeWhere((item) => item['id'] == id);
    return Response.ok(json.encode({'message': 'Блюдо удалено'}),
        headers: _headers);
  } catch (e) {
    return Response.badRequest(body: json.encode({'error': 'Ошибка удаления'}));
  }
}

Future<Response> _createOrder(Request req) async {
  try {
    final body = json.decode(await req.readAsString());
    final order = {
      'id': _nextOrderId++,
      'userId': body['userId'],
      'items': body['items'],
      'total': body['total'],
      'phone': body['phone'] ?? '',
      'address': body['address'] ?? '',
      'status': 'новый',
      'created_at': DateTime.now().toIso8601String(),
    };
    _orders.add(order);
    return Response.ok(json.encode(order), headers: _headers);
  } catch (e) {
    return Response.badRequest(
        body: json.encode({'error': 'Ошибка создания заказа'}));
  }
}

Response _getOrders(Request req) {
  try {
    final userId = req.url.queryParameters['userId'];
    if (userId != null) {
      final userOrders =
          _orders.where((order) => order['userId'] == userId).toList();
      return Response.ok(json.encode(userOrders), headers: _headers);
    }
    return Response.ok(json.encode(_orders), headers: _headers);
  } catch (e) {
    return Response.ok(json.encode(_orders), headers: _headers);
  }
}

final _router = Router()
  ..get('/api/menu', _getMenu)
  ..post('/api/menu', _postMenu)
  ..delete('/api/menu/<id>', _deleteMenu)
  ..post('/api/orders', _createOrder)
  ..get('/api/orders', _getOrders);

void main() async {
  final handler = Pipeline()
      .addMiddleware(_corsMiddleware())
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  final server = await io.serve(handler, 'localhost', 8080);
  print(' Кафе "Солнечный зайчик" API запущено!');
  print(' http://localhost:8080/api/menu');
  print(' Меню содержит ${_menu.length} блюд');
}
