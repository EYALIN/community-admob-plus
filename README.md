# AdMob Plus

> ## ⚠️ IMPORTANT: This Plugin Has Reached End of Life

---

## 🚀 We've Moved to Something Better!

**This plugin is no longer maintained.** But don't worry — we've built something even better!

We've created **two new, dedicated, and actively maintained plugins** that offer:

- ✅ **Better performance** and smaller footprint
- ✅ **Faster updates** with the latest AdMob SDK
- ✅ **Dedicated consent management** (GDPR/ATT compliant)
- ✅ **Active maintenance** and quick bug fixes
- ✅ **Improved documentation** and support
- ✅ **Cleaner, more modular codebase**

---

## 🎯 Migrate to the New Plugins

### 📢 For Ads (Banner, Interstitial, Rewarded, etc.)

[![NPM version](https://img.shields.io/npm/v/community-cordova-plugin-admob)](https://www.npmjs.com/package/community-cordova-plugin-admob)
[![Downloads](https://img.shields.io/npm/dm/community-cordova-plugin-admob)](https://www.npmjs.com/package/community-cordova-plugin-admob)

```bash
cordova plugin add community-cordova-plugin-admob --variable APP_ID_ANDROID=ca-app-pub-xxx~yyy --variable APP_ID_IOS=ca-app-pub-xxx~yyy
```

👉 **[View community-cordova-plugin-admob on GitHub](https://github.com/niceonedaviddevs/community-cordova-plugin-admob)**

---

### 🔐 For User Consent (GDPR, ATT, UMP)

[![NPM version](https://img.shields.io/npm/v/community-cordova-plugin-consent)](https://www.npmjs.com/package/community-cordova-plugin-consent)
[![Downloads](https://img.shields.io/npm/dm/community-cordova-plugin-consent)](https://www.npmjs.com/package/community-cordova-plugin-consent)

```bash
cordova plugin add community-cordova-plugin-consent
```

👉 **[View community-cordova-plugin-consent on GitHub](https://github.com/niceonedaviddevs/community-cordova-plugin-consent)**

---

## 🔄 Migration Guide

Migrating is straightforward! Here's a quick overview:

### 1. Remove the old plugin

```bash
cordova plugin remove community-admob-plus
```

### 2. Install the new plugins

```bash
cordova plugin add community-cordova-plugin-admob --variable APP_ID_ANDROID=ca-app-pub-xxx~yyy --variable APP_ID_IOS=ca-app-pub-xxx~yyy
cordova plugin add community-cordova-plugin-consent
```

### 3. Update your code

The API is similar but improved. Check the documentation in each new plugin for detailed usage examples.

---

## ❓ Why the Split?

Separating ads and consent into dedicated plugins provides:

| Benefit | Description |
|---------|-------------|
| **Modularity** | Use only what you need — ads, consent, or both |
| **Compliance** | Dedicated consent plugin ensures proper GDPR/ATT handling |
| **Maintenance** | Smaller, focused codebases are easier to maintain and update |
| **Flexibility** | Mix and match with other ad or consent solutions |

---

## 💖 Support the New Plugins

I dedicate a considerable amount of my free time to developing and maintaining these plugins for the community.

If these plugins help you build successful apps, please consider supporting the development:

[![Sponsor Me](https://img.shields.io/static/v1?label=Sponsor%20Me&style=for-the-badge&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/eyalin)

---

## 📜 Credits

This plugin was originally created by [Ratson](https://github.com/niceonedaviddevs). Thank you for laying the foundation that helped the Cordova community monetize their apps.

---

## 📄 License

This project is [MIT licensed](./LICENSE).

---

<p align="center">
  <b>🌟 Star the new repos to stay updated! 🌟</b>
</p>
