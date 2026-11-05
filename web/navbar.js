/**
 * SegurCel Web - Shared Navbar & Dynamic Localizations Module
 * Gestiona encabezado, selector desplegable con banderas HD, botones de descarga (Web, Android, iOS TestFlight) y pie de página profesional multicolumna en 14 idiomas.
 */

const FLAGS_MAP = {
  es: "https://flagcdn.com/20x15/es.png",
  en: "https://flagcdn.com/20x15/us.png",
  pt: "https://flagcdn.com/20x15/br.png",
  zh: "https://flagcdn.com/20x15/cn.png",
  zh_HK: "https://flagcdn.com/20x15/hk.png",
  fr: "https://flagcdn.com/20x15/fr.png",
  hi: "https://flagcdn.com/20x15/in.png",
  de: "https://flagcdn.com/20x15/de.png",
  ja: "https://flagcdn.com/20x15/jp.png",
  ko: "https://flagcdn.com/20x15/kr.png",
  ru: "https://flagcdn.com/20x15/ru.png",
  it: "https://flagcdn.com/20x15/it.png",
  ar: "https://flagcdn.com/20x15/sa.png",
  id: "https://flagcdn.com/20x15/id.png"
};

const NAMES_MAP = {
  es: "Español", en: "English", pt: "Português", zh: "中文 (简体)", zh_HK: "繁體中文", fr: "Français",
  hi: "हिन्दी", de: "Deutsch", ja: "日本語", ko: "한국어", ru: "Русский", it: "Italiano", ar: "العربية", id: "Bahasa Indonesia"
};

const NAV_DICT = {
  es: { btnBack: "← Volver al Sitio Oficial", headerVault: "Acceder a la Bóveda", headerGuide: "📘 Guía de Uso" },
  en: { btnBack: "← Back to Official Site", headerVault: "Access Vault", headerGuide: "📘 User Guide" },
  pt: { btnBack: "← Voltar ao Site Oficial", headerVault: "Acessar Cofre", headerGuide: "📘 Guia do Usuário" },
  zh: { btnBack: "← 返回官方网站", headerVault: "进入保险库", headerGuide: "📘 使用指南" },
  zh_HK: { btnBack: "← 返回官方網站", headerVault: "進入保險庫", headerGuide: "📘 使用指南" },
  fr: { btnBack: "← Retour au Site Officiel", headerVault: "Accéder au Coffre", headerGuide: "📘 Guide Utilisateur" },
  hi: { btnBack: "← आधिकारिक साइट पर वापस जाएं", headerVault: "वॉल्ट एक्सेस करें", headerGuide: "📘 उपयोग निर्देशिका" },
  de: { btnBack: "← Zurück zur offiziellen Website", headerVault: "Tresor öffnen", headerGuide: "📘 Benutzerhandbuch" },
  ja: { btnBack: "← 公式サイトに戻る", headerVault: "保管庫に入る", headerGuide: "📘 ユーザーガイド" },
  ko: { btnBack: "← 공식 사이트로 돌아가기", headerVault: "보관함 접속", headerGuide: "📘 사용자 설명서" },
  ru: { btnBack: "← Вернуться на официальный сайт", headerVault: "Войти в хранилище", headerGuide: "📘 Руководство" },
  it: { btnBack: "← Torna al Sito Ufficiale", headerVault: "Accedi alla Bóveda", headerGuide: "📘 Guida Utente" },
  ar: { btnBack: "← العودة إلى الموقع الرسمي", headerVault: "الوصول إلى الخزنة", headerGuide: "📘 دليل الاستخدام" },
  id: { btnBack: "← Kembali ke Situs Resmi", headerVault: "Akses Brankas", headerGuide: "📘 Panduan Pengguna" }
};

