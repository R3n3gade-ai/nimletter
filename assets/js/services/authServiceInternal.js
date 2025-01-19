
export default class AuthService {

  constructor() {
    if (AuthService.instance) {
      return AuthService.instance;
    }
    AuthService.instance = this;

    this.resource = "/api/profile";
  }

  async getProfile() {
    return await fetch(`${this.resource}/get-profile`, {
      method: "GET"
    })
    .then((res) => res.json())
    .then((res) => {
      console.log(res);
      return res;
    })
    .catch(() => {
      return { success: false };
    });
  }

  async saveEmail(email) {
    return await fetch(`${this.resource}/save-email`, {
      method: "POST",
      body: new URLSearchParams({
        email,
        action: "save",
      }),
    })
    .then((res) => res.json())
    .then((res) => {
      return res;
    })
    .catch(() => {
      return { success: false };
    });
  }

  async saveYubikeyCode(otp, name, clientID) {
    return await fetch(`${this.resource}/save-yubikey`, {
      method: "POST",
      body: new URLSearchParams({
        otp,
        name,
        clientID,
        action: "save",
      }),
    })
    .then((res) => res.json())
    .then((res) => {
      return res;
    })
    .catch(() => {
      return { success: false };
    });
  }

  async savePassword(password) {
    return await fetch(`${this.resource}/save-password`, {
      method: "POST",
      body: new URLSearchParams({
        password,
        action: "save",
      }),
    })
    .then((res) => res.json())
    .then((res) => {
      return res;
    })
    .catch(() => {
      return { success: false };
    });
  }

  // async validate2FA(code) {
  //   return await fetch(`${this.resource}/validate-2fa`, {
  //     method: "POST",
  //     body: new URLSearchParams({
  //       code,
  //       action: "validate",
  //     }),
  //   })
  //   .then((res) => res.json())
  //   .then((res) => {
  //     return res;
  //   })
  //   .catch(() => {
  //     return { success: false };
  //   });
  // }

  // async save2FACode(code) {
  //   return await fetch(`${this.resource}/save-2fa`, {
  //     method: "POST",
  //     body: new URLSearchParams({
  //       code,
  //       action: "save",
  //     }),
  //   })
  //   .then((res) => res.json())
  //   .then((res) => {
  //     return res;
  //   })
  //   .catch(() => {
  //     return { success: false };
  //   });
  // }

}
