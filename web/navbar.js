/**
 * SegurCel Web - Shared Navbar & Dynamic Localizations Module
 * Gestiona encabezado, selector desplegable con banderas HD, botones de descarga (Android Test, iOS TestFlight, PC/Mac) y pie de página completo en 14 idiomas.
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
  es: { btnBack: "← Volver al Sitio Oficial", headerVault: "Acceder a la Bóveda", headerGuide: "Guía de Uso" },
  en: { btnBack: "← Back to Official Site", headerVault: "Access Vault", headerGuide: "User Guide" },
  pt: { btnBack: "← Voltar ao Site Oficial", headerVault: "Acessar Cofre", headerGuide: "Guia do Usuário" },
  zh: { btnBack: "← 返回官方网站", headerVault: "进入保险库", headerGuide: "使用指南" },
  zh_HK: { btnBack: "← 返回官方網站", headerVault: "進入保險庫", headerGuide: "使用指南" },
  fr: { btnBack: "← Retour au Site Officiel", headerVault: "Accéder au Coffre", headerGuide: "Guide Utilisateur" },
  hi: { btnBack: "← आधिकारिक साइट पर वापस जाएं", headerVault: "वॉल्ट एक्सेस करें", headerGuide: "उपयोग निर्देशिका" },
  de: { btnBack: "← Zurück zur offiziellen Website", headerVault: "Tresor öffnen", headerGuide: "Benutzerhandbuch" },
  ja: { btnBack: "← 公式サイトに戻る", headerVault: "保管庫に入る", headerGuide: "ユーザーガイド" },
  ko: { btnBack: "← 공식 사이트로 돌아가기", headerVault: "보관함 접속", headerGuide: "사용자 설명서" },
  ru: { btnBack: "← Вернуться на официальный сайт", headerVault: "Войти в хранилище", headerGuide: "Руководство" },
  it: { btnBack: "← Torna al Sito Ufficiale", headerVault: "Accedi alla Bóveda", headerGuide: "Guida Utente" },
  ar: { btnBack: "← العودة إلى الموقع الرسمي", headerVault: "الوصول إلى الخزنة", headerGuide: "دليل الاستخدام" },
  id: { btnBack: "← Kembali ke Situs Resmi", headerVault: "Akses Brankas", headerGuide: "Panduan Pengguna" }
};

const FOOTER_DICT = {
  es: {
    copyright: "© 2026 SegurCel. Todos los derechos reservados.",
    dev: "Desarrollado por A.M.B.",
    guide: "Guía Rápida de Uso",
    privacy: "Política de Privacidad",
    support: "Contacto: support.segurcel@gmail.com",
    github: "GitHub (Código Auditable)",
    android: "Unirse a la Prueba en Google Play",
    ios: "Probar Beta en TestFlight (iOS)",
    ext: "Extensión PC/Mac (.zip)"
  },
  en: {
    copyright: "© 2026 SegurCel. All rights reserved.",
    dev: "Developed by A.M.B.",
    guide: "Quick User Guide",
    privacy: "Privacy Policy",
    support: "Contact: support.segurcel@gmail.com",
    github: "GitHub (Auditable Code)",
    android: "Join Beta Test on Google Play",
    ios: "Test Beta on TestFlight (iOS)",
    ext: "PC/Mac Extension (.zip)"
  },
  pt: {
    copyright: "© 2026 SegurCel. Todos os direitos reservados.",
    dev: "Desenvolvido por A.M.B.",
    guide: "Guia Rápido do Usuário",
    privacy: "Política de Privacidade",
    support: "Contato: support.segurcel@gmail.com",
    github: "GitHub (Código Auditável)",
    android: "Participar do Teste no Google Play",
    ios: "Testar Beta no TestFlight (iOS)",
    ext: "Extensão PC/Mac (.zip)"
  },
  zh: {
    copyright: "© 2026 SegurCel。保留所有权利。",
    dev: "由 A.M.B. 开发",
    guide: "快速使用指南",
    privacy: "隐私政策",
    support: "联系支持: support.segurcel@gmail.com",
    github: "GitHub (可审计源码)",
    android: "加入 Google Play 测试",
    ios: "在 TestFlight 上测试 iOS Beta",
    ext: "PC/Mac 浏览器扩展 (.zip)"
  },
  zh_HK: {
    copyright: "© 2026 SegurCel。保留所有權利。",
    dev: "由 A.M.B. 開發",
    guide: "快速使用指南",
    privacy: "私隱政策",
    support: "聯絡支援: support.segurcel@gmail.com",
    github: "GitHub (可審計源碼)",
    android: "加入 Google Play 測試",
    ios: "在 TestFlight 上測試 iOS Beta",
    ext: "PC/Mac 瀏覽器擴充功能 (.zip)"
  },
  fr: {
    copyright: "© 2026 SegurCel. Tous droits réservés.",
    dev: "Développé par A.M.B.",
    guide: "Guide Rapide d'Utilisation",
    privacy: "Politique de Confidentialité",
    support: "Contact : support.segurcel@gmail.com",
    github: "GitHub (Code Auditable)",
    android: "Rejoindre le Test sur Google Play",
    ios: "Tester la Bêta sur TestFlight (iOS)",
    ext: "Extension PC/Mac (.zip)"
  },
  hi: {
    copyright: "© 2026 SegurCel. सर्वाधिकार सुरक्षित।",
    dev: "A.M.B. द्वारा विकसित",
    guide: "त्वरित उपयोग निर्देशिका",
    privacy: "गोपनीयता नीति",
    support: "संपर्क: support.segurcel@gmail.com",
    github: "GitHub (ऑडिट योग्य कोड)",
    android: "Google Play पर बीटा टेस्ट में शामिल हों",
    ios: "TestFlight पर iOS बीटा टेस्ट करें",
    ext: "PC/Mac एक्सटेंशन (.zip)"
  },
  de: {
    copyright: "© 2026 SegurCel. Alle Rechte vorbehalten.",
    dev: "Entwickelt von A.M.B.",
    guide: "Schnellstartanleitung",
    privacy: "Datenschutzerklärung",
    support: "Kontakt: support.segurcel@gmail.com",
    github: "GitHub (Prüfbarer Code)",
    android: "Beta-Test auf Google Play beitreten",
    ios: "Beta auf TestFlight testen (iOS)",
    ext: "PC/Mac-Erweiterung herunterladen (.zip)"
  },
  ja: {
    copyright: "© 2026 SegurCel. All rights reserved.",
    dev: "A.M.B. によって開発",
    guide: "クイックユーザーガイド",
    privacy: "プライバシーポリシー",
    support: "お問い合わせ: support.segurcel@gmail.com",
    github: "GitHub (監査可能コード)",
    android: "Google Play ベータテストに参加",
    ios: "TestFlight で iOS ベータをテスト",
    ext: "PC/Mac 拡張機能をダウンロード (.zip)"
  },
  ko: {
    copyright: "© 2026 SegurCel. All rights reserved.",
    dev: "A.M.B. 개발",
    guide: "빠른 사용자 설명서",
    privacy: "개인정보 처리방침",
    support: "문의: support.segurcel@gmail.com",
    github: "GitHub (감사 가능 코드)",
    android: "Google Play 베타 테스트 참여",
    ios: "TestFlight에서 iOS 베타 테스트",
    ext: "PC/Mac 확장 프로그램 (.zip)"
  },
  ru: {
    copyright: "© 2026 SegurCel. Все права защищены.",
    dev: "Разработано A.M.B.",
    guide: "Краткое руководство",
    privacy: "Политика конфиденциальности",
    support: "Контакты: support.segurcel@gmail.com",
    github: "GitHub (Проверяемый код)",
    android: "Присоединиться к тесту в Google Play",
    ios: "Бета-тест в TestFlight (iOS)",
    ext: "Расширение ПК/Mac (.zip)"
  },
  it: {
    copyright: "© 2026 SegurCel. Tutti i diritti riservati.",
    dev: "Sviluppato da A.M.B.",
    guide: "Guida Rapida Utente",
    privacy: "Informativa sulla Privacy",
    support: "Contatto: support.segurcel@gmail.com",
    github: "GitHub (Codice Ispezionabile)",
    android: "Partecipa al Test su Google Play",
    ios: "Prova la Beta su TestFlight (iOS)",
    ext: "Estensione PC/Mac (.zip)"
  },
  ar: {
    copyright: "© 2026 SegurCel. جميع الحقوق محفوظة.",
    dev: "تطوير A.M.B.",
    guide: "دليل الاستخدام السريع",
    privacy: "سياسة الخصوصية",
    support: "التواصل: support.segurcel@gmail.com",
    github: "GitHub (كود قابل للتدقيق)",
    android: "الانضمام للاختبار على Google Play",
    ios: "اختبار البيتا على TestFlight (iOS)",
    ext: "إضافة الكمبيوتر (.zip)"
  },
  id: {
    copyright: "© 2026 SegurCel. Hak cipta dilindungi undang-undang.",
    dev: "Dikembangkan oleh A.M.B.",
    guide: "Panduan Pengguna Cepat",
    privacy: "Kebijakan Privasi",
    support: "Kontak: support.segurcel@gmail.com",
    github: "GitHub (Kode Dapat Diaudit)",
    android: "Bergabung dengan Uji Coba Google Play",
    ios: "Uji Beta di TestFlight (iOS)",
    ext: "Ekstensi PC/Mac (.zip)"
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
        padding: 36px 20px 24px;
        text-align: center;
      }
      .footer-simple-container {
        max-width: 1100px;
        margin: 0 auto;
      }
      .footer-links-row {
        display: flex;
        justify-content: center;
        align-items: center;
        gap: 20px;
        flex-wrap: wrap;
        margin-bottom: 16px;
      }
      .footer-links-row a {
        color: #cbd5e1;
        text-decoration: none;
        font-size: 13px;
        font-weight: 500;
        transition: color 0.2s ease;
      }
      .footer-links-row a:hover {
        color: #6C63FF;
      }
      .footer-download-row a {
        color: #818cf8;
        background: rgba(108, 99, 255, 0.12);
        padding: 6px 14px;
        border-radius: 8px;
        border: 1px solid rgba(108, 99, 255, 0.3);
        font-size: 13px;
        font-weight: 600;
      }
      .footer-download-row a:hover {
        background: rgba(108, 99, 255, 0.3);
        color: #ffffff;
      }
      .footer-copy-row {
        border-top: 1px solid rgba(255, 255, 255, 0.08);
        padding-top: 16px;
        margin-top: 16px;
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
        <div class="footer-simple-container">
          <div class="footer-links-row">
            <a href="/guide?lang=${lang}" id="linkFooterGuide">${data.guide}</a>
            <a href="/privacy?lang=${lang}" id="linkFooterPrivacy">${data.privacy}</a>
            <a href="mailto:support.segurcel@gmail.com" id="linkFooterSupport">${data.support}</a>
            <a href="https://github.com/ambuydev/SegurCel" target="_blank" id="linkFooterGithub">${data.github}</a>
          </div>
          <div class="footer-links-row footer-download-row">
            <a href="https://play.google.com/apps/testing/com.segurcel.segurcel" target="_blank" id="linkFooterAndroid">${data.android}</a>
            <a href="https://testflight.apple.com/join/3Dvcxj1E" target="_blank" id="linkFooterIos">${data.ios}</a>
            <a href="/segurcel-extension.zip" target="_blank" id="linkFooterExt">${data.ext}</a>
          </div>
          <div class="footer-copy-row">
            <p id="footerCopyright">${data.copyright} <span class="dev-credit">${data.dev}</span></p>
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