const FOOTER_DICT = {
  es: {
    desc: "Bóveda de contraseñas y autenticador 2FA con cifrado local Zero-Knowledge AES-256-GCM.",
    colEco: "Plataformas & Descargas", colDoc: "Documentación & Legal", colSup: "Soporte & Código",
    vault: "🌐 Acceder a Bóveda Web", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 Extensión PC/Mac (.zip)",
    guide: "📘 Guía Rápida de Uso", privacy: "🔒 Política de Privacidad", github: "⭐ GitHub (Código Auditable)", support: "✉️ soporte@segurcel.app",
    copyright: "© 2026 SegurCel. Todos los derechos reservados.", dev: "Desarrollado por Alejandro Martínez Briao"
  },
  en: {
    desc: "Password vault and 2FA authenticator with local Zero-Knowledge AES-256-GCM encryption.",
    colEco: "Platforms & Downloads", colDoc: "Documentation & Legal", colSup: "Support & Source Code",
    vault: "🌐 Access Web Vault", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 PC/Mac Extension (.zip)",
    guide: "📘 Quick User Guide", privacy: "🔒 Privacy Policy", github: "⭐ GitHub (Auditable Code)", support: "✉️ soporte@segurcel.app",
    copyright: "© 2026 SegurCel. All rights reserved.", dev: "Developed by Alejandro Martínez Briao"
  },
  pt: {
    desc: "Cofre de senhas e autenticador 2FA com criptografia local Zero-Knowledge AES-256-GCM.",
    colEco: "Plataformas e Downloads", colDoc: "Documentação e Legal", colSup: "Suporte e Código",
    vault: "🌐 Acessar Cofre Web", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 Extensão PC/Mac (.zip)",
    guide: "📘 Guia Rápido do Usuário", privacy: "🔒 Política de Privacidade", github: "⭐ GitHub (Código Auditável)", support: "✉️ soporte@segurcel.app",
    copyright: "© 2026 SegurCel. Todos os direitos reservados.", dev: "Desenvolvido por Alejandro Martínez Briao"
  },
  zh: {
    desc: "密码保险库和 2FA 身份验证器，采用本地零知识 AES-256-GCM 加密。",
    colEco: "平台与下载", colDoc: "文档与法律", colSup: "支持与源码",
    vault: "🌐 进入 Web 保险库", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 PC/Mac 浏览器扩展 (.zip)",
    guide: "📘 快速使用指南", privacy: "🔒 隐私政策", github: "⭐ GitHub (可审计源码)", support: "✉️ 官方支持邮箱",
    copyright: "© 2026 SegurCel。保留所有权利。", dev: "由 Alejandro Martínez Briao 开发"
  },
  zh_HK: {
    desc: "密碼保險庫及 2FA 身份驗證器，採用本地零知識 AES-256-GCM 加密。",
    colEco: "平台與下載", colDoc: "文檔與法律", colSup: "支援與源碼",
    vault: "🌐 進入 Web 保險庫", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 PC/Mac 瀏覽器擴充功能 (.zip)",
    guide: "📘 快速使用指南", privacy: "🔒 私隱政策", github: "⭐ GitHub (可審計源碼)", support: "✉️ 官方支援電郵",
    copyright: "© 2026 SegurCel。保留所有權利。", dev: "由 Alejandro Martínez Briao 開發"
  },
  fr: {
    desc: "Coffre-fort de mots de passe et authentificateur 2FA avec chiffrement local Zero-Knowledge AES-256-GCM.",
    colEco: "Plateformes & Téléchargements", colDoc: "Documentation & Légal", colSup: "Support & Code Source",
    vault: "🌐 Accéder au Coffre Web", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 Extension PC/Mac (.zip)",
    guide: "📘 Guide Rapide d'Utilisation", privacy: "🔒 Politique de Confidentialité", github: "⭐ GitHub (Code Auditable)", support: "✉️ Support Officiel",
    copyright: "© 2026 SegurCel. Tous droits réservés.", dev: "Développé par Alejandro Martínez Briao"
  },
  hi: {
    desc: "स्थानीय Zero-Knowledge AES-256-GCM एन्क्रिप्शन के साथ पासवर्ड वॉल्ट और 2FA ऑथेंटिकेटर।",
    colEco: "प्लेटफ़ॉर्म और डाउनलोड", colDoc: "दस्तावेज़ीकरण और कानूनी", colSup: "सहायता और कोड",
    vault: "🌐 वेब वॉल्ट एक्सेस करें", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 PC/Mac एक्सटेंशन (.zip)",
    guide: "📘 त्वरित उपयोग निर्देशिका", privacy: "🔒 गोपनीयता नीति", github: "⭐ GitHub (ऑडिट योग्य कोड)", support: "✉️ आधिकारिक सहायता",
    copyright: "© 2026 SegurCel. सर्वाधिकार सुरक्षित।", dev: "Alejandro Martínez Briao द्वारा विकसित"
  },
  de: {
    desc: "Passwort-Tresor und 2FA-Authentifikator mit lokaler Zero-Knowledge AES-256-GCM-Verschlüsselung.",
    colEco: "Plattformen & Downloads", colDoc: "Dokumentation & Rechtliches", colSup: "Support & Quellcode",
    vault: "🌐 Web-Tresor öffnen", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 PC/Mac Erweiterung (.zip)",
    guide: "📘 Schnellstartanleitung", privacy: "🔒 Datenschutzerklärung", github: "⭐ GitHub (Prüfbarer Code)", support: "✉️ Offizieller Support",
    copyright: "© 2026 SegurCel. Alle Rechte vorbehalten.", dev: "Entwickelt von Alejandro Martínez Briao"
  },
  ja: {
    desc: "ローカル Zero-Knowledge AES-256-GCM 暗号化を備えたパスワード保管庫および 2FA 認証アプリ。",
    colEco: "プラットフォーム＆ダウンロード", colDoc: "ドキュメント＆法的情報", colSup: "サポート＆ソースコード",
    vault: "🌐 Web 保管庫に入る", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 PC/Mac 拡張機能 (.zip)",
    guide: "📘 クイックユーザーガイド", privacy: "🔒 プライバシーポリシー", github: "⭐ GitHub (監査可能コード)", support: "✉️ 公式サポート",
    copyright: "© 2026 SegurCel. All rights reserved.", dev: "Alejandro Martínez Briao によって開発"
  },
  ko: {
    desc: "로컬 영지식 AES-256-GCM 암호화를 적용한 비밀번호 보관함 및 2FA 인증기.",
    colEco: "플랫폼 및 다운로드", colDoc: "문서 및 법적 공지", colSup: "지원 및 소스 코드",
    vault: "🌐 웹 보관함 접속", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 PC/Mac 확장 프로그램 (.zip)",
    guide: "📘 빠른 사용자 설명서", privacy: "🔒 개인정보 처리방침", github: "⭐ GitHub (감사 가능 코드)", support: "✉️ 공식 지원",
    copyright: "© 2026 SegurCel. All rights reserved.", dev: "Alejandro Martínez Briao 개발"
  },
  ru: {
    desc: "Хранилище паролей и 2FA-аутентификатор с локальным шифрованием Zero-Knowledge AES-256-GCM.",
    colEco: "Платформы и загрузки", colDoc: "Документация и правовая информация", colSup: "Поддержка и исходный код",
    vault: "🌐 Войти в веб-хранилище", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 Расширение ПК/Mac (.zip)",
    guide: "📘 Краткое руководство", privacy: "🔒 Политика конфиденциальности", github: "⭐ GitHub (Проверяемый код)", support: "✉️ Официальная поддержка",
    copyright: "© 2026 SegurCel. Все права защищены.", dev: "Разработано Алехандро Мартинес Бриао"
  },
  it: {
    desc: "Cassaforte di password e autenticatore 2FA con crittografia locale Zero-Knowledge AES-256-GCM.",
    colEco: "Piattaforme & Download", colDoc: "Documentazione & Legale", colSup: "Supporto & Codice",
    vault: "🌐 Accedi alla Bóveda Web", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 Estensione PC/Mac (.zip)",
    guide: "📘 Guida Rapida Utente", privacy: "🔒 Informativa sulla Privacy", github: "⭐ GitHub (Codice Ispezionabile)", support: "✉️ Supporto Ufficiale",
    copyright: "© 2026 SegurCel. Tutti i diritti riservati.", dev: "Sviluppato da Alejandro Martínez Briao"
  },
  ar: {
    desc: "خزنة كلمات المرور ومصرّح 2FA بتشفير محلي Zero-Knowledge AES-256-GCM.",
    colEco: "المنصات والتنزيلات", colDoc: "الوثائق والشروط القانونية", colSup: "الدعم والكود المصدري",
    vault: "🌐 الوصول إلى الخزنة السحابية", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 إضافة الكمبيوتر (.zip)",
    guide: "📘 دليل الاستخدام السريع", privacy: "🔒 سياسة الخصوصية", github: "⭐ GitHub (كود قابل للتدقيق)", support: "✉️ الدعم الرسمي",
    copyright: "© 2026 SegurCel. جميع الحقوق محفوظة.", dev: "تطوير أليخاندرو مارتينيز برياو"
  },
  id: {
    desc: "Brankas kata sandi dan otentikator 2FA dengan enkripsi lokal Zero-Knowledge AES-256-GCM.",
    colEco: "Platform & Unduhan", colDoc: "Dokumentasi & Legal", colSup: "Dukungan & Kode Sumber",
    vault: "🌐 Akses Brankas Web", android: "🤖 Google Play (Android)", ios: "🍏 Apple TestFlight (iOS)", ext: "💻 Ekstensi PC/Mac (.zip)",
    guide: "📘 Panduan Pengguna Cepat", privacy: "🔒 Kebijakan Privasi", github: "⭐ GitHub (Kode Dapat Diaudit)", support: "✉️ Dukungan Resmi",
    copyright: "© 2026 SegurCel. Hak cipta dilindungi undang-undang.", dev: "Dikembangkan oleh Alejandro Martínez Briao"
  }
};

