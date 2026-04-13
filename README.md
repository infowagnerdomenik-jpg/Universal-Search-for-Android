<div align="center">
  <img src="https://raw.githubusercontent.com/infowagnerdomenik-jpg/Universal-Search-for-Android/main/assets/icons/original/Search_App_Icon.svg" width="120" alt="Universal Search Icon">
  
  <h1>Universal Search</h1>
  <p><b>A privacy-first, modular universal search engine for Android.</b></p>
  
  [![Android Support](https://img.shields.io/badge/Android-14_to_16_QPR2_(API_34--36.1)-3DDC84?style=for-the-badge&logo=android)](https://www.android.com/)
  [![Flutter](https://img.shields.io/badge/Flutter-Native_UI-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev/)
  [![Kotlin](https://img.shields.io/badge/Kotlin-Widget_Core-7F52FF?style=for-the-badge&logo=kotlin)](https://kotlinlang.org/)
  <br><br>
</div>

---

## 🛡️ Architecture & Philosophy (Zero-Trust)

This project is built on the principle of maximum data isolation. The main search app acts as an orchestrator and display engine, but it **does not** inherently possess the permissions to read your files or browse the web.

Instead, the ecosystem relies on completely isolated **Companion Apps**:

> 📂 **[File Companion](https://github.com/infowagnerdomenik-jpg/Search-Files-Companion)** <br>
> Completely air-gapped. It has no internet permission. It only reads local files and passes non-sensitive metadata (file names and thumbnails) back to the main app.

> 🌐 **[Internet Companion](https://github.com/infowagnerdomenik-jpg/Search-Internet-Companion)** <br>
> Handles web queries and suggestions. 

*Don't trust the internet companion? Simply don't install it. The main app and local search will continue to work flawlessly.*

---

## 📦 Downloads & Ecosystem

This project is split into multiple repositories to maintain strict separation of concerns. For the best experience, download the Main App and any Companions you wish to use.

| Component | Source Code | Direct Download |
| :--- | :--- | :--- |
| **Main Search App** | [Current Repository](#) | [![Download Main App](https://img.shields.io/badge/Download-Coming_Soon-lightgrey?style=for-the-badge)](#) |
| **File Companion** | [View Repository](https://github.com/infowagnerdomenik-jpg/Search-Files-Companion) | [![Download File Companion](https://img.shields.io/badge/Download-First_Release-02569B?style=for-the-badge&logo=github)](https://github.com/infowagnerdomenik-jpg/Search-Files-Companion/releases/tag/First_Release) |
| **Internet Companion** | [View Repository](https://github.com/infowagnerdomenik-jpg/Search-Internet-Companion) | [![Download Internet Companion](https://img.shields.io/badge/Download-First_Release-02569B?style=for-the-badge&logo=github)](https://github.com/infowagnerdomenik-jpg/Search-Internet-Companion/releases/tag/First_Release) |

---

## 🔐 Security & Build Instructions

This app utilizes custom intents and **Signature Level Protection** for all communication between the main app and its companions. Furthermore, signature hashes are verified dynamically at the kernel level to prevent spoofing or tampering.

> [!IMPORTANT]
> **Building from source:**
> Because of this strict security model, the Main App and the Companion Apps can only communicate if they are signed with the **exact same keystore**. If you compile this project yourself, you must build and sign all required companion apps with your own key. Modifying or injecting third-party code into the communication bridge will result in a connection block.

For most users, it is highly recommended to use the pre-compiled, officially signed APKs from the table above.

---

## ✨ Core Features

<table>
  <tr>
    <td width="50%">
      <b>⚡ Native Speed</b><br>
      The homescreen widget is built entirely with native Android Kotlin and XML layouts to guarantee instant response times and zero rendering overhead.
    </td>
    <td width="50%">
      <b>🧠 Smart Time-Parsing</b><br>
      Search for "Monday" or "Tomorrow" to instantly pull up relevant calendar events in that specific timeframe, bypassing the need to remember exact event titles.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <b>🎨 Custom Design Engine</b><br>
      A massive custom UI engine allows for granular control over widget transparency, corner radius, and layout order. Powered by our open-source <b><a href="https://github.com/infowagnerdomenik-jpg/Design-Engine-Plug-In-for-the-search-app">Flutter Design Engine Plug-In</a></b> (Code-only plugin for developers). Includes a true AMOLED dark mode.
    </td>
    <td width="50%">
      <b>🌊 Modern Navigation</b><br>
      Fully supports Android's modern predictive back navigation for seamless, native-feeling screen transitions.
    </td>
  </tr>
</table>

---

## 💡 Design Philosophy

> [!NOTE]
> **Privacy over Aesthetics (The Screen Transition Flicker)**
> When transitioning between certain native and Flutter screens, you might notice a very brief flicker before the system wallpaper is rendered. **This is not a bug**, but a conscious design choice. 
> 
> Eliminating this flicker would require requesting the `READ_EXTERNAL_STORAGE` permission just to cache your wallpaper. We refuse to ask for sensitive file permissions for a purely cosmetic effect. Zero-Trust means keeping permissions to an absolute minimum.

<br>

<div align="center">
  <p><i>Designed with ❤️ and a strict focus on privacy.</i></p>
</div>
