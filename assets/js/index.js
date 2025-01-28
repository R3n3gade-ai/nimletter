// Copyright Thomas T. Jarløv (TTJ) - ttj@ttj.dk

const dqs  = document.querySelector.bind(document);

const dqsA = document.querySelectorAll.bind(document);

const qs = (elm, qs) => {
    return elm.querySelector(qs);
}

const qsA = (elm, qs) => {
    return elm.querySelectorAll(qs);
}





function manageErrors(response) {
  if(!response.ok){
    const responseError = {
      bodyUsed: response.bodyUsed,
      redirected: response.redirected,
      type: response.type,
      url: response.url,
      statusText: response.statusText,
      status: response.status
    };
    if (response.status == 401) {
      manageErrorsMsg("error", ("Http401"))
    } else if (response.status == 400) {
      response.text().then((text) => {
        manageErrorsMsg("error", text || "Error400");
      });
    } else if (response.status == 403) {
      response.text().then((text) => {
        if (text != "") {
          manageErrorsMsg("error", text)
        } else {
          manageErrorsMsg("error", ("NoAccess"))
        }
      });
    } else if (response.status == 404) {
      manageErrorsMsg("error", ("Error404"));
    } else if (response.status == 413) {
      manageErrorsMsg("error", ("FileLimit"));
    } else if (response.status == 429) { // Rate limit
      manageErrorsMsg("error", text);
    } else if (response.status == 499) {
      manageErrorsMsg("info", "You are faster than you internet connection.");
    } else if (response.status == 500) {
      onErrorSendPrivate(
        "Error500:" + response.statusText,
        response.url, "", "",
        "", ""
      );
      manageErrorsMsg("error", "Sorry, got an error. Please let us know what happened in the chat-support.");
    } else if (response.status == 502) {
      onErrorSendPrivate(
        "Error502:" + response.statusText,
        response.url, "", "",
        "", ""
      );
      manageErrorsMsg("error", ("Error502"));
    } else {
      console.log(("NoConnection"));
    }

    throw(responseError);
  }
  return response;
}
function manageErrorsMsg(errorType, text) {
  alert(text);
}


/*
  JS creator
*/
function jsCreateElement(tagName, { attrs = {}, children = [], rawHtml = [] } = {}){
  return {
    tagName,
    attrs,
    children,
    rawHtml
  }
}

function jsRender({ tagName, attrs = {}, children = [], rawHtml = [] }){
  let element = document.createElement(tagName);
  rawHtml.forEach(html => {
    element.innerHTML += html;
  });
  children.forEach( child =>  {
    if (typeof child === 'string'){
      element.appendChild(document.createTextNode(child));
    }
    else {
      element.appendChild(jsRender(child));
    }
  });
  if (Object.keys(attrs).length){
    for (const [key, value] of Object.entries(attrs)) {
      if ((key === 'checked' || key === 'selected' || key == 'open' || key == 'disabled') && value === false) {
        continue;
      }
      element.setAttribute(key, value);
    }
  }
  return element;
};

const jsOn = (selector, eventType, childSelector, eventHandler) => {
  const elements = document.querySelectorAll(selector);
  for (let element of elements) {
    element.addEventListener(eventType, (eventOnElement) => {
      if (eventOnElement.target.matches(childSelector)) {
        eventHandler(eventOnElement);
      }
    });
  }
};
const jsOnSpecific = (selector, eventType, eventHandler) => {
  const elements = document.querySelectorAll(selector);
  for (let element of elements) {
    element.addEventListener(eventType, (eventOnElement) => {
      eventHandler(eventOnElement);
    });
  }
};


