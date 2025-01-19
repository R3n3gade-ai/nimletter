import { authService } from "../services/indexInternal.js";


const profile = await authService.getProfile();


dqs("#heading").innerText = "Profile";
dqs("#work").innerHTML = "";




const htmlEmail = jsCreateElement('div', {
  attrs: {
    id: 'profileForm',
    style: 'margin-bottom: 100px;'
  },
  children: [
    jsCreateElement('div', {
      attrs: {
        class: 'headingH3 mb20'
      },
      children: [
        'Update Email'
      ]
    }),
    jsCreateElement('div', {
      attrs: {
        class: 'itemBlock mb20'
      },
      children: [
        jsCreateElement('label', {
          attrs: {
            class: 'forinput'
          },
          children: ['New Email']
        }),
        jsCreateElement('input', {
          attrs: {
            type: 'email',
            id: 'newEmail',
            value: profile.email
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
            id: 'saveEmail'
          },
          children: ['Save new email']
        })
      ]
    })
  ]
});

const htmlPassword = jsCreateElement('div', {
  attrs: {
    id: 'profileForm',
    style: 'margin-bottom: 100px;'
  },
  children: [
    jsCreateElement('div', {
      attrs: {
        class: 'headingH3 mb20'
      },
      children: [
        'Update Password'
      ]
    }),
    jsCreateElement('div', {
      attrs: {
        class: 'itemBlock mb20'
      },
      children: [
        jsCreateElement('label', {
          attrs: {
            class: 'forinput'
          },
          children: ['New Password']
        }),
        jsCreateElement('input', {
          attrs: {
            type: 'password',
            id: 'newPassword'
          }
        })
      ]
    }),
    jsCreateElement('div', {
      attrs: {
        class: 'itemBlock mb20'
      },
      children: [
        jsCreateElement('label', {
          attrs: {
            class: 'forinput'
          },
          children: ['Confirm New Password']
        }),
        jsCreateElement('input', {
          attrs: {
            type: 'password',
            id: 'confirmNewPassword'
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
            id: 'savePassword'
          },
          children: ['Save new password']
        })
      ]
    })
  ]
});

const htmlYubikey = jsCreateElement('div', {
  attrs: {
    id: 'profileForm',
  },
  children: [
    jsCreateElement('div', {
      attrs: {
        class: 'headingH3 mb20'
      },
      children: [
        'Add new Yubikey OTP'
      ]
    }),
    jsCreateElement('div', {
      attrs: {
        class: 'itemBlock mb20'
      },
      children: [
        jsCreateElement('label', {
          attrs: {
            class: 'forinput'
          },
          children: ['Yubikey name']
        }),
        jsCreateElement('input', {
          attrs: {
            type: 'text',
            id: 'yubikeyName'
          }
        })
      ]
    }),
    jsCreateElement('div', {
      attrs: {
        class: 'itemBlock mb20'
      },
      children: [
        jsCreateElement('label', {
          attrs: {
            class: 'forinput'
          },
          children: ['Yubikey ClientID']
        }),
        jsCreateElement('input', {
          attrs: {
            type: 'text',
            id: 'yubikeyClientID',
            value: '106891'
          }
        }),
        jsCreateElement('div', {
          attrs: {
            style: 'font-size: 12px;',
            class: 'center'
          },
          children: [
            'ClientID: https://upgrade.yubico.com/getapikey/'
          ]
        }),
      ]
    }),
    jsCreateElement('div', {
      attrs: {
        class: 'itemBlock mb20'
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
            type: 'submit',
            class: 'buttonIcon',
            id: 'yubikeySave'
          },
          children: ['Save OTP']
        })
      ]
    })
  ]
});

const html = jsCreateElement('div', {
  attrs: {
    id: 'profileForm',
    style: 'width: 350px; margin-top: 40px;'
  },
  children: [
    htmlEmail,
    htmlPassword,
    htmlYubikey
  ]
});

dqs("#work").appendChild(jsRender(html));
labelFloater();



jsOnSpecific("#saveEmail", "click", () => {
  emailSave();
});

async function emailSave() {
  const resp = await authService.saveEmail(dqs("#newEmail").value);
  if (!resp.success) {
    alert(resp.message);
    return;
  }
  dqs("#newEmail").value = "";
}



jsOnSpecific("#yubikeySave", "click", () => {
  const
    otp = dqs("#yubikeyOTP").value,
    name = dqs("#yubikeyName").value,
    clientID = dqs("#yubikeyClientID").value;
  yubikeySave(otp, name, clientID);
});

async function yubikeySave(otp, name, clientID) {
  if (!isValidYubikeyOTP(otp) || name.length === 0 || clientID.length === 0) {
    alert("Invalid Yubikey OTP");
    yubikeyClearCodeInput();
    return;
  }

  const resp = await authService.saveYubikeyCode(otp, name, clientID);

  if (!resp.success) {
    alert(resp.message);
    return;
  }
  yubikeyClearCodeInput();
}

function yubikeyClearCodeInput() {
  dqs("#yubikeyOTP").value = "";
}

function isValidYubikeyOTP(otp) {
  return otp.length === 44;
}


jsOnSpecific("#savePassword", "click", () => {
  passwordSave();
});

function passwordCompare() {
  const password = dqs("#newPassword").value;
  const confirmPassword = dqs("#confirmNewPassword").value;

  return password === confirmPassword;
}

async function passwordSave() {
  if (!passwordCompare()) {
    alert("Passwords do not match");
    return;
  }
  const resp = await authService.savePassword(dqs("#newPassword").value);

  if (!resp.success) {
    alert(resp.message);
    return;
  }
  dqs("#newPassword").value = "";
  dqs("#confirmNewPassword").value = "";
}