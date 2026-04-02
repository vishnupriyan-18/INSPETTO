// To support Firebase Cloud Messaging on Web
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

// Dummy initialization to suppress missing service worker errors on flutter web
firebase.initializeApp({
  apiKey: "dummy-key",
  projectId: "dummy-project",
  messagingSenderId: "dummy-sender",
  appId: "dummy-app",
});

const messaging = firebase.messaging();
