import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/user.dart' as model;

class AuthService {
  final _supabase = Supabase.instance.client;

  // Получение текущей сессии
  Future<Session?> get currentSession async {
    try {
      return _supabase.auth.currentSession;
    } catch (e) {
      return null;
    }
  }

  // Получение текущего пользователя
  Future<model.User?> getCurrentUser() async {
    try {
      final session = await currentSession;
      if (session == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .single();

      return model.User(
        id: session.user.id,
        email: session.user.email!,
        fullName: response['full_name'],
        phone: response['phone'],
        imageUrl: response['avatar_url'],
      );
    } catch (e) {
      debugPrint('Ошибка получения пользователя: $e');
      return null;
    }
  }

  // Проверка авторизации
  Future<bool> get isAuthenticated async {
    final session = await currentSession;
    return session != null;
  }

  // Проверка существования email
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: 'temp_password', // Временный пароль для проверки
      );
      await _supabase.auth.signOut(); // Сразу выходим
      return true; // Если дошли до этой точки, значит пользователь существует
    } catch (e) {
      return false; // Если получили ошибку, значит пользователя нет
    }
  }

  // Регистрация
  Future<model.User> signUp({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Начало регистрации для $email');
      
      // Регистрируем пользователя
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'email_confirmed': true,
        },
      );

      debugPrint('Ответ от signUp: ${response.user?.id}');

      if (response.user == null) {
        debugPrint('Ошибка: пользователь не создан');
        throw Exception('REGISTRATION_FAILED');
      }

      debugPrint('Создание профиля для пользователя ${response.user!.id}');
      
      try {
        // Создаем запись в profiles
        await _supabase.from('profiles').upsert({
          'id': response.user!.id,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        }).select();

        debugPrint('Профиль успешно создан');
      } catch (e) {
        debugPrint('Ошибка создания профиля: $e');
        // Если не удалось создать профиль, удаляем пользователя
        await _supabase.auth.admin.deleteUser(response.user!.id);
        throw Exception('PROFILE_CREATION_FAILED');
      }

      // Возвращаем пользователя
      return model.User(
        id: response.user!.id,
        email: email,
        fullName: null,
        phone: null,
        imageUrl: null,
      );
    } catch (e) {
      debugPrint('Ошибка при регистрации: $e');
      if (e.toString().contains('User already registered')) {
        throw Exception('EMAIL_EXISTS');
      }
      rethrow;
    }
  }

  // Вход
  Future<model.User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Попытка входа для $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('Ответ от signIn: ${response.user?.id}');

      if (response.user == null) {
        debugPrint('Ошибка: неверные учетные данные');
        throw Exception('INVALID_CREDENTIALS');
      }

      debugPrint('Получение профиля пользователя');

      // Получаем или создаем профиль
      try {
        final profile = await _supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();

        debugPrint('Профиль найден: ${profile['id']}');

        return model.User(
          id: response.user!.id,
          email: email,
          fullName: profile['full_name'],
          phone: profile['phone'],
          imageUrl: profile['avatar_url'],
        );
      } catch (e) {
        debugPrint('Профиль не найден, создаем новый');
        
        // Если профиль не найден, создаем его
        await _supabase.from('profiles').upsert({
          'id': response.user!.id,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        });

        return model.User(
          id: response.user!.id,
          email: email,
          fullName: null,
          phone: null,
          imageUrl: null,
        );
      }
    } catch (e) {
      debugPrint('Ошибка при входе: $e');
      if (e.toString().contains('Invalid login credentials')) {
        throw Exception('INVALID_CREDENTIALS');
      }
      rethrow;
    }
  }

  // Обновление профиля пользователя
  Future<model.User> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? imageUrl,
  }) async {
    // Обновляем профиль в базе данных
    await _supabase.from('profiles').update({
      if (fullName != null) 'full_name': fullName,
      if (phone != null) 'phone': phone,
      if (imageUrl != null) 'avatar_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    // Получаем обновленный профиль
    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    // Возвращаем обновленного пользователя
    return model.User(
      id: userId,
      email: profile['email'],
      fullName: profile['full_name'],
      phone: profile['phone'],
      imageUrl: profile['avatar_url'],
    );
  }

  // Выход
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
