import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BaseService<T> {
  final SupabaseClient supabase = Supabase.instance.client;
  final String table;

  BaseService(this.table);

  /// Convert JSON to strongly-typed model
  T fromJson(Map<String, dynamic> json);

  /// Get all records
  Future<List<T>> getAll({
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = false,
  }) async {
    try {
      dynamic query = supabase.from(table).select();

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      final response = await query;

      return (response as List)
          .map((json) => fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch data from $table: $e');
    }
  }

  /// Get single record by ID
  Future<T?> getById(String id) async {
    try {
      final response = await supabase
          .from(table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch record from $table: $e');
    }
  }

  /// Insert new record
  Future<T> insert(Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(table)
          .insert(data)
          .select()
          .single();

      return fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to insert into $table: $e');
    }
  }

  /// Update record
  Future<T> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from(table)
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update $table: $e');
    }
  }

  /// Delete record
  Future<void> delete(String id) async {
    try {
      await supabase.from(table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete from $table: $e');
    }
  }
}