# Guía de Configuración de Firebase para HeyTeacher!

## 📋 Paso 1: Crear Proyecto en Firebase

1. Ir a [Firebase Console](https://console.firebase.google.com)
2. Click en "Agregar proyecto"
3. Nombre del proyecto: `HeyTeacher`
4. Habilitar Google Analytics (opcional)
5. Crear proyecto

## 📱 Paso 2: Configurar Apps

### Android

1. En Firebase Console, click en el ícono de Android
2. Package name: `com.example.hey_teacher_app`
3. App nickname: `HeyTeacher Android`
4. Descargar `google-services.json`
5. Colocar archivo en: `android/app/google-services.json`

### iOS

1. En Firebase Console, click en el ícono de iOS
2. Bundle ID: `com.example.heyTeacherApp`
3. App nickname: `HeyTeacher iOS`
4. Descargar `GoogleService-Info.plist`
5. Colocar archivo en: `ios/Runner/GoogleService-Info.plist`

## 🔐 Paso 3: Configurar Authentication

1. En Firebase Console, ir a **Authentication**
2. Click en "Comenzar"
3. Habilitar **Email/Password**
4. Guardar cambios

**Configuración adicional (opcional):**
- Personalizar emails de verificación
- Configurar dominios autorizados

## 💾 Paso 4: Configurar Cloud Firestore

1. Ir a **Firestore Database**
2. Click en "Crear base de datos"
3. Seleccionar modo: **Modo de prueba** (para desarrollo)
4. Seleccionar ubicación: `southamerica-east1` (São Paulo)
5. Click en "Habilitar"

### Reglas de Seguridad de Firestore

Ir a la pestaña "Reglas" y pegar:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && isOwner(userId);
      allow update: if isSignedIn() && isOwner(userId);
      allow delete: if isSignedIn() && isOwner(userId);
    }
    
    // Teacher profiles
    match /teacher_profiles/{userId} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && isOwner(userId);
    }
    
    // Institution profiles
    match /institution_profiles/{userId} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && isOwner(userId);
    }
    
    // Jobs collection
    match /jobs/{jobId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isSignedIn() && 
        (isOwner(resource.data.postedBy) || 
         request.auth.token.admin == true);
      allow delete: if isSignedIn() && 
        (isOwner(resource.data.postedBy) || 
         request.auth.token.admin == true);
    }
    
    // Applications collection
    match /applications/{applicationId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isSignedIn();
      allow delete: if isSignedIn() && 
        isOwner(resource.data.teacherId);
    }
    
    // Materials collection
    match /materials/{materialId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update: if isSignedIn() && 
        (isOwner(resource.data.uploadedBy) || 
         request.auth.token.admin == true);
      allow delete: if isSignedIn() && 
        (isOwner(resource.data.uploadedBy) || 
         request.auth.token.admin == true);
    }
    
    // User notifications
    match /users/{userId}/notifications/{notificationId} {
      allow read: if isSignedIn() && isOwner(userId);
      allow write: if isSignedIn() && isOwner(userId);
    }
  }
}
```

**Publicar reglas**: Click en "Publicar"

## 📦 Paso 5: Configurar Cloud Storage

1. Ir a **Storage**
2. Click en "Comenzar"
3. Iniciar en **Modo de prueba**
4. Seleccionar ubicación: `southamerica-east1`
5. Click en "Listo"

### Reglas de Seguridad de Storage

Ir a la pestaña "Reglas" y pegar:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // CVs - only owner can read/write
    match /cvs/{userId}/{fileName} {
      allow read: if isSignedIn() && isOwner(userId);
      allow write: if isSignedIn() && isOwner(userId) &&
                     request.resource.size < 5 * 1024 * 1024; // 5MB limit
    }
    
    // Certifications - only owner can write, all can read
    match /certifications/{userId}/{fileName} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && isOwner(userId) &&
                     request.resource.size < 5 * 1024 * 1024;
    }
    
    // Teaching materials - all can read, owner can write
    match /materials/{userId}/{fileName} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && isOwner(userId) &&
                     request.resource.size < 10 * 1024 * 1024; // 10MB limit
    }
    
    // Profile photos
    match /profile_photos/{fileName} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() &&
                     request.resource.size < 2 * 1024 * 1024 && // 2MB limit
                     request.resource.contentType.matches('image/.*');
    }
    
    // Institution logos
    match /institution_logos/{fileName} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() &&
                     request.resource.size < 2 * 1024 * 1024 &&
                     request.resource.contentType.matches('image/.*');
    }
  }
}
```

