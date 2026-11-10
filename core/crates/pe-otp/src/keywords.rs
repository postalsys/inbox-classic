//! Words that tell a one-time code apart from every other number in an email, a port of
//! otp-detect's src/keywords.ts. The lists are hand written and multilingual; the model learns how
//! much each class matters from how close it is to a candidate.

use std::borrow::Cow;
use std::sync::LazyLock;

use regex::Regex;

use crate::js::Units;

/// A list of phrases as one expression, `(?:a)|(?:b)|...` with JavaScript's `giu` flags
pub struct Keywords {
    re: Regex,
}

/// The one lookaround of the lists, which the `regex` crate has no syntax for: the phrase is
/// matched bare and its neighbours are checked after. No other phrase of its list starts with the
/// same letter, so a match it refuses hides no other match at that place.
const GUARDED: &str = r"(?<!\p{L})код(?!\p{L})";
const GUARDED_BARE: &str = "код";

static LETTER: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"^\p{L}$").expect("valid"));

fn is_letter(c: Option<char>) -> bool {
    c.is_some_and(|c| LETTER.is_match(c.encode_utf8(&mut [0; 4])))
}

/// The byte offset after the character at `at`
fn next_char(text: &str, at: usize) -> usize {
    at + text[at..].chars().next().map_or(1, char::len_utf8)
}

/// A text as the keyword expressions read it. With the `i` and `u` flags JavaScript counts the two
/// characters that fold into ASCII letters, `ſ` (to s) and the Kelvin sign (to k), as word
/// characters for `\b`, which the ASCII `\b` of the translated expressions does not. Each is read
/// as the ASCII letter it folds to: the case insensitive expressions match it the same, and `\b`
/// sees a word character. Both are one UTF-16 code unit, like their stand-ins.
pub struct KeywordText<'a> {
    text: Cow<'a, str>,
    units: Units,
}

impl<'a> KeywordText<'a> {
    pub fn new(text: &'a str) -> KeywordText<'a> {
        let text: Cow<str> = if text.contains(['\u{17F}', '\u{212A}']) {
            text.replace('\u{17F}', "s").replace('\u{212A}', "k").into()
        } else {
            text.into()
        };
        let units = Units::new(&text);
        KeywordText { text, units }
    }
}

impl Keywords {
    fn compile(phrases: &[&str]) -> Keywords {
        let source = phrases
            .iter()
            .map(|p| format!("(?:{})", if *p == GUARDED { GUARDED_BARE } else { p }))
            .collect::<Vec<_>>()
            .join("|");
        Keywords {
            re: pe_jsre::regex(&source, "giu"),
        }
    }

    fn accepted(text: &str, start: usize, end: usize) -> bool {
        if text[start..end].to_lowercase() != GUARDED_BARE {
            return true;
        }
        !is_letter(text[..start].chars().next_back()) && !is_letter(text[end..].chars().next())
    }

    /// The UTF-16 start and end of every match, sorted by start, as JavaScript's global exec loop
    /// finds them
    pub fn find_all(&self, text: &KeywordText) -> Vec<(usize, usize)> {
        let (units, text) = (&text.units, text.text.as_ref());
        let mut out = Vec::new();
        let mut at = 0;
        while at <= text.len() {
            let Some(m) = self.re.find_at(text, at) else {
                break;
            };
            if Self::accepted(text, m.start(), m.end()) {
                out.push((units.at(m.start()), units.at(m.end())));
                // No phrase matches the empty string
                at = if m.end() > m.start() {
                    m.end()
                } else {
                    next_char(text, m.start())
                };
            } else {
                at = next_char(text, m.start());
            }
        }
        out
    }

