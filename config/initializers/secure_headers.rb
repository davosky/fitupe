# Configura gli header di sicurezza HTTP (HSTS, CSP, X-Frame-Options, ecc.),
# vedi la sezione "Best Practice Essenziali di Sicurezza per Ruby on Rails" in
# CLAUDE.md. Sostituisce il CSP nativo di Rails (config/initializers/content_security_policy.rb,
# rimasto commentato/inattivo) con una configurazione più completa.
SecureHeaders::Configuration.default do |config|
  config.cookies = {
    # secure_headers accetta solo true/Hash/OPT_OUT per :secure (mai false):
    # in sviluppo (http, niente TLS) il flag Secure va disattivato del tutto,
    # non impostato a false.
    secure: Rails.env.production? ? true : SecureHeaders::OPT_OUT,
    httponly: true,
    samesite: { lax: true }
  }
  config.hsts = "max-age=#{1.year.to_i}; includeSubDomains"
  config.x_frame_options = "SAMEORIGIN"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = %w[origin-when-cross-origin strict-origin-when-cross-origin]
  config.csp = {
    # Asset self-hosted (font Asap Condensed, Bootstrap/Bootswatch via cssbundling-rails,
    # JS via jsbundling-rails/esbuild): nessun CDN esterno da autorizzare.
    default_src: %w['self'],
    script_src: %w['self'],
    # unsafe-inline necessario: molte view usano attributi style="" inline
    # (dimensionamento dei grafici Chart.js). blob: necessario per un foglio
    # di stile generato via Blob URL dal pannello Administrate.
    style_src: %w['self' 'unsafe-inline' blob:],
    img_src: %w['self' data:],
    font_src: %w['self'],
    # 'self' copre anche le connessioni websocket same-origin di Action Cable
    # (usato da ImportCsvJob/ImportSpiCsvJob per il progresso via Turbo Stream).
    connect_src: %w['self'],
    object_src: %w['none'],
    base_uri: %w['self'],
    form_action: %w['self'],
    frame_ancestors: %w['self']
  }
end
