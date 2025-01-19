import { authServiceExternal } from "../services/indexExternal.js";


dqs("#work").innerHTML = "";

const html = jsCreateElement('div', {
  attrs: {
    id: 'loginForm',
    class: 'headingH2',
    style: 'margin: auto;max-width: 400px;'
  },
  children: [
    // Honeypot
    jsCreateElement('div', {
      attrs: {
        class: 'itemBlock mb20 hideme'
      },
      children: [
        jsCreateElement('label', {
          attrs: {
            class: 'forinput'
          },
          children: ['Username']
        }),
        jsCreateElement('input', {
          attrs: {
            type: 'text',
            id: 'username_second'
          }
        })
      ]
    }),
    jsCreateElement('div', {
      attrs: {
        class: 'itemBlock mb20 passwordMain'
      },
      children: [
        jsCreateElement('label', {
          attrs: {
            class: 'forinput'
          },
          children: ['Email']
        }),
        jsCreateElement('input', {
          attrs: {
            type: 'email',
            id: 'email'
          }
        })
      ]
    }),
    jsCreateElement('div', {
      attrs: {
        class: 'itemBlock mb20 passwordMain'
      },
      children: [
        jsCreateElement('label', {
          attrs: {
            class: 'forinput'
          },
          children: ['Password']
        }),
        jsCreateElement('input', {
          attrs: {
            type: 'password',
            id: 'password'
          }
        })
      ]
    }),
    jsCreateElement('div', {
      attrs: {
        class: 'itemBlock mb20 hideme'
      },
      children: [
        jsCreateElement('label', {
          attrs: {
            class: 'forinput'
          },
          children: ['Yubikey OTP']
        }),
        jsCreateElement('input', {
          attrs: {
            type: 'text',
            id: 'yubikeyOTP'
          }
        })
      ]
    }),
    jsCreateElement('div', {
      attrs: {
        class: 'itemBlock mb20'
      },
      children: [
        jsCreateElement('button', {
          attrs: {
            type: 'button',
            class: 'buttonIcon',
            id: 'login'
          },
          children: ['Login']
        })
      ]
    })
  ]
});

dqs("#work").appendChild(jsRender(html));

jsOnSpecific("#password", "keyup", (e) => {
  if (e.key === "Enter") {
    doLogin();
  }
});
jsOnSpecific("#yubikeyOTP", "keyup", (e) => {
  if (e.key === "Enter") {
    doLogin();
  }
});


jsOnSpecific("#login", "click", () => {
  doLogin();
});

async function doLogin() {
  const resp = await authServiceExternal.login(
    dqs("#email").value,
    dqs("#password").value,
    dqs("#yubikeyOTP").value,
    dqs("#username_second").value
  );
  console.log(resp);

  if (!resp.success) {
    alert(resp.message);
    return;
  }

  if (resp.otpRequired && resp.otpProvided == "") {
    dqs("#yubikeyOTP").value = "";
    dqs("#yubikeyOTP").parentNode.classList.remove("hideme");
    dqsA(".passwordMain").forEach((el) => {
      el.classList.add("hideme");
    });
    return;
  }

  window.location.href = "/";
}