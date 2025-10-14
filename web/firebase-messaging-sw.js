// Import the functions you need from the SDKs you need
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyBMB1fPsacFXOmvIkgF9q2fxAEjgm50HL4",
  authDomain: "oficinaescolar-colaboradores.firebaseapp.com",
  projectId: "oficinaescolar-colaboradores",
  storageBucket: "oficinaescolar-colaboradores.firebasestorage.app",
  messagingSenderId: "424263278007",
  appId: "1:424263278007:web:ab6f8571ed8b0100b61c32",
  measurementId: "G-6XPGRHNWP0"
};

// Initialize Firebase
//const app = initializeApp(firebaseConfig);
const app = firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// Manejador de mensajes en segundo plano
messaging.onBackgroundMessage((payload) => {
    // ... tu lógica para mostrar la notificación aquí ...
    const notificationTitle = payload.notification.title || 'Mensaje de FCM';
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/favicon.png' 
    };
    return self.registration.showNotification(notificationTitle, notificationOptions);
});