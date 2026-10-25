# La versión release pasa por R8, que acorta los nombres de las clases. JNA busca por nombre,
# desde C, los campos de sus clases (com.sun.jna.Pointer.peer) y los métodos de Vosk: si R8 los
# renombra, la app se cae al abrir con «Can't obtain peer field ID» (Samsung, domingo 00:03).
-keep class com.sun.jna.** { *; }
-keepclassmembers class * extends com.sun.jna.** { public *; }
-keep class org.vosk.** { *; }
-dontwarn java.awt.**