window.SegurCelNav = {
  activeLang: 'es',

  injectFooterStyles() {
    if (document.getElementById('segurcel-footer-styles')) return;
    const style = document.createElement('style');
    style.id = 'segurcel-footer-styles';
    style.textContent = `
      footer {
        background-color: #0b0f19;
        border-top: 1px solid rgba(108, 99, 255, 0.2);
        color: #e2e8f0;
      }
      .footer-container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 48px 24px 24px 24px;
      }
      .footer-grid {
        display: grid;
        grid-template-columns: 1.5fr 1fr 1fr 1fr;
        gap: 36px;
        margin-bottom: 36px;
        text-align: left;
      }
      [dir="rtl"] .footer-grid {
        text-align: right;
      }
      @media (max-width: 850px) {
        .footer-grid {
          grid-template-columns: 1fr 1fr;
          gap: 28px;
        }
      }
      @media (max-width: 520px) {
        .footer-grid {
          grid-template-columns: 1fr;
          gap: 24px;
        }
      }
      .footer-brand .brand-row {
        display: flex;
        align-items: center;
        gap: 10px;
        margin-bottom: 14px;
      }
      .footer-logo {
        width: 36px;
        height: 36px;
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(108, 99, 255, 0.4);
      }
      .footer-title {
        font-size: 22px;
        font-weight: 800;
        color: #ffffff;
        letter-spacing: -0.5px;
      }
      .footer-desc {
        font-size: 13px;
        color: #94a3b8;
        line-height: 1.6;
        margin: 0;
      }
      .footer-col h4 {
        font-size: 13px;
        font-weight: 800;
        color: #818cf8;
        margin: 0 0 14px 0;
        text-transform: uppercase;
        letter-spacing: 0.8px;
      }
      .footer-col ul {
        list-style: none;
        padding: 0;
        margin: 0;
      }
      .footer-col li {
        margin-bottom: 10px;
      }
      .footer-col a {
        color: #cbd5e1;
        text-decoration: none;
        font-size: 13px;
        font-weight: 500;
        transition: color 0.2s ease, transform 0.2s ease;
        display: inline-block;
      }
      .footer-col a:hover {
        color: #6C63FF;
        transform: translateX(3px);
      }
      [dir="rtl"] .footer-col a:hover {
        transform: translateX(-3px);
      }
      .footer-bottom {
        border-top: 1px solid rgba(255, 255, 255, 0.08);
        padding-top: 24px;
        text-align: center;
        font-size: 13px;
        color: #64748b;
      }
      .dev-credit {
        display: inline-block;
        margin-left: 8px;
        color: #fbbf24;
        font-weight: 600;
      }
      [dir="rtl"] .dev-credit {
        margin-left: 0;
        margin-right: 8px;
      }
    `;
    document.head.appendChild(style);
  },

  getNavData(lang) {
    return NAV_DICT[lang] || NAV_DICT.es;
  },

  updateNav(lang) {
    this.activeLang = lang;
    const navData = NAV_DICT[lang] || NAV_DICT.es;

    // Actualizar dirección del documento para soporte RTL (Árabe)
    document.documentElement.dir = (lang === 'ar') ? 'rtl' : 'ltr';

    // Actualizar botón 'Volver al Sitio Oficial'
    const btnBack = document.getElementById('btnBack');
    if (btnBack) {
      btnBack.innerText = navData.btnBack;
      btnBack.href = `/?lang=${lang}`;
    }

    // Actualizar botón 'Acceder a la Bóveda' en el header
    const btnHeaderVault = document.getElementById('btnHeaderVault');
    if (btnHeaderVault) {
      btnHeaderVault.innerText = navData.headerVault;
      btnHeaderVault.href = `/vault?lang=${lang}`;
    }

    // Actualizar enlace a la Guía en el header
    const linkHeaderGuide = document.getElementById('linkHeaderGuide');
    if (linkHeaderGuide) {
      linkHeaderGuide.innerText = navData.headerGuide;
      linkHeaderGuide.href = `/guide?lang=${lang}`;
    }

    // Actualizar Pie de Página (Footer)
    this.updateFooter(lang);
  },

  updateFooter(lang) {
    this.injectFooterStyles();
    const data = FOOTER_DICT[lang] || FOOTER_DICT.es;

    const copyEl = document.getElementById('footerCopyright');
    if (copyEl) copyEl.innerText = data.copyright;

    const footerEl = document.querySelector('footer');
    if (footerEl) {
      footerEl.innerHTML = `
        <div class="footer-container">
          <div class="footer-grid">
            <div class="footer-col footer-brand">
              <div class="brand-row">
                <img src="/assets/assets/html/logo_solo.jpeg" alt="SegurCel Logo" class="footer-logo">
                <span class="footer-title">SegurCel</span>
              </div>
              <p class="footer-desc">${data.desc}</p>
            </div>
            <div class="footer-col">
              <h4>${data.colEco}</h4>
              <ul>
                <li><a href="/vault?lang=${lang}">${data.vault}</a></li>
                <li><a href="https://play.google.com/store/apps/details?id=com.segurcel.segurcel" target="_blank">${data.android}</a></li>
                <li><a href="https://testflight.apple.com/join/3Dvcxj1E" target="_blank">${data.ios}</a></li>
                <li><a href="/segurcel-extension.zip" target="_blank">${data.ext}</a></li>
              </ul>
            </div>
            <div class="footer-col">
              <h4>${data.colDoc}</h4>
              <ul>
                <li><a href="/guide?lang=${lang}">${data.guide}</a></li>
                <li><a href="/privacy?lang=${lang}">${data.privacy}</a></li>
              </ul>
            </div>
            <div class="footer-col">
              <h4>${data.colSup}</h4>
              <ul>
                <li><a href="https://github.com/ambuydev/SegurCel" target="_blank">${data.github}</a></li>
                <li><a href="mailto:soporte@segurcel.app">${data.support}</a></li>
              </ul>
            </div>
          </div>
          <div class="footer-bottom">
            <p>${data.copyright} <span class="dev-credit">${data.dev}</span></p>
          </div>
        </div>
      `;
    }
  },

  renderLangMenu() {
    const menu = document.getElementById("langMenu");
    if (!menu) return;
    let html = "";
    for (const code of Object.keys(FLAGS_MAP)) {
      const flag = FLAGS_MAP[code];
      const name = NAMES_MAP[code];
      html += `<div onclick="selectLanguage('${code}')"><img src="${flag}" alt="${code}"> ${name}</div>`;
    }
    menu.innerHTML = html;
  },

  selectLanguage(lang, callback) {
    const flagEl = document.getElementById("selectedFlag");
    const nameEl = document.getElementById("selectedLangName");
    if (flagEl && FLAGS_MAP[lang]) flagEl.src = FLAGS_MAP[lang];
    if (nameEl && NAMES_MAP[lang]) nameEl.innerText = NAMES_MAP[lang];

    const menu = document.getElementById("langMenu");
    if (menu) menu.classList.remove("show");

    try {
      const newUrl = window.location.pathname + '?lang=' + lang;
      window.history.replaceState(null, '', newUrl);
    } catch (_) {}

    this.updateNav(lang);

    if (typeof callback === 'function') {
      callback(lang);
    }
  },

  toggleLangMenu(event) {
    if (event) event.stopPropagation();
    const menu = document.getElementById("langMenu");
    if (menu) menu.classList.toggle("show");
  },

  init(callback) {
    this.renderLangMenu();
    const urlParams = new URLSearchParams(window.location.search);
    const langParam = urlParams.get('lang');
    const initialLang = (langParam && FLAGS_MAP[langParam]) ? langParam : 'es';

    this.selectLanguage(initialLang, callback);

    window.onclick = (event) => {
      const menu = document.getElementById("langMenu");
      if (menu && menu.classList.contains('show')) {
        menu.classList.remove('show');
      }
    };
  }
};