    /// `RegExp.prototype.test`
    pub fn matches(&self, text: &KeywordText) -> bool {
        let text = text.text.as_ref();
        let mut at = 0;
        while at <= text.len() {
            let Some(m) = self.re.find_at(text, at) else {
                return false;
            };
            if Self::accepted(text, m.start(), m.end()) {
                return true;
            }
            at = next_char(text, m.start());
        }
        false
    }
}

/// Phrases that name a one-time code
pub static STRONG: LazyLock<Keywords> = LazyLock::new(|| Keywords::compile(STRONG_PHRASES));
/// Generic words for a code or secret, weaker evidence on their own
pub static WEAK: LazyLock<Keywords> = LazyLock::new(|| Keywords::compile(WEAK_PHRASES));
/// How a one-time code is introduced or limited: instructions, expiry, warnings
pub static CUE: LazyLock<Keywords> = LazyLock::new(|| Keywords::compile(CUE_PHRASES));
/// Words that introduce the other kinds of numbers an email is full of
pub static NEGATIVE: LazyLock<Keywords> = LazyLock::new(|| Keywords::compile(NEGATIVE_PHRASES));
/// Codes that are handed out but prove nothing: promotions, referrals, invitations, gifts
pub static PROMO: LazyLock<Keywords> = LazyLock::new(|| Keywords::compile(PROMO_PHRASES));

const STRONG_PHRASES: &[&str] = &[
    // English
    r#"verification code"#,
    r#"verify code"#,
    r#"validation code"#,
    r#"security code"#,
    r#"confirmation code"#,
    r#"one[- ]time (?:pass(?:code|word)|code|pin|password|key)"#,
    r#"\botp\b"#,
    r#"pass ?code"#,
    r#"log ?in code"#,
    r#"sign[- ]?in code"#,
    r#"access code"#,
    r#"authentication code"#,
    r#"auth code"#,
    r#"\b2fa\b"#,
    r#"two[- ]factor"#,
    r#"2-step"#,
    r#"two[- ]step"#,
    r#"temporary (?:code|password|pin)"#,
    r#"single[- ]use code"#,
    r#"guard code"#,
    r#"magic code"#,
    r#"activation code"#,
    r#"reset code"#,
    r#"recovery code"#,
    r#"device code"#,
    r#"approval code"#,
    r#"your code(?: is)?"#,
    r#"code to (?:sign|log|verify|confirm|continue|complete)"#,
    r#"enter (?:this|the following|the) code"#,
    // Estonian
    r#"kinnituskood"#,
    r#"turvakood"#,
    r#"ühekordne (?:kood|parool|salasõna)"#,
    r#"sisselogimiskood"#,
    r#"kontrollkood"#,
    r#"autentimiskood"#,
    r#"verifitseerimiskood"#,
    r#"aktiveerimiskood"#,
    r#"sinu kood"#,
    r#"teie kood"#,
    // German
    r#"bestätigungscode"#,
    r#"sicherheitscode"#,
    r#"einmal-?(?:code|passwort|kennwort)"#,
    r#"verifizierungscode"#,
    r#"anmeldecode"#,
    r#"ihr code"#,
    r#"zugangscode"#,
    r#"prüfcode"#,
    // French, Spanish, Portuguese, Italian
    r#"code de (?:vérification|confirmation|sécurité|connexion|validation)"#,
    r#"code à usage unique"#,
    r#"votre code"#,
    r#"código de (?:verificación|verificação|seguridad|segurança|confirmación|confirmação|acceso|acesso)"#,
    r#"tu código"#,
    r#"seu código"#,
    r#"codice (?:di verifica|di sicurezza|di accesso|di conferma|otp)"#,
    // Dutch, Nordic, Finnish
    r#"verificatiecode"#,
    r#"beveiligingscode"#,
    r#"inlogcode"#,
    r#"bevestigingscode"#,
    r#"verifieringskod"#,
    r#"engångskod"#,
    r#"säkerhetskod"#,
    r#"bekræftelseskode"#,
    r#"sikkerhedskode"#,
    r#"engangskode"#,
    r#"bekreftelseskode"#,
    r#"vahvistuskoodi"#,
    r#"turvakoodi"#,
    r#"kertakäyttöinen"#,
    // Baltic, Polish, Czech
    r#"verifikācijas kods"#,
    r#"apstiprinājuma kods"#,
    r#"drošības kods"#,
    r#"patvirtinimo kodas"#,
    r#"saugos kodas"#,
    r#"kod weryfikacyjny"#,
    r#"kod potwierdzający"#,
    r#"kod jednorazowy"#,
    r#"ověřovací kód"#,
    r#"bezpečnostní kód"#,
    // Russian, Ukrainian
    r#"код подтверждения"#,
    r#"проверочный код"#,
    r#"код для входа"#,
    r#"одноразов\p{L}* (?:код|пароль)"#,
    r#"код безопасности"#,
    r#"ваш код"#,
    r#"код підтвердження"#,
    // CJK, Turkish
    r#"验证码"#,
    r#"驗證碼"#,
    r#"認証コード"#,
    r#"確認コード"#,
    r#"ワンタイム"#,
    r#"인증번호"#,
    r#"인증 코드"#,
    r#"doğrulama kodu"#,
    r#"güvenlik kodu"#,
];

const WEAK_PHRASES: &[&str] = &[
    r#"\bcodes?\b"#,
    r#"\bkood\b"#,
    r#"\bpin\b"#,
    r#"\bpassword\b"#,
    r#"\bparool\b"#,
    r#"\bsalasõna\b"#,
    r#"\btoken\b"#,
    r#"\bkods\b"#,
    r#"\bkodas\b"#,
    r#"\bkode\b"#,
    r#"\bkod\b"#,
    r#"\bkoodi\b"#,
    r#"\bcodice\b"#,
    r#"\bcódigo\b"#,
    // \b only knows ASCII word characters
    r#"(?<!\p{L})код(?!\p{L})"#,
    r#"コード"#,
    r#"码"#,
    r#"碼"#,
    r#"kontrollsõna"#,
];

const CUE_PHRASES: &[&str] = &[
    r#"\benter\b"#,
    r#"\btype\b"#,
    r#"\bpaste\b"#,
    r#"expires?"#,
    r#"valid (?:for|until)"#,
    r#"\bminutes?\b"#,
    r#"\bmins?\b"#,
    r#"(?:do not|don't|never) share"#,
    r#"(?:did not|didn't) (?:request|try|attempt)"#,
    r#"ignore this (?:e-?mail|message)"#,
    r#"sisesta"#,
    r#"kehtib"#,
    r#"kehtiv"#,
    r#"minuti"#,
    r#"ära jaga"#,
    r#"eingeben"#,
    r#"gültig"#,
    r#"minuten"#,
    r#"nicht weiter"#,
    r#"ingres[ae]"#,
    r#"introduce"#,
    r#"válido"#,
    r#"minutos"#,
    r#"saisissez"#,
    r#"valable"#,
    r#"введите"#,
    r#"действител"#,
    r#"минут"#,
    r#"分钟"#,
    r#"有效"#,
];

const NEGATIVE_PHRASES: &[&str] = &[
    r#"\border\b"#,
    r#"invoice"#,
    r#"receipt"#,
    r#"tracking"#,
    r#"shipment"#,
    r#"parcel"#,
    r#"package"#,
    r#"\bphone\b"#,
    r#"\btel\b"#,
    r#"\bfax\b"#,
    r#"\bmobile\b"#,
    r#"\bref(?:erence)?\b"#,
    r#"customer"#,
    r#"account (?:no|number)"#,
    r#"booking"#,
    r#"reservation"#,
    r#"ticket"#,
    r#"promo"#,
    r#"discount"#,
    r#"coupon"#,
    r#"voucher"#,
    r#"gift"#,
    r#"\bzip\b"#,
    r#"postal"#,
    r#"price"#,
    r#"\btotal\b"#,
    r#"amount"#,
    r#"\biban\b"#,
    r#"\bvat\b"#,
    r#"license"#,
    r#"serial"#,
    r#"\bid\b"#,
    r#"member"#,
    r#"transaction"#,
    r#"tellimus"#,
    r#"\barve\b"#,
    r#"viitenumber"#,
    r#"telefon"#,
    r#"pakk"#,
    r#"pakiautomaat"#,
    r#"kupong"#,
    r#"sooduskood"#,
    r#"\bsumma\b"#,
    r#"kokku"#,
    r#"\bhind\b"#,
    r#"registrikood"#,
    r#"isikukood"#,
    r#"bestellung"#,
    r#"rechnung"#,
    r#"sendungsnummer"#,
    r#"kundennummer"#,
    r#"gutschein"#,
    r#"pedido"#,
    r#"factura"#,
    r#"commande"#,
    r#"facture"#,
    r#"заказ"#,
    r#"счет"#,
];

const PROMO_PHRASES: &[&str] = &[
    r#"promo"#,
    r#"discount"#,
    r#"coupon"#,
    r#"voucher"#,
    r#"referral"#,
    r#"\brefer\b"#,
    r#"invite"#,
    r#"invitation"#,
    r#"\bgift\b"#,
    r#"redeem"#,
    r#"\boffer\b"#,
    r#"\bsale\b"#,
    r#"\d+ ?% off"#,
    r#"\bfree\b"#,
    r#"\bsave\b"#,
    r#"share (?:your|this) code"#,
    r#"friends?"#,
    r#"\bvip\b"#,
    r#"checkout"#,
    r#"sooduskood"#,
    r#"soodus"#,
    r#"allahindlus"#,
    r#"kinkekaart"#,
    r#"kupong"#,
    r#"tasuta"#,
    r#"gutschein"#,
    r#"rabatt"#,
    r#"empfehl"#,
    r#"descuento"#,
    r#"cupón"#,
    r#"réduction"#,
    r#"parrainage"#,
    r#"скидк"#,
    r#"промокод"#,
    r#"优惠"#,
];
