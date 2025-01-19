
export default class AuthServiceExternal {

  constructor() {
    if (AuthServiceExternal.instance) {
      return AuthServiceExternal.instance;
    }
    AuthServiceExternal.instance = this;

    this.resource = "/api/auth";
  }

  async login(email = "", password = "", otp = "", hp = "") {
    return await fetch(`${this.resource}/login`, {
      method: "POST",
      body: new URLSearchParams({
        email,
        password,
        otp,
        hp
      }),
    })
    .then((res) => res.json())
    .then((res) => {
      return res;
    })
    .catch(() => {
      return { success: false }
    });
  }

}
