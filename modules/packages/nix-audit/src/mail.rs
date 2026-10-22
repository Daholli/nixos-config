use anyhow::{Context, Result};
use lettre::message::header::ContentType;
use lettre::message::{Attachment, MultiPart, SinglePart};
use lettre::transport::smtp::authentication::Credentials;
use lettre::{Message, SmtpTransport, Transport};

const STYLE: &str = "table{border-collapse:collapse}th,td{border:1px solid #d4d3cf;padding:2px 8px;text-align:left}";

pub struct Config {
    url: String,
    password: Option<String>,
    from: String,
    pub to: String,
}

impl Config {
    /// None unless an SMTP server is configured, so local runs keep printing the report.
    pub fn from_env() -> Option<Self> {
        let env = |key| std::env::var(key).ok().filter(|v: &String| !v.is_empty());
        Some(Self {
            url: env("NIX_AUDIT_SMTP_URL")?,
            password: env("NIX_AUDIT_SMTP_PASSWORD"),
            from: env("NIX_AUDIT_MAIL_FROM")
                .unwrap_or_else(|| String::from("nix-audit <auditreports@christophhollizeck.dev>")),
            to: env("NIX_AUDIT_MAIL_TO")
                .unwrap_or_else(|| String::from("christoph.hollizeck@hey.com")),
        })
    }
}

pub fn send(config: &Config, subject: &str, body: &str, graphs: &[(String, String)]) -> Result<()> {
    let mut html = String::new();
    pulldown_cmark::html::push_html(
        &mut html,
        pulldown_cmark::Parser::new_ext(body, pulldown_cmark::Options::all()),
    );
    let mut parts = MultiPart::mixed().multipart(MultiPart::alternative_plain_html(
        body.to_string(),
        format!(
            "<!doctype html><html><head><style>{STYLE}</style></head><body>{html}</body></html>"
        ),
    ));
    for (name, svg) in graphs {
        let part: SinglePart =
            Attachment::new(name.clone()).body(svg.clone(), ContentType::parse("image/svg+xml")?);
        parts = parts.singlepart(part);
    }
    let message = Message::builder()
        .from(config.from.parse().context("parsing NIX_AUDIT_MAIL_FROM")?)
        .to(config.to.parse().context("parsing NIX_AUDIT_MAIL_TO")?)
        .subject(subject)
        .multipart(parts)?;

    let mut transport =
        SmtpTransport::from_url(&config.url).context("parsing NIX_AUDIT_SMTP_URL")?;
    if let Some(password) = &config.password {
        let user = url_user(&config.url).context("NIX_AUDIT_SMTP_URL names no user")?;
        transport = transport.credentials(Credentials::new(user, password.clone()));
    }
    transport
        .build()
        .send(&message)
        .context("sending the report")?;
    Ok(())
}

// The password stays out of the URL so it can come from a masked CI secret on its own.
fn url_user(url: &str) -> Option<String> {
    let authority = url.split_once("://")?.1;
    let user = authority.split_once('@')?.0;
    Some(user.replace("%40", "@"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_the_user_out_of_the_smtp_url() {
        assert_eq!(
            url_user("smtps://forgejo%40example.org@mail.example.org:465").as_deref(),
            Some("forgejo@example.org")
        );
        assert_eq!(url_user("smtps://mail.example.org"), None);
    }
}
