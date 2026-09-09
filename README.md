# وصفتي — iOS 15 / TrollStore Wrapper

تطبيق iPhone بسيط يفتح بوابة وصفتي للطبيب داخل `WKWebView`:

- الرابط الأساسي: `https://cp.wasfaty.sa/`
- الحد الأدنى: iOS 15.0
- مناسب لجهاز iPhone 6s على iOS 15.8.x
- يحفظ جلسة WebKit والكوكيز على الجهاز باستخدام `WKWebsiteDataStore.default()`
- لا يحتوي Analytics أو خادم وسيط أو كود لإرسال بيانات الدخول
- يدعم الرجوع، الرئيسية، التحديث، وفتح الصفحة الحالية في Safari
- الروابط وعمليات SSO عبر HTTPS تبقى داخل WebView ما أمكن

> **مهم:** هذا Wrapper غير رسمي للبوابة الرسمية، وليس تطبيقًا صادرًا عن وصفتي. إذا منعت البوابة تسجيل الدخول أو بعض الوظائف داخل WebView، استخدم زر Safari داخل التطبيق.

## البناء على GitHub Actions

1. فك ضغط ملف ZIP على جهازك.
2. أنشئ Repository جديدًا في GitHub.
3. ارفع **محتويات المجلد** إلى جذر الـRepository، مع الحفاظ على مجلد `.github/workflows`.
4. افتح تبويب **Actions**.
5. اختر **Build Wasfaty IPA** ثم **Run workflow**، أو ادفع أي تعديل إلى `main`.
6. بعد نجاح البناء افتح الـRun، ثم قسم **Artifacts**.
7. حمّل `Wasfaty_iOS15_TrollStore`، وفك ضغطه لتحصل على:
   `Wasfaty_iOS15_TrollStore.ipa`
8. ثبّت الـIPA بواسطة TrollStore.

## الملفات المهمة

- `Sources/WasfatyApp.swift` — التطبيق وWKWebView
- `Info.plist` — هوية التطبيق وiOS 15
- `Resources/Icons/` — الأيقونة الخاصة
- `scripts/build_ipa.sh` — بناء التطبيق وتغليف IPA
- `.github/workflows/build-ipa.yml` — GitHub Actions

## الخصوصية

هذا المشروع لا يلتقط اسم المستخدم أو كلمة المرور ولا يرسلها إلى أي خدمة مضافة. بيانات الموقع تُدار بواسطة WebKit كما يحدث داخل متصفح مضمّن على الجهاز. لا تضع أي بيانات دخول أو Tokens داخل مستودع GitHub.
