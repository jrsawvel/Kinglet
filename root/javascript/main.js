
const App = {

    init() {
        this.registerServiceWorker();
    },

    registerServiceWorker() {
        if ('serviceWorker' in navigator) {
            navigator.serviceWorker.register('/sw.js', { scope: '/' });
            console.log('Service Worker registered successfully.');
        }
    }
};

(() => {
  App.init()
})()

