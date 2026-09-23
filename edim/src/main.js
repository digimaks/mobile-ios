import { mobileApp } from '@edim/mobile-ui';
import '@edim/mobile-ui/dist/style.css';

window.lxBridge = {
  postMessage: (bridgeName, payload) => {
    if (window.webkit?.messageHandlers?.[bridgeName]) {
      window.webkit.messageHandlers[bridgeName].postMessage(payload);
    } else {
      console.warn(`No bridge found '${bridgeName}'`, payload);
    }
  },
};

mobileApp.mount('#app');