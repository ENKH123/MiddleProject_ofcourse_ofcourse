import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  SupabaseManager._();

  static final SupabaseManager instance = SupabaseManager._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://dbhecolzljfrmgtdjwie.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRiaGVjb2x6bGpmcm1ndGRqd2llIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwNzc2MTQsImV4cCI6MjA3NzY1MzYxNH0.BsKpELVM0vmihAPd37CDs-fm0sdaVZGeNuBaGlgFOac',
    );

    debugPrint("🔥 Supabase initialized");
  }
}
