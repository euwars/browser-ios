(function() {
  window.addEventListener("pagehide", function() { // beforeunload is not supported
    webkit.messageHandlers.pageUnloadMessageHandler.postMessage({"event":"pagehide"});
  });
})()