/*
  Modal loader
*/
function rawModalSuccess(msg) {
  const html = jsCreateElement("div", {
    attrs: {
      style: 'width: 300px;'
    },
    children: [
      jsCreateElement("div", {
        attrs: {
          class: "modal-header"
        },
        rawHtml: [
          '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" /></svg>'
        ]
      }),
      jsCreateElement('div', {
        attrs: {
          class: "center mt10 mb20" + (msg == null ? " hideme" : "")
        },
        rawHtml: [
          msg
        ]
      }),
      jsCreateElement("button", {
        attrs: {
          class: "buttonIcon",
          onclick: "dqs('.modalpop').classList.remove('show')"
        },
        rawHtml: [
          'Close'
        ]
      })
    ]
  });
  rawModalLoader(jsRender(html));
}
function rawModalError(msg) {
  const html = jsCreateElement("div", {
    attrs: {
      style: 'width: 300px;'
    },
    children: [
      jsCreateElement("div", {
        attrs: {
          class: "modal-header"
        },
        rawHtml: [
          '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-6"><path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m0-10.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.75c0 5.592 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.57-.598-3.75h-.152c-3.196 0-6.1-1.25-8.25-3.286Zm0 13.036h.008v.008H12v-.008Z" /></svg>'
        ]
      }),
      jsCreateElement('div', {
        attrs: {
          class: "center mt10 mb20" + (msg == null ? " hideme" : "")
        },
        rawHtml: [
          msg
        ]
      }),
      jsCreateElement("button", {
        attrs: {
          class: "buttonIcon",
          onclick: "dqs('.modalpop').classList.remove('show')"
        },
        rawHtml: [
          'Close'
        ]
      })
    ]
  });
  rawModalLoader(jsRender(html));
}
function rawModalLoader(content) {
  if (dqs(".modalpop")) {
    dqs(".modalpop").remove();
  }

  const modal = jsRender(
    jsCreateElement("div", {
      attrs: {
        class: "modalpop"
      },
      children: [
        jsCreateElement("div", {
          attrs: {
            class: "modal-content"
          }
        })
      ]
    })
  );
  qs(modal, ".modal-content").appendChild(content);
  document.getElementsByTagName("body")[0].appendChild(modal);

  setTimeout(() => {
    modal.classList.add("show");
  }, 10);

  window.onclick = function(event) {
    if (event.target == modal && !modal.classList.contains("confirmclose")) {
      modal.classList.remove('show');
    }
  }
}



/*
loadScriptManually("js/myscript.js").then(function(){ console.log("script loaded"); });
await loadScriptManually("js/myscript.js");
*/
function loadScriptManually(src, isModule = false) {
  return new Promise(function (resolve, reject) {
    if (dqs("script[src='" + src + "']") == null) {
      var script = document.createElement('script');
      script.onload = function () {
          resolve();
      };
      script.onerror = function () {
          reject();
      };
      script.type = (isModule) ? "module" : "text/javascript";
      script.src = src;
      document.body.appendChild(script);
    } else {
      resolve();
    }
  });
}

function isScriptInjected(src) {
  return (dqs("script[src='" + src + "']") != null);
}

function loadStylesheetManually(src) {
  return new Promise(function (resolve, reject) {
    if (dqs("link[href='" + src + "']") == null) {
      var script = document.createElement('link');
      script.onload = function () {
          resolve();
      };
      script.onerror = function () {
          reject();
      };
      script.rel = "stylesheet";
      script.href = src;
      document.body.appendChild(script);
    } else {
      resolve();
    }
  });
}

function isStylesheetInjected(src) {
  return (dqs("link[href='" + src + "']") != null);
}


/*
  Label designer
*/
function labelFloater() {
  const elements = document.querySelectorAll('textarea, input, select');
  elements.forEach(element => {
    element.addEventListener('focus', () => {
      const label = element.previousElementSibling;
      if (label && label.tagName.toLowerCase() === 'label') {
        label.classList.add('floatup');
      }
    });
    element.addEventListener('blur', () => {
      const label = element.previousElementSibling;
      if (label && label.tagName.toLowerCase() === 'label') {
        label.classList.remove('floatup');
      }
    });
  });
}