# ML Kit e Play Services: le classi caricate per riflessione vanno tenute.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# WorkManager usa Room: il database generato si crea per riflessione.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
