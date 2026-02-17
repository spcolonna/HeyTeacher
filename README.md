# HeyTeacher! - English Teachers Platform

Una plataforma móvil diseñada para conectar a la comunidad docente de inglés en Uruguay con instituciones educativas, recursos pedagógicos y beneficios exclusivos.

## 📱 Descripción

**HeyTeacher!** es una aplicación móvil construida con Flutter y Firebase que ofrece:

- **Bolsa de Empleo Inteligente**: Sistema de matching entre docentes e instituciones
- **Repositorio de Materiales**: The Teacher's Toolbox con recursos pedagógicos
- **Sistema de Notificaciones**: Alertas push para nuevas oportunidades
- **Perfiles Profesionales**: Gestión de CV, certificaciones y disponibilidad

## 🛠 Tecnologías

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Cloud Storage
  - Cloud Messaging (Push Notifications)
- **Arquitectura**: Provider (State Management)

## 📋 Requisitos Previos

- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Android Studio / Xcode
- Cuenta de Firebase

## 🚀 Configuración del Proyecto

### 1. Clonar o descargar el proyecto

```bash
cd hey_teacher_app
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Firebase

#### Para Android:
1. Crear proyecto en [Firebase Console](https://console.firebase.google.com)
2. Agregar app Android con package name: `com.example.hey_teacher_app`
3. Descargar `google-services.json`
4. Colocar en: `android/app/google-services.json`

#### Para iOS:
1. Agregar app iOS en Firebase Console
2. Descargar `GoogleService-Info.plist`
3. Colocar en: `ios/Runner/GoogleService-Info.plist`

### 4. Configurar servicios de Firebase

Habilitar en Firebase Console:
- ✅ Authentication (Email/Password)
- ✅ Cloud Firestore
- ✅ Cloud Storage
- ✅ Cloud Messaging

### 5. Estructura de Firestore

Colecciones necesarias:

```
users/
  {userId}/
    - email: string
    - userType: string (teacher | institution | admin)
    - displayName: string
    - createdAt: timestamp
    
jobs/
  {jobId}/
    - postedBy: string
    - institutionName: string
    - jobTitle: string
    - description: string
    - location: string
    - shifts: array
    - levels: array
    - status: string
    - postedAt: timestamp
    
applications/
  {applicationId}/
    - jobId: string
    - teacherId: string
    - teacherName: string
    - appliedAt: timestamp
    - status: string
    
materials/
  {materialId}/
    - title: string
    - description: string
    - category: string
    - uploadedBy: string
    - uploadedAt: timestamp
    - downloadCount: number
```

### 6. Reglas de seguridad de Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Jobs
    match /jobs/{jobId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.postedBy;
    }
    
    // Applications
    match /applications/{applicationId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    
    // Materials
    match /materials/{materialId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.uploadedBy;
    }
  }
}
```

### 7. Reglas de Storage

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /cvs/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    match /materials/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    match /profile_photos/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## 🏃 Ejecutar la aplicación

```bash
# Verificar dispositivos disponibles
flutter devices

# Ejecutar en modo debug
flutter run

# Ejecutar en dispositivo específico
flutter run -d <device_id>

# Build para producción Android
flutter build apk --release

# Build para producción iOS
flutter build ios --release
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── models/                   # Modelos de datos
│   ├── app_user.dart
│   ├── job_posting.dart
│   ├── teaching_material.dart
│   └── ...
├── services/                 # Servicios (Firebase)
│   ├── auth_service.dart
│   ├── job_service.dart
│   ├── material_service.dart
│   └── ...
├── providers/                # State Management
│   └── auth_provider.dart
├── screens/                  # Pantallas
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── jobs/
│   ├── materials/
│   └── profile/
└── widgets/                  # Componentes reutilizables
```

## 🎯 Funcionalidades Implementadas (MVP)

### ✅ Autenticación
- Registro de usuarios (Docente/Institución)
- Login con email y contraseña
- Recuperación de contraseña
- Gestión de sesión

### ✅ Bolsa de Empleo
- Listado de vacantes activas
- Detalle de vacante
- Publicar vacante (Instituciones)
- Postular a vacante (Docentes)
- Sistema de filtros básico

### ✅ Materiales Pedagógicos
- Repositorio categorizado
- Filtros por categoría
- Grid view de materiales
- Contador de descargas

### ✅ Perfil de Usuario
- Visualización de perfil
- Información de cuenta
- Cerrar sesión

## 🔜 Próximas Funcionalidades

- [ ] Sistema completo de notificaciones push
- [ ] Gamificación (Trivia de inglés)
- [ ] Marketplace de beneficios
- [ ] Chat entre instituciones y docentes
- [ ] Sistema de reviews/ratings
- [ ] Búsqueda avanzada con filtros
- [ ] Exportar CV en PDF
- [ ] Calendario de disponibilidad
- [ ] Dashboard de estadísticas

## 🐛 Testing

```bash
# Ejecutar tests
flutter test

# Generar coverage
flutter test --coverage
```

## 📱 Capturas de Pantalla

(Agregar screenshots de la app)

## 👥 Tipos de Usuario

1. **Teacher (Docente)**
   - Crear perfil profesional
   - Buscar y postular a empleos
   - Acceder a materiales
   - Recibir notificaciones de matching

2. **Institution (Institución)**
   - Publicar vacantes
   - Gestionar postulantes
   - Ver aplicaciones recibidas

3. **Admin (Administrador)**
   - Control total del contenido
   - Moderación de publicaciones
   - Gestión de usuarios

## 🔐 Seguridad

- Autenticación mediante Firebase Auth
- Reglas de seguridad en Firestore y Storage
- Validación de datos en cliente y servidor
- Permisos basados en roles

## 📄 Licencia

Este proyecto es un MVP/prototipo funcional para HeyTeacher!

## 📞 Contacto

Para consultas sobre el proyecto, contactar a través de GitHub.

---

**Nota**: Este es un prototipo funcional básico. Se recomienda implementar las funcionalidades adicionales y realizar testing exhaustivo antes de lanzar a producción.
