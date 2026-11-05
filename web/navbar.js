/**
 * SegurCel Web - Shared Navbar & Dynamic Localizations Module
 * Gestiona el encabezado, banderas HD, selector desplegable de idiomas, botón 'Volver al Sitio Oficial', enlace a GitHub y pie de página en 14 idiomas con URLs Limpias.
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
  es: { copyright: "© 2026 SegurCel. Todos los derechos reservados.", guide: "📘 Guía Rápida de Uso", privacy: "Política de Privacidad", official: "Sitio Oficial", github: "⭐ GitHub (Código Auditable)" },
  en: { copyright: "© 2026 SegurCel. All rights reserved.", guide: "📘 Quick User Guide", privacy: "Privacy Policy", official: "Official Site", github: "⭐ GitHub (Auditable Code)" },
  pt: { copyright: "© 2026 SegurCel. Todos os direitos reservados.", guide: "📘 Guia Rápido do Usuário", privacy: "Política de Privacidade", official: "Site Oficial", github: "⭐ GitHub (Código Auditável)" },
  zh: { copyright: "© 2026 SegurCel。保留所有权利。", guide: "📘 快速使用指南", privacy: "隐私政策", official: "官方网站", github: "⭐ GitHub (可审计源码)" },
  zh_HK: { copyright: "© 2026 SegurCel。保留所有權利。", guide: "📘 快速使用指南", privacy: "私隱政策", official: "官方網站", github: "⭐ GitHub (可審計源碼)" },
  fr: { copyright: "© 2026 SegurCel. Tous droits réservés.", guide: "📘 Guide Rapide d'Utilisation", privacy: "Politique de Confidentialité", official: "Site Officiel", github: "⭐ GitHub (Code Auditable)" },
  hi: { copyright: "© 2026 SegurCel. सर्वाधिकार सुरक्षित।", guide: "📘 त्वरित उपयोग निर्देशिका", privacy: "गोपनीयता नीति", official: "आधिकारिक साइट", github: "⭐ GitHub (ऑडिट योग्य कोड)" },
  de: { copyright: "© 2026 SegurCel. Alle Rechte vorbehalten.", guide: "📘 Schnellstartanleitung", privacy: "Datenschutzerklärung", official: "Offizielle Website", github: "⭐ GitHub (Prüfbarer Code)" },
  ja: { copyright: "© 2026 SegurCel. All rights reserved.", guide: "📘 クイックユーザーガイド", privacy: "プライバシーポリシー", official: "公式サイト", github: "⭐ GitHub (監査可能コード)" },
  ko: { copyright: "© 2026 SegurCel. All rights reserved.", guide: "📘 빠른 사용자 설명서", privacy: "개인정보 처리방침", official: "공식 사이트", github: "⭐ GitHub (감사 가능 코드)" },
  ru: { copyright: "© 2026 SegurCel. Все права защищены.", guide: "📘 Краткое руководство", privacy: "Политика конфиденциальности", official: "Официальный сайт", github: "⭐ GitHub (Проверяемый код)" },
  it: { copyright: "© 2026 SegurCel. Tutti i diritti riservati.", guide: "📘 Guida Rapida Utente", privacy: "Informativa sulla Privacy", official: "Sito Ufficiale", github: "⭐ GitHub (Codice Ispezionabile)" },
  ar: { copyright: "© 2026 SegurCel. جميع الحقوق محفوظة.", guide: "📘 دليل الاستخدام السريع", privacy: "سياسة الخصوصية", official: "الموقع الرسمي", github: "⭐ GitHub (كود قابل للتدقيق)" },
  id: { copyright: "© 2026 SegurCel. Hak cipta dilindungi undang-undang.", guide: "📘 Panduan Pengguna Cepat", privacy: "Kebijakan Privasi", official: "Situs Resmi", github: "⭐ GitHub (Kode Dapat Diaudit)" }
};

window.SegurCelNav = {
  activeLang: 'es',

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
    const data = FOOTER_DICT[lang] || FOOTER_DICT.es;

    const copyEl = document.getElementById('footerCopyright');
    if (copyEl) copyEl.innerText = data.copyright;

    const guideEl = document.getElementById('linkFooterGuide');
    if (guideEl) {
      guideEl.innerText = data.guide;
      guideEl.href = `/guide?lang=${lang}`;
    }

    const privacyEl = document.getElementById('linkFooterPrivacy');
    if (privacyEl) {
      privacyEl.innerText = data.privacy;
      privacyEl.href = `/privacy?lang=${lang}`;
    }

    const officialEl = document.getElementById('linkFooterOfficial');
    if (officialEl) {
      officialEl.innerText = data.official;
      officialEl.href = `/?lang=${lang}`;
    }

    const githubEl = document.getElementById('linkFooterGithub');
    if (githubEl) {
      githubEl.innerText = data.github;
      githubEl.href = "https://github.com/ambuydev/SegurCel";
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
