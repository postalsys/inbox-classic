//! A response from a host the address domain names, or from a DoH provider, through the autoconfig parsers:
//! Thunderbird's configuration file, Autodiscover POX and SOAP, and DoH JSON. The input is cut short of the
//! size a lookup reads, as a lookup would.
#![no_main]

use libfuzzer_sys::fuzz_target;
use pe_autoconfig::{MAX_BODY, autodiscover, dns, parse_partial};

fuzz_target!(|data: &[u8]| {
    let data = &data[..data.len().min(MAX_BODY)];
    let _ = dns::parse_doh_mx(data);
    let _ = dns::parse_doh_srv(data);
    let Ok(text) = std::str::from_utf8(data) else { return };
    let _ = parse_partial(text, "user@example.com", "example.com");
    let _ = autodiscover::parse_pox(text);
    let _ = autodiscover::parse_soap(text);
});