**Publicar reglas**: Click en "Publicar"

## 🔔 Paso 6: Configurar Cloud Messaging

1. Ir a **Cloud Messaging**
2. La configuración básica ya está lista con el SDK

### Para Android:
Agregar al archivo `android/app/build.gradle`:

```gradle
dependencies {
    // Firebase Cloud Messaging
    implementation 'com.google.firebase:firebase-messaging:23.0.0'
}
```

### Para iOS:
1. Abrir proyecto en Xcode
2. Ir a **Capabilities**
3. Habilitar **Push Notifications**
4. Habilitar **Background Modes** > **Remote notifications**

## 🔍 Paso 7: Índices de Firestore

Los índices compuestos se crearán automáticamente cuando la app los requiera. Firebase mostrará un error con un link para crearlos.

**Índices recomendados para crear manualmente:**

1. Colección `jobs`:
   - Campos: `status` (Ascending), `postedAt` (Descending)
   - Campos: `postedBy` (Ascending), `postedAt` (Descending)

2. Colección `applications`:
   - Campos: `jobId` (Ascending), `appliedAt` (Descending)
   - Campos: `teacherId` (Ascending), `appliedAt` (Descending)

3. Colección `materials`:
   - Campos: `category` (Ascending), `uploadedAt` (Descending)
   - Campos: `uploadedBy` (Ascending), `uploadedAt` (Descending)

## 📊 Paso 8: Configurar Analytics (Opcional)

1. Ir a **Analytics**
2. Eventos personalizados ya están configurados en el código
3. Revisar dashboard después de algunos días de uso

## 🚀 Paso 9: Desplegar Cloud Functions (Futuro)

Para funcionalidades avanzadas como:
- Matching inteligente de vacantes
- Notificaciones automáticas
- Procesamiento de imágenes

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Inicializar functions
firebase init functions

# Desplegar
firebase deploy --only functions
```

## ✅ Checklist Final

- [ ] Proyecto Firebase creado
- [ ] Apps Android e iOS configuradas
- [ ] Authentication habilitado (Email/Password)
- [ ] Firestore creado con reglas de seguridad
- [ ] Storage configurado con reglas de seguridad
- [ ] Cloud Messaging configurado
- [ ] Archivos de configuración descargados
- [ ] Archivos colocados en ubicaciones correctas
- [ ] Índices de Firestore creados

## 🔒 Producción

**Antes de lanzar a producción:**

1. Cambiar reglas de Firestore y Storage de "modo prueba" a reglas restrictivas
2. Configurar límites de uso y alertas de facturación
3. Habilitar App Check para proteger contra abuso
4. Configurar dominios autorizados en Authentication
5. Revisar y optimizar índices de Firestore
6. Configurar backup automático de Firestore

## 📱 URLs Importantes

- Firebase Console: https://console.firebase.google.com
- Documentación: https://firebase.google.com/docs
- Precios: https://firebase.google.com/pricing

## 🆘 Troubleshooting

**Error: "No se encuentra google-services.json"**
- Verificar que el archivo esté en `android/app/`
- Ejecutar `flutter clean` y `flutter pub get`

**Error: "GoogleService-Info.plist not found"**
- Agregar archivo en Xcode, no solo en el Finder
- Asegurarse que esté en el target correcto

**Error de permisos en Firestore:**
- Verificar que las reglas estén publicadas
- Verificar que el usuario esté autenticado
- Revisar los logs en Firebase Console

## 💡 Tips

- Usar **Firestore Emulator** para desarrollo local
- Configurar diferentes proyectos para dev/staging/prod
- Monitorear costos regularmente
- Implementar paginación para consultas grandes
- Usar caché de Firestore para reducir lecturas

---

¡Firebase configurado exitosamente! 🎉